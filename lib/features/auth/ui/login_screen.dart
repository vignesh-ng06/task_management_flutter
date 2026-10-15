import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'register_screen.dart';

const _background = Color(0xFFFAF8FF);
const _surface = Color(0xFFFFFFFF);
const _surfaceLow = Color(0xFFF2F3FF);
const _surfaceHigh = Color(0xFFE2E7FF);
const _primary = Color(0xFF4F46E5);
const _secondary = Color(0xFF712AE2);
const _onSurface = Color(0xFF131B2E);
const _onSurfaceVariant = Color(0xFF464555);
const _outline = Color(0xFF777587);
const _error = Color(0xFFBA1A1A);
const _errorContainer = Color(0xFFFFDAD6);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _passwordVisible = false;
  bool _rememberMe = true;
  bool _showDemoError = false;
  String? _dismissedError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _dismissedError = null;
      _showDemoError = false;
    });
    context.read<AuthBloc>().add(
      AuthLoginSubmitted(_emailCtrl.text.trim(), _passwordCtrl.text),
    );
  }

  void _openRegister() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AuthBloc>(),
          child: const RegisterScreen(),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: _buildLanguageSelector(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildWelcomeHeader(),
                        const SizedBox(height: 24),
                        _buildAuthCard(),
                        const SizedBox(height: 24),
                        _buildTrustBadge(),
                        const SizedBox(height: 24),
                        _buildRegisterCallout(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return PopupMenuButton<String>(
      tooltip: 'Choose language',
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'EN',
          child: Row(
            children: [
              Text('English'),
              Spacer(),
              Icon(Icons.check, size: 18, color: _primary),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          enabled: false,
          value: 'ES',
          child: Text('Español · Coming soon'),
        ),
        const PopupMenuItem<String>(
          enabled: false,
          value: 'FR',
          child: Text('Français · Coming soon'),
        ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _surfaceLow,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 16, color: _onSurfaceVariant),
            const SizedBox(width: 5),
            const Text(
              'EN',
              style: TextStyle(
                color: _onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.expand_more, size: 14, color: _onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/branding/taskflow_logo.png',
          width: 150,
          height: 100,
          fit: BoxFit.contain,
          semanticLabel: 'TaskFlow',
        ),
        const SizedBox(height: 12),
        Text(
          'Welcome Back',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _onSurface,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sign in to your high-velocity workspace',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: _onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildAuthCard() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final authError =
            state.error != null &&
                state.error != _dismissedError &&
                !state.isLoading
            ? state.error
            : null;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (authError != null || _showDemoError) ...[
                _buildErrorBanner(
                  authError ??
                      'The email or password does not match active records.',
                  onDismiss: () {
                    setState(() {
                      if (authError != null) _dismissedError = authError;
                      _showDemoError = false;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildEmailField(),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 16),
                    _buildOptionsRow(),
                    const SizedBox(height: 16),
                    _LoginButton(
                      isLoading: state.isLoading,
                      onPressed: state.isLoading ? null : _submit,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider(color: _surfaceHigh)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR CONTINUE WITH',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: _surfaceHigh)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SocialButton(
                      label: 'Google',
                      icon: const _GoogleMark(),
                      onPressed: () =>
                          _showMessage('Google sign-in is not configured yet.'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SocialButton(
                      label: 'GitHub',
                      icon: const Icon(Icons.code, size: 18, color: _onSurface),
                      onPressed: () =>
                          _showMessage('GitHub sign-in is not configured yet.'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner(String message, {required VoidCallback onDismiss}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 20, color: _error),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unable to sign in',
                  style: TextStyle(
                    color: _error,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: _onSurfaceVariant,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.close, size: 18, color: _onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Work Email',
          style: TextStyle(
            color: _onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          autofillHints: const [AutofillHints.email],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'name@company.com',
            prefixIcon: const Icon(Icons.mail_outline, size: 20),
            suffixIcon: _emailCtrl.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear email',
                    onPressed: () {
                      _emailCtrl.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.cancel, size: 18),
                  ),
            filled: true,
            fillColor: _surfaceLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            hintStyle: const TextStyle(color: _outline, fontSize: 14),
            prefixIconColor: _outline,
            suffixIconColor: _outline,
          ),
          validator: (value) {
            final email = value?.trim() ?? '';
            if (email.isEmpty) return 'Enter your email';
            if (!email.contains('@') || !email.contains('.')) {
              return 'Enter a valid email address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Password',
                style: TextStyle(
                  color: _onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _showMessage(
                'Password reset is not available yet. Contact your administrator.',
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Forgot password?',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        TextFormField(
          controller: _passwordCtrl,
          obscureText: !_passwordVisible,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: '••••••••••••',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              tooltip: _passwordVisible ? 'Hide password' : 'Show password',
              onPressed: () {
                setState(() => _passwordVisible = !_passwordVisible);
              },
              icon: Icon(
                _passwordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: _surfaceLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            hintStyle: const TextStyle(color: _outline, fontSize: 14),
            prefixIconColor: _outline,
            suffixIconColor: _outline,
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'Enter your password' : null,
        ),
      ],
    );
  }

  Widget _buildOptionsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rememberOption = InkWell(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          borderRadius: BorderRadius.circular(6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() => _rememberMe = value ?? false);
                  },
                  activeColor: _primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Remember me for 30 days',
                style: TextStyle(color: _onSurface, fontSize: 11),
              ),
            ],
          ),
        );
        final simulateError = TextButton.icon(
          onPressed: () => setState(() => _showDemoError = !_showDemoError),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: _onSurfaceVariant,
          ),
          icon: const Icon(Icons.bug_report_outlined, size: 14),
          label: const Text('Simulate error', style: TextStyle(fontSize: 10)),
        );

        if (constraints.maxWidth < 310) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              rememberOption,
              Align(alignment: Alignment.centerRight, child: simulateError),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: rememberOption),
            simulateError,
          ],
        );
      },
    );
  }

  Widget _buildTrustBadge() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 16, color: _primary),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            'Secure workspace sign-in',
            textAlign: TextAlign.center,
            style: TextStyle(color: _onSurfaceVariant, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterCallout() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            "Don't have an account? ",
            style: TextStyle(color: _onSurfaceVariant, fontSize: 14),
          ),
          TextButton(
            onPressed: _openRegister,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Create workspace',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.chevron_right, size: 16, color: _primary),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _onSurface,
        backgroundColor: _surfaceLow,
        side: BorderSide.none,
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _LoginButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? null
              : const LinearGradient(
                  colors: [_primary, _secondary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: onPressed == null ? const Color(0xFF94A3B8) : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(10),
            child: Center(
              child: isLoading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 9),
                        Text(
                          'Verifying session...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sign In to Workspace',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
