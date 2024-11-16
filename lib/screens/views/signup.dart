import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'login.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedPosition = 'Factory Manager';
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  File? _imageFile;
  final _picker = ImagePicker();
  bool _isLoading = false;

  // Form validation patterns
  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final _phoneRegex = RegExp(r'^\+?[0-9]{10,}$');
  final _passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');

  // Colors
  final Color _backgroundColor = const Color(0xFFF5E6D3);
  final Color _containerColor = const Color.fromARGB(255, 226, 216, 204);
  final Color _textColor = const Color(0xFF8B7355);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Register!',
                      style: TextStyle(
                        fontSize: 40,
                        color: Colors.brown,
                        fontWeight: FontWeight.w300,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildProfileImagePicker(),
                    const SizedBox(height: 40),
                    _buildFormContainer(),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                    _buildLoginLink(),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
              color: const Color.fromARGB(255, 250, 206, 190), width: 2),
        ),
        child: GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 48,
            backgroundColor: Colors.white,
            backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
            child: _imageFile == null
                ? Icon(
                    Icons.camera_alt,
                    size: 30,
                    color: _textColor,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildFormContainer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _containerColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextFormField(
            controller: _nameController,
            label: 'Name',
            hintText: 'Your Name, e.g : Sara saleh',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              if (value.length < 3) {
                return 'Name must be at least 3 characters';
              }
              return null;
            },
          ),
          _buildTextFormField(
            controller: _emailController,
            label: 'Email',
            hintText: 'Your email, e.g : Sarah.saleh@gmail.com',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!_emailRegex.hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          _buildTextFormField(
            controller: _phoneController,
            label: 'Phone Number',
            hintText: 'Your phone number, e.g : +966 xxx xxx',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              if (!_phoneRegex.hasMatch(value)) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
          _buildPositionDropdown(),
          _buildTextFormField(
            controller: _passwordController,
            label: 'Password',
            hintText: 'Your password, at least 8 character',
            isPassword: true,
            obscureText: _obscurePassword,
            onTogglePassword: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (!_passwordRegex.hasMatch(value)) {
                return 'Password must be at least 8 characters with letters and numbers';
              }
              return null;
            },
          ),
          _buildTextFormField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hintText: 'Re-type your password',
            isPassword: true,
            obscureText: _obscureConfirmPassword,
            onTogglePassword: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPositionDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Position',
          style: TextStyle(
            fontSize: 20,
            color: _textColor,
            fontWeight: FontWeight.w500,
            fontFamily: 'SF Pro Display',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _textColor.withOpacity(0.3),
              ),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedPosition,
            dropdownColor: _containerColor,
            style: TextStyle(
              color: _textColor,
              fontFamily: 'SF Pro Display',
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
            items: ['Factory Manager', 'Safety Person', 'Employee']
                .map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedPosition = newValue!;
              });
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    String? Function(String?)? validator,
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onTogglePassword,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 20,
            color: _textColor,
            fontWeight: FontWeight.w500,
            fontFamily: 'SF Pro Display',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? (obscureText ?? true) : false,
          style: TextStyle(
            color: _textColor,
            fontFamily: 'SF Pro Display',
          ),
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: _textColor.withOpacity(0.5),
              fontSize: 16,
              fontFamily: 'SF Pro Display',
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _textColor.withOpacity(0.3)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _textColor),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ?? true
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: _textColor.withOpacity(0.7),
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.brown, // Changed to brown
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextButton(
        onPressed: _isLoading ? null : _submitForm,
        child: const Text(
          'sign up',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w400,
            fontFamily: 'SF Pro Display',
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        },
        child: Text(
          'Already have an account? Login',
          style: TextStyle(
            color: Colors.brown.withOpacity(0.9),
            fontFamily: 'SF Pro Display',
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef
          .child('profile_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      await imageRef.putFile(_imageFile!);
      return await imageRef.getDownloadURL();
    } catch (e) {
      _showErrorSnackBar('Failed to upload image: $e');
      return null;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'SF Pro Display'),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create user account
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Upload profile image if selected
      String? imageUrl = await _uploadImage();

      // Save user data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'position': _selectedPosition,
        'profileImage': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
      });

      if (mounted) {
        _showVerificationDialog();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during registration';

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered';
          break;
        case 'weak-password':
          errorMessage = 'The password provided is too weak';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid';
          break;
      }

      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('Registration failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Column(
              children: [
                Icon(
                  Icons.mark_email_read,
                  size: 50,
                  color: Color(0xFFBFAFA0),
                ),
                SizedBox(height: 10),
                Text(
                  'Verify Your Email',
                  style: TextStyle(
                    color: Color.fromARGB(255, 9, 9, 10),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'We\'ve sent a verification email to:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _emailController.text,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please check your email and click the verification link to complete your registration.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  // Sign out the current user
                  await FirebaseAuth.instance.signOut();

                  if (mounted) {
                    // Navigate to login page
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
                child: const Text(
                  'Go to Login',
                  style: TextStyle(
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 37, 37, 37),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () async {
                  try {
                    // Resend verification email
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await user.sendEmailVerification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Verification email resent!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to resend verification email'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Resend Email'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
