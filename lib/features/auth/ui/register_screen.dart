import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'registration_success_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _personalFormKey = GlobalKey<FormState>();
  final _companyFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyController = TextEditingController();
  final _industryController = TextEditingController();
  final _websiteController = TextEditingController();

  bool _obscurePassword = true;
  int _tab = 0;
  String _industry = 'Tech & SaaS';
  String _teamSize = '11-50';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _companyController.dispose();
    _industryController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_personalFormKey.currentState?.validate() ?? true) ||
        !(_companyFormKey.currentState?.validate() ?? false)) {
      return;
    }

    context.read<AuthBloc>().add(
      AuthRegisterSubmitted(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        companyName: _companyController.text.trim(),
        industry: _industry,
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        companySize: _teamSize,
      ),
    );
  }

  void _goToWorkspace() {
    if (_personalFormKey.currentState!.validate()) {
      setState(() => _tab = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.error != current.error ||
            previous.successMessage != current.successMessage ||
            previous.status != current.status,
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            Navigator.of(context).pop();
          } else if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state.successMessage != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => const RegistrationSuccessScreen(),
              ),
            );
          }
        },
        builder: (context, state) => SafeArea(
          child: Column(
            children: [
              _TopBar(onBack: () => Navigator.of(context).pop()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Header(),
                      const SizedBox(height: 16),
                      _RegistrationTabs(
                        selected: _tab,
                        onSelected: (value) {
                          if (value == 1 &&
                              !_personalFormKey.currentState!.validate()) {
                            return;
                          }
                          setState(() => _tab = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_tab == 0)
                        Form(
                          key: _personalFormKey,
                          child: _FormCard(
                            icon: Icons.badge_outlined,
                            title: 'Personal Profile',
                            subtitle: 'Your login credentials for TaskFlow',
                            child: _personalFields(),
                          ),
                        )
                      else
                        Form(
                          key: _companyFormKey,
                          child: _FormCard(
                            icon: Icons.corporate_fare_outlined,
                            title: 'Company Profile',
                            subtitle: 'Configure your team hub and workspace',
                            child: _companyFields(),
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: state.isLoading
                              ? null
                              : (_tab == 0 ? _goToWorkspace : _submit),
                          icon: state.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add_circle_outline),
                          label: Text(
                            state.isLoading
                                ? 'Creating workspace...'
                                : (_tab == 0
                                      ? 'Continue to Workspace Info'
                                      : 'Create Workspace & Continue'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '🔒 SOC2 Type II   •   🔐 End-to-End TLS   •   ⚡ Instant Setup',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Already have an account?  Log in'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _personalFields() {
    return Column(
      children: [
        const _FieldLabel('Full Name'),
        TextFormField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'e.g. Alex Henderson',
            prefixIcon: Icon(Icons.account_circle_outlined),
          ),
          validator: (value) => value == null || value.trim().length < 2
              ? 'Enter your full name'
              : null,
        ),
        const SizedBox(height: 14),
        const _FieldLabel('Work Email'),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'alex@acmecorp.com',
            prefixIcon: Icon(Icons.mail_outline),
          ),
          validator: (value) {
            final email = value?.trim() ?? '';
            return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                ? null
                : 'Enter a valid work email';
          },
        ),
        const SizedBox(height: 14),
        const _FieldLabel('Password'),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'Enter secure password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          validator: (value) => value == null || value.length < 6
              ? 'Password must be at least 6 characters'
              : null,
        ),
        const SizedBox(height: 6),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Use uppercase, numbers & symbols for high security.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _companyFields() {
    const industries = [
      'Tech & SaaS',
      'Design',
      'Marketing',
      'Agency',
      'Other',
    ];
    const teamSizes = ['1-10', '11-50', '51-200', '200+'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Company or Team Name'),
        TextFormField(
          controller: _companyController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Acme Studios',
            prefixIcon: Icon(Icons.storefront_outlined),
          ),
          validator: (value) => value == null || value.trim().length < 2
              ? 'Enter your company name'
              : null,
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Industry Sector'),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: industries
              .map(
                (value) => ChoiceChip(
                  label: Text(value),
                  selected: _industry == value,
                  onSelected: (_) => setState(() {
                    _industry = value;
                    _industryController.text = value;
                  }),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _industry == value
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        const _FieldLabel('Team Size'),
        Row(
          children: teamSizes
              .map(
                (value) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: value == teamSizes.last ? 0 : 5,
                    ),
                    child: ChoiceChip(
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(value, textAlign: TextAlign.center),
                      ),
                      selected: _teamSize == value,
                      onSelected: (_) => setState(() => _teamSize = value),
                      selectedColor: const Color(0xFF8A4CFC),
                      showCheckmark: false,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        const _FieldLabel('Website (optional)'),
        TextFormField(
          controller: _websiteController,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: 'https://example.com',
            prefixIcon: Icon(Icons.link),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF712AE2)],
              ),
            ),
            child: const Icon(Icons.view_quilt_outlined, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Text(
            'TaskFlow',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: AppColors.background,
            child: const Row(
              children: [
                Icon(Icons.language, size: 16),
                SizedBox(width: 4),
                Text('EN'),
                Icon(Icons.keyboard_arrow_down, size: 15),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person_outline, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFEAEFFF), Color(0xFFF5F3FF)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🚀  Workspace Onboarding',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Set up your workspace',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            'Start managing high-velocity projects & tasks with your team.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RegistrationTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _RegistrationTabs({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: _TabButton(
                icon: Icons.person_outline,
                label: '1. Personal',
                selected: selected == 0,
                onPressed: () => onSelected(0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TabButton(
                icon: Icons.domain_outlined,
                label: '2. Workspace',
                selected: selected == 1,
                onPressed: () => onSelected(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: selected ? Colors.white : AppColors.textSecondary,
        backgroundColor: selected ? AppColors.primary : AppColors.background,
        padding: const EdgeInsets.symmetric(vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _FormCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 9),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
