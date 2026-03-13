import 'package:cbtapp/utils/app_colors.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController matricController;
  final TextEditingController surnameController;
  final VoidCallback onLoginPressed;
  final bool isLoading;

  const LoginScreen({
    super.key,
    required this.matricController,
    required this.surnameController,
    required this.onLoginPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Examination Login Portal",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkPrimary,
                  ),
                ),
                const Text(
                  "Enter your credentials to proceed",
                  style: TextStyle(color: AppColors.textLight),
                ),
                const SizedBox(height: 32),

                // Matric Field
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: matricController,
                    cursorColor: AppColors.darkPrimary,
                    decoration: const InputDecoration(
                      hintText: 'Reg. No',
                      prefixIcon: Icon(Icons.badge),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Surname Field
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: surnameController,
                    decoration: const InputDecoration(
                      hintText: 'Surname',
                      prefixIcon: Icon(Icons.person),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Login Button
                isLoading
                    ? Center(
                        child: const CircularProgressIndicator(
                          color: AppColors.darkPrimary,
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: AppColors.darkPrimary,
                          ),
                          onPressed: onLoginPressed,
                          child: const Text(
                            "Log In",
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.surface,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}