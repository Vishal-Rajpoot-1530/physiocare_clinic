import 'package:flutter/material.dart';

import '../widgets/common.dart';
import 'dashboard.dart';
import 'finance.dart';
import 'members.dart';
import 'settings.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int index = 0;
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      Dashboard(onGo: (i) => setState(() => index = i)),
      const MembersScreen(),
      const FinanceScreen(),
      const SettingsScreen(),
    ];
  }

  static const _items = [
    (Icons.grid_view_rounded, 'Dashboard'),
    (Icons.groups_rounded, 'Patients'),
    (Icons.account_balance_wallet_outlined, 'Finances'),
    (Icons.tune_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NightBackground(
        child: IndexedStack(index: index, children: pages),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: panel,
          border: Border(top: BorderSide(color: lineGrey)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => index = i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: index == i
                                  ? orange.withValues(alpha: 0.16)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _items[i].$1,
                              size: 24,
                              color: index == i ? orange : muted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _items[i].$2,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: index == i ? orange : muted,
                            ),
                          ),
                        ],
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
