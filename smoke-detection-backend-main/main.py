import asyncio
from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import numpy as np
import requests
import logging
import uvicorn
import statistics
from typing import Dict, Any

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = FastAPI()

# Load the saved model and scaler
try:
    model = joblib.load('random_forest_model.pkl')
    scaler = joblib.load('scaler.pkl')
    logger.info("Model and scaler loaded successfully")
except FileNotFoundError:
    logger.error("Error: Model or scaler file not found. Please ensure they are in the correct directory.")
    exit(1)

# Firebase URL
FIREBASE_URL = 'https://smart-64616-default-rtdb.firebaseio.com/'


class Configuration:
    def __init__(self):
        self.thresholds = {}
        self.priorities = {}

    def update_config(self, config_data: Dict[str, Any]):
        if not config_data:
            logger.warning("Empty configuration received")
            return

        try:
            thresholds = config_data.get('thresholds', {})
            priorities = config_data.get('priorities', {})

            # Convert temperature key if needed
            if 'temperature' in thresholds:
                thresholds['temp'] = thresholds.pop('temperature')
            if 'temperature' in priorities:
                priorities['temp'] = priorities.pop('temperature')

            self.thresholds = thresholds
            self.priorities = priorities

            logger.info(f"Configuration updated - Thresholds: {self.thresholds}, Priorities: {self.priorities}")
        except Exception as e:
            logger.error(f"Error updating configuration: {e}")


# Global configuration instance
config = Configuration()


def get_sensor_average(room_data: dict, sensor_type: str) -> float:
    """Calculate average value for multiple sensors of the same type."""
    values = []
    for key, value in room_data.items():
        # Check if the key starts with the sensor type and is followed by a number
        if key.startswith(sensor_type) and key[len(sensor_type):].isdigit():
            try:
                values.append(float(value))
            except (ValueError, TypeError):
                logger.warning(f"Invalid value for sensor {key}: {value}")
                continue

    if values:
        average = sum(values) / len(values)
        logger.info(f"Average for {sensor_type} sensors: {average}")
        return average
    return None


def check_fire_sensors(room_data: dict) -> bool:
    """Check if any fire sensor in the room reports fire (value of '1')."""
    for key, value in room_data.items():
        if key.startswith('fire') and key[4:].isdigit():
            if str(value) == '1':
                logger.warning(f"Fire detected by sensor {key}")
                return True
    return False


def process_room_sensors(room_data: dict) -> dict:
    """Process all sensors in a room and return averaged values."""
    processed_data = {}

    # Handle fire sensors specially
    if any(key.startswith('fire') for key in room_data.keys()):
        fire_detected = check_fire_sensors(room_data)
        if fire_detected:
            processed_data['fire'] = '1'

    # Process other sensor types
    sensor_types = ['temp', 'humidity', 'gas']
    for sensor_type in sensor_types:
        avg_value = get_sensor_average(room_data, sensor_type)
        if avg_value is not None:
            processed_data[sensor_type] = str(avg_value)

    logger.info(f"Processed sensor data: {processed_data}")
    return processed_data


def predict_fire_alarm(data):
    scaled_data = scaler.transform(data)
    predictions = model.predict(scaled_data)
    logger.info(f"ML Model Prediction: {predictions[0]}")
    return predictions


def level_specifier(value, medium, maximum):
    value = float(value)
    if value < medium:
        return 1
    elif medium <= value < maximum:
        return 2
    else:
        return 3


def improved_voting_function_with_escalation(input_data: dict, location_config: dict) -> int:
    if not location_config or 'thresholds' not in location_config or 'priorities' not in location_config:
        logger.error("Invalid configuration data")
        return 1  # Default safety level

    factor_levels = {}
    thresholds = location_config['thresholds']
    priorities = location_config['priorities']

    # Convert temperature to temp if needed
    if 'temperature' in thresholds:
        thresholds['temp'] = thresholds.pop('temperature')
    if 'temperature' in priorities:
        priorities['temp'] = priorities.pop('temperature')

    # Calculate levels for each sensor
    for factor, value in input_data.items():
        if factor in thresholds:
            try:
                medium = float(thresholds[factor]['medium'])
                maximum = float(thresholds[factor]['maximum'])
                factor_levels[factor] = level_specifier(float(value), medium, maximum)
                logger.info(f"Factor {factor} value {value} -> level {factor_levels[factor]}")
            except (ValueError, KeyError) as e:
                logger.error(f"Error processing {factor}: {e}")
                continue

    logger.info(f"Calculated factor levels: {factor_levels}")

    # Immediate escalation if any sensor is at critical level (3)
    if 3 in factor_levels.values():
        logger.warning("Critical level detected - immediate escalation")
        return 3

    existing_factors_count = len(factor_levels)

    if existing_factors_count > 1:
        factors_values = list(factor_levels.values())
        try:
            most_common_level = statistics.mode(factors_values)
            logger.info(f"Most common level determined: {most_common_level}")
            return most_common_level
        except statistics.StatisticsError:
            # In case of tie, use sensor priority
            highest_priority_factor = min(
                [f for f in factor_levels.keys() if f in priorities],
                key=lambda x: priorities[x]
            )
            logger.info(f"No clear mode - using highest priority factor {highest_priority_factor}")
            return factor_levels[highest_priority_factor]

    elif existing_factors_count == 1:
        return next(iter(factor_levels.values()))

    logger.warning("No valid sensor data available")
    return 1  # Default safety level


