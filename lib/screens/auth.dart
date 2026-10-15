import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../db/app_db.dart';
import '../widgets/common.dart';
import 'shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const _demoEmail = 'demo@gmail.com';
  static const _demoPassword = '123456';

  bool loading = false, hide = true, remember = true;
  bool creatingAccount = false;
  AccountMode mode = AccountMode.offline;

  final name = TextEditingController();
  final email = TextEditingController(text: _demoEmail);
  final pass = TextEditingController(text: _demoPassword);

  String? err;
  bool errIsOk = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      mode = AccountMode.online;
    } else {
      _loadLastMode();
    }
  }

  Future<void> _loadLastMode() async {
    final lastMode = await AppDb.i.accountMode;
    if (!mounted || lastMode == null) return;
    setState(() => mode = lastMode);
  }

  Future<void> go() async {
    final normalizedEmail = email.text.trim().toLowerCase();
    final demoLogin =
        !creatingAccount &&
        !kIsWeb &&
        normalizedEmail == _demoEmail &&
        pass.text == _demoPassword;
    final selectedMode = demoLogin ? AccountMode.offline : mode;
    if ((creatingAccount && name.text.trim().isEmpty) ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail) ||
        pass.text.length < 4) {
      setState(() {
        err = creatingAccount
            ? 'Enter your name, a valid email, and a password of at least 4 characters.'
            : 'Enter a valid email and password (minimum 4 characters).';
        errIsOk = false;
      });
      return;
    }

    setState(() {
      loading = true;
      if (demoLogin) mode = AccountMode.offline;
    });

    try {
      Map<String, Object?>? account;
      if (creatingAccount) {
        account = await AppDb.i.register(
          name.text,
          normalizedEmail,
          pass.text,
          selectedMode,
          remember: remember,
        );
      } else {
        account = await AppDb.i.login(
          normalizedEmail,
          pass.text,
          selectedMode,
          remember: remember,
        );
        if (account == null &&
            demoLogin) {
          account = await AppDb.i.register(
            'Demo User',
            _demoEmail,
            _demoPassword,
            AccountMode.offline,
            remember: remember,
          );
        }
      }

      if (!mounted) return;
      if (account == null) {
        setState(() {
          err = 'Invalid email or password.';
          errIsOk = false;
        });
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Shell()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          err = e.toString().replaceFirst('Exception: ', '');
          errIsOk = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // ==========================================================
        // BACKGROUND IMAGE
        // ==========================================================
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/login_gym_bg.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),

        // ==========================================================
        // DARK OVERLAY
        // Keeps the login UI readable over the gym photo.
        // ==========================================================
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withValues(alpha: 0.38),

          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                child: Column(
                  children: [
                    const BigLogo(),

                    const SizedBox(height: 26),

                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Welcome Back, Owner',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Access your physiotherapy clinic management hub',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // LOGIN FORM
                    // ==================================================
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: SegmentedButton<AccountMode>(
                              segments: const [
                                ButtonSegment(
                                  value: AccountMode.offline,
                                  label: Text('Offline'),
                                  icon: Icon(Icons.storage_rounded),
                                  enabled: !kIsWeb,
                                ),
                                ButtonSegment(
                                  value: AccountMode.online,
                                  label: Text('Online'),
                                  icon: Icon(Icons.cloud_outlined),
                                ),
                              ],
                              selected: {mode},
                              onSelectionChanged: loading
                                  ? null
                                  : (selection) => setState(() {
                                      mode = selection.first;
                                      err = null;
                                    }),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 12),
                            child: Text(
                              mode == AccountMode.offline
                                  ? 'Offline: data stays on this device in SQLite.'
                                  : 'Online: data is stored on the server.',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (creatingAccount) ...[
                            const FieldLabel('Name'),
                            TextField(
                              controller: name,
                              textCapitalization: TextCapitalization.words,
                              decoration: fieldDeco(
                                hint: 'Your name',
                                icon: Icons.person_outline,
                              ),
                            ),
                          ],
                          // ============================================
                          // EMAIL
                          // ============================================
                          const FieldLabel('Email Address'),

                          TextField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: fieldDeco(
                              hint: 'manager@thepowercave.com',
                              icon: Icons.mail_outline,
                            ),
                          ),

                          // ============================================
                          // PASSWORD
                          // ============================================
                          const FieldLabel('Password'),

                          TextField(
                            controller: pass,
                            obscureText: hide,
                            decoration: fieldDeco(
                              hint: '••••••••••',
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    hide = !hide;
                                  });
                                },
                                icon: Icon(
                                  hide
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: muted,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),

                          // ============================================
                          // REMEMBER DEVICE
                          // ============================================
                          InkWell(
                            onTap: () {
                              setState(() {
                                remember = !remember;
                              });
                            },
                            child: Row(
                              children: [
                                Checkbox(
                                  value: remember,
                                  activeColor: orange,
                                  checkColor: ink,
                                  onChanged: (v) {
                                    setState(() {
                                      remember = v ?? true;
                                    });
                                  },
                                ),
                                const Text(
                                  'Remember this device',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),

                          // ============================================
                          // ERROR / SUCCESS MESSAGE
                          // ============================================
                          if (err != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 10,
                                top: 4,
                              ),
                              child: Text(
                                err!,
                                style: TextStyle(
                                  color: errIsOk ? okGreen : warnRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                          const SizedBox(height: 6),

                          // ============================================
                          // LOGIN BUTTON
                          // ============================================
                          PrimaryButton(
                            creatingAccount ? 'Create Account' : 'Sign In',
                            icon: Icons.arrow_forward_rounded,
                            busy: loading,
                            onPressed: go,
                          ),
                          Center(
                            child: TextButton(
                              onPressed: loading
                                  ? null
                                  : () => setState(() {
                                      creatingAccount = !creatingAccount;
                                      err = null;
                                    }),
                              child: Text(
                                creatingAccount
                                    ? 'Already have an account? Sign in'
                                    : 'New here? Create an account',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // SECURITY FOOTER
                    // ==================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.verified_user_outlined,
                          color: Colors.white54,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Secured locally  •  Station #04',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
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
