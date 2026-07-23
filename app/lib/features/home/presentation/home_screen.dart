import 'package:bb_block/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TopChip(
                    icon: Icons.movie_outlined,
                    label: 'Ödüllü Reklam',
                    onTap: () {},
                  ),
                  _TopChip(
                    icon: Icons.vpn_key_outlined,
                    label: '0',
                    onTap: () {},
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'BB Block',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const Spacer(),
              _ModeButton(label: 'Level Mod', onTap: () {}),
              const SizedBox(height: 12),
              _ModeButton(label: 'Klasik Mod', onTap: () {}),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopChip extends StatelessWidget {
  const _TopChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.paper, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: AppColors.paper),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