def update_room_level(location: str, room: str, level: int):
    update_url = f'{FIREBASE_URL}{location}/{room}.json'
    update_data = {"level": level}
    response = requests.patch(update_url, json=update_data)
    if response.status_code == 200:
        logger.info(f"Room level updated for {location} - {room}: {level}")
    else:
        logger.error(f"Failed to update room level for {location} - {room}. Status code: {response.status_code}")


def update_location_alarm(location: str, alarm_value: str):
    update_url = f'{FIREBASE_URL}{location}.json'
    update_data = {"alarm": alarm_value}
    response = requests.patch(update_url, json=update_data)
    if response.status_code == 200:
        logger.info(f"Location alarm updated for {location}: {alarm_value}")
    else:
        logger.error(f"Failed to update location alarm for {location}. Status code: {response.status_code}")


def process_room_data(location: str, room: str, room_data: dict, location_config: dict):
    # Process and average multiple sensors of the same type
    processed_data = process_room_sensors(room_data)

    logger.info(f"Processing {location} - {room}: {processed_data}")
    logger.info(f"Using configuration: {location_config}")

    room_level = 1  # Default level

    # Check for fire condition first
    if 'fire' in processed_data and processed_data['fire'] == '1':
        logger.warning(f"Fire detected in {location} - {room}")
        room_level = 3
    else:
        # Check for ML prediction if all three sensors are present
        sensors = ['temp', 'humidity', 'gas']
        available_sensors = [sensor for sensor in sensors if sensor in processed_data]

        if len(available_sensors) == 3:
            sensor_values = [float(processed_data[sensor]) for sensor in available_sensors]
            prediction = predict_fire_alarm(np.array([sensor_values]))[0]
            if prediction == 1:
                logger.warning(f"ML model predicted fire risk in {location} - {room}")
                room_level = 3
            else:
                room_level = improved_voting_function_with_escalation(
                    {sensor: processed_data[sensor] for sensor in available_sensors},
                    location_config
                )
        else:
            voting_result = improved_voting_function_with_escalation(
                {sensor: processed_data[sensor] for sensor in available_sensors},
                location_config
            )
            if voting_result:
                room_level = voting_result

    update_room_level(location, room, room_level)
    return room_level


async def check_sensors():
    while True:
        logger.info("Checking sensors...")
        try:
            response = requests.get(f'{FIREBASE_URL}.json')
            if response.status_code == 200:
                data = response.json()
                for location, location_data in data.items():
                    if 'configuration' not in location_data:
                        logger.error(f"No configuration found for location {location}")
                        continue

                    location_config = location_data['configuration']
                    max_room_level = 1

                    for room, room_data in location_data.items():
                        if room.startswith('room'):
                            room_level = process_room_data(location, room, room_data, location_config)
                            max_room_level = max(max_room_level, room_level)

                    # Update location alarm based on max room level
                    if max_room_level == 3:
                        update_location_alarm(location, '1')
                    else:
                        update_location_alarm(location, '0')
            else:
                logger.error(f"Failed to retrieve data. Status code: {response.status_code}")
        except requests.RequestException as e:
            logger.error(f"Error occurred while fetching data: {e}")
        except Exception as e:
            logger.error(f"Unexpected error: {e}")

        await asyncio.sleep(5)


@app.on_event("startup")
async def startup_event():
    logger.info("Starting up the Sensor Checker API")
    asyncio.create_task(check_sensors())


@app.get("/")
async def root():
    logger.info("Root endpoint accessed")
    return {"message": "Sensor Checker API is running"}


if __name__ == "__main__":
    logger.info("Starting Sensor Checker API")
    uvicorn.run("main:app", host="0.0.0.0", port=8000, log_level="info")