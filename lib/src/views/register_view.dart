import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:template/src/controllers/auth_controller.dart';
import 'package:template/src/design_system/app_logo.dart';
import 'package:template/src/design_system/controller_builder.dart';
import 'package:template/src/design_system/responsive_wrapper.dart';
import 'package:template/src/extensions/index.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ControllerBuilder<AuthController>(
      create: () => AuthController(),
      builder: (context, controller) {
        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary.withOpacity(0.5),
                        theme.colorScheme.surface.withOpacity(0),
                      ],
                      stops: const [0, 0.3, 0.6],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: ResponsiveWrapper(
                  child: Form(
                    key: formKey,
                    child: Center(
                      child: Container(
                        width: 400,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppLogo(size: 60),
                            const Gap(16),
                            Text(
                              'Create Account',
                              style: theme.textTheme.headlineMedium,
                            ),
                            const Gap(8),
                            Text(
                              'Sign up to get started',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const Gap(24),
                            if (controller.errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  controller.errorMessage!,
                                  style: theme.textTheme.bodyMedium!.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                              const Gap(16),
                            ],
                            FormField<String>(
                              validator: (value) {
                                if (emailController.text.isEmpty) {
                                  return 'Email is required';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(emailController.text)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                              builder: (state) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CupertinoTextField(
                                    controller: emailController,
                                    placeholder: 'Email',
                                    keyboardType: TextInputType.emailAddress,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    placeholderStyle: theme.textTheme.bodyMedium!.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                    style: theme.textTheme.bodyMedium,
                                    onChanged: (value) => state.didChange(value),
                                  ),
                                  if (state.hasError) ...[
                                    Gap(8),
                                    Text(
                                      state.errorText!,
                                      style: theme.textTheme.bodySmall!
                                          .copyWith(color: theme.colorScheme.error),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Gap(16),
                            FormField(
                              validator: (value) {
                                if (passwordController.text.isEmpty) {
                                  return 'Password is required';
                                }
                                if (passwordController.text.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                              builder: (state) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CupertinoTextField(
                                    controller: passwordController,
                                    placeholder: 'Password',
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    placeholderStyle: theme.textTheme.bodyMedium!.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                    style: theme.textTheme.bodyMedium,
                                    obscureText: true,
                                    onChanged: (value) => state.didChange(value),
                                  ),
                                  if (state.hasError) ...[
                                    Gap(8),
                                    Text(
                                      state.errorText!,
                                      style: theme.textTheme.bodySmall!
                                          .copyWith(color: theme.colorScheme.error),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Gap(16),
                            FormField(
                              validator: (value) {
                                if (confirmPasswordController.text.isEmpty) {
                                  return 'Confirm password is required';
                                }
                                if (confirmPasswordController.text != passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                              builder: (state) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CupertinoTextField(
                                    controller: confirmPasswordController,
                                    placeholder: 'Confirm Password',
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    placeholderStyle: theme.textTheme.bodyMedium!.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                    style: theme.textTheme.bodyMedium,
                                    obscureText: true,
                                    onChanged: (value) => state.didChange(value),
                                  ),
                                  if (state.hasError) ...[
                                    Gap(8),
                                    Text(
                                      state.errorText!,
                                      style: theme.textTheme.bodySmall!
                                          .copyWith(color: theme.colorScheme.error),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Gap(24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: controller.isLoading
                                    ? null
                                    : () async {
                                        if (formKey.currentState!.validate()) {
                                          await controller.signUpWithEmailAndPassword(
                                            email: emailController.text,
                                            password: passwordController.text,
                                          );
                                        }
                                      },
                                child: controller.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Sign Up'),
                              ),
                            ),
                            const Gap(16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account?",
                                  style: theme.textTheme.bodyMedium,
                                ),
                                TextButton(
                                  onPressed: () => context.go('/login'),
                                  child: Text('Sign In'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}