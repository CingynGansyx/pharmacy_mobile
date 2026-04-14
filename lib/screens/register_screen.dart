import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/user.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'customer_home.dart';
import 'staff_home.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  UserRole _role = UserRole.customer;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final state = context.read<AppState>();
      final user = await state.auth.register(
        username: _username.text.trim(),
        password: _password.text,
        fullName: _fullName.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        role: _role,
      );
      state.setUser(user);
      if (user.role == UserRole.customer) {
        state.loadCart();
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => user.role == UserRole.staff
              ? const StaffHome()
              : const CustomerHome(),
        ),
        (route) => false,
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Алдаа: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Бүртгэл үүсгэх')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _RoleSelector(
                      value: _role,
                      onChanged: (v) => setState(() => _role = v),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _username,
                      decoration: const InputDecoration(
                        labelText: 'Нэвтрэх нэр',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Заавал' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Нууц үг',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 4) ? '4+ тэмдэгт' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fullName,
                      decoration: const InputDecoration(
                        labelText: 'Бүтэн нэр',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Заавал' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      decoration: const InputDecoration(
                        labelText: 'Утас',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'Имэйл',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.danger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Бүртгүүлэх'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.value, required this.onChanged});

  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.borderSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleOption(
              icon: Icons.person_outline,
              label: 'Хэрэглэгч',
              selected: value == UserRole.customer,
              onTap: () => onChanged(UserRole.customer),
            ),
          ),
          Expanded(
            child: _RoleOption(
              icon: Icons.badge_outlined,
              label: 'Ажилтан',
              selected: value == UserRole.staff,
              onTap: () => onChanged(UserRole.staff),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
