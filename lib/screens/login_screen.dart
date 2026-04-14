import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/user.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'customer_home.dart';
import 'register_screen.dart';
import 'staff_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
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
      final user =
          await state.auth.login(_username.text.trim(), _password.text);
      state.setUser(user);
      if (user.role == UserRole.customer) {
        state.loadCart(); // fire & forget — async load server cart
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => user.role == UserRole.staff
              ? const StaffHome()
              : const CustomerHome(),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _error =
          e.statusCode == 401 ? 'Нэр эсвэл нууц үг буруу' : e.message);
    } catch (e) {
      setState(() => _error = 'Холболтын алдаа: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.local_pharmacy_outlined,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Эмийн сан',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Тавтай морилно уу',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _username,
                      decoration: const InputDecoration(
                        labelText: 'Нэвтрэх нэр',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Нэр шаардлагатай' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      decoration: const InputDecoration(
                        labelText: 'Нууц үг',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Нууц үг шаардлагатай'
                          : null,
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
                    const SizedBox(height: 20),
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
                          : const Text('Нэвтрэх'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Бүртгэлгүй юу? ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: _loading
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  ),
                          child: const Text('Бүртгүүлэх'),
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
    );
  }
}
