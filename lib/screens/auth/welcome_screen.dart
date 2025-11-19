import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo and app name
              Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.style,
                      size: 50,
                      color: AppTheme.primaryButtonColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  Text(
                    'StyleMemory',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),
                  Text(
                    'Remember every client\'s style\nwith photos and notes',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.secondaryTextColor,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const Spacer(flex: 3),

              // Get Started button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.goNamed('login');
                  },
                  child: const Text('Get Started'),
                ),
              ),

              const SizedBox(height: AppTheme.spacingLarge),

              // Terms and Privacy links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      // TODO: Implement terms and privacy
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Terms of Service')),
                      );
                    },
                    child: Text(
                      'Terms',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primaryButtonColor,
                      ),
                    ),
                  ),
                  Text(
                    ' • ',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Implement privacy policy
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy Policy')),
                      );
                    },
                    child: Text(
                      'Privacy',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primaryButtonColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacingMedium),
            ],
          ),
        ),
      ),
    );
  }
}