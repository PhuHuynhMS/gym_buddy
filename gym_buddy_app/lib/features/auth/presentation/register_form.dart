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
  bool acceptedTerms = false;

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
            autofillHints: const [AutofillHints.username],
            validator: AuthFormValidators.username,
          ),
          const SizedBox(height: 14),
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
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            validator: AuthFormValidators.password,
          ),
          const SizedBox(height: 14),
          AuthTextField(
            controller: confirmPasswordController,
            label: 'Confirm password',
            icon: Icons.verified_user_outlined,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) => widget.isSubmitting ? null : submit(),
            validator: (value) => AuthFormValidators.confirmPassword(
              value,
              passwordController.text,
            ),
          ),
          const SizedBox(height: 14),
          FormField<bool>(
            initialValue: acceptedTerms,
            validator: AuthFormValidators.acceptedTerms,
            builder: (field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    key: const Key('register-terms-checkbox'),
                    value: acceptedTerms,
                    onChanged: widget.isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              acceptedTerms = value ?? false;
                              field.didChange(acceptedTerms);
                            });
                          },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      'I agree to the Terms and Privacy Policy',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        field.errorText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
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
        ],
      ),
    );
  }
}
