import 'package:flutter/material.dart';
import 'package:gym_buddy_app/features/auth/domain/auth_form_validators.dart';
import 'package:gym_buddy_app/features/auth/presentation/auth_text_field.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({
    required this.isSubmitting,
    required this.onSubmit,
    super.key,
  });

  final bool isSubmitting;
  final Future<void> Function() onSubmit;

  @override
  State<LoginForm> createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
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
          Text('Sign in', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Pick up your matches, check-ins, and workout chats.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          AuthTextField(
            controller: emailController,
            label: 'Email',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: AuthFormValidators.email,
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => widget.isSubmitting ? null : submit(),
            validator: AuthFormValidators.password,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('login-submit-button'),
            onPressed: widget.isSubmitting ? null : submit,
            icon: widget.isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            label: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
