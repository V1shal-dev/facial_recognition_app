import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_button.dart';
import 'capture_image_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedGender = 'Male';
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters';
    }
    return null;
  }

  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your mobile number';
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
      return 'Please enter a valid 10-digit mobile number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final user = UserModel(
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        gender: _selectedGender,
      );

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.saveUser(user);

      setState(() => _isLoading = false);

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
            const CaptureImageScreen(isProfile: true),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.85),
              BlendMode.lighten,
            ),
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Header
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_add_alt_1,
                            size: 60,
                            color: Colors.deepPurple.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Fill in your details to get started',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        validator: _validateName,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                          prefixIcon: Icon(Icons.person_outline, color: Colors.deepPurple.shade600),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),

                      const SizedBox(height: 20),

                      // Mobile Field
                      TextFormField(
                        controller: _mobileController,
                        validator: _validateMobile,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          hintText: 'Enter 10-digit mobile number',
                          prefixIcon: Icon(Icons.phone_outlined, color: Colors.deepPurple.shade600),
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        validator: _validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'Enter your email',
                          prefixIcon: Icon(Icons.email_outlined, color: Colors.deepPurple.shade600),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Gender Selection
                      Text(
                        'Gender',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _GenderOption(
                                label: 'Male',
                                icon: Icons.male,
                                isSelected: _selectedGender == 'Male',
                                onTap: () => setState(() => _selectedGender = 'Male'),
                              ),
                            ),
                            Expanded(
                              child: _GenderOption(
                                label: 'Female',
                                icon: Icons.female,
                                isSelected: _selectedGender == 'Female',
                                onTap: () => setState(() => _selectedGender = 'Female'),
                              ),
                            ),
                            Expanded(
                              child: _GenderOption(
                                label: 'Other',
                                icon: Icons.transgender,
                                isSelected: _selectedGender == 'Other',
                                onTap: () => setState(() => _selectedGender = 'Other'),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Submit Button
                      CustomButton(
                        text: 'Continue',
                        onPressed: _handleSubmit,
                        isLoading: _isLoading,
                        icon: Icons.arrow_forward,
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    Key? key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.shade600 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}