import 'package:flutter/material.dart';
import 'package:gym_buddy_app/features/auth/domain/auth_form_validators.dart';
import 'package:gym_buddy_app/features/auth/presentation/auth_text_field.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({
    required this.isSubmitting,
    required this.onSubmit,
    super.key,
  });

  final bool isSubmitting;
  final Future<void> Function() onSubmit;

  @override
  State<RegisterForm> createState() => RegisterFormState();
}

class RegisterFormState extends State<RegisterForm> {
  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    await widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create account', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Start finding nearby partners and tracking gym sessions.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          AuthTextField(
            controller: usernameController,
            label: 'Username',
            icon: Icons.person_outline,
            textInputAction: TextInputAction.next,
            validator: AuthFormValidators.username,
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: emailController,
            label: 'Email',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: AuthFormValidators.email,
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            obscureText: true,
            textInputAction: TextInputAction.next,
            validator: AuthFormValidators.password,
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: confirmPasswordController,
            label: 'Confirm password',
            icon: Icons.verified_user_outlined,
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: (value) => AuthFormValidators.confirmPassword(
              value,
              passwordController.text,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('register-submit-button'),
            onPressed: widget.isSubmitting ? null : submit,
            icon: widget.isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_alt_1),
            label: const Text('Create account'),
          ),
          const SizedBox(height: 12),
          Text(
            'By continuing, you agree to keep your training profile honest and respectful.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
