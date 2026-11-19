import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/control_style.dart';
import '../bloc/auth_bloc.dart';

class _Slide {
  const _Slide(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

const _slides = <_Slide>[
  _Slide(
    Icons.directions_bus_rounded,
    'Your bus, booked in minutes',
    'Compare operators, fares and seats left from your phone',
  ),
  _Slide(
    Icons.payments_outlined,
    'Pay with mobile money',
    'MTN MoMo, Airtel Money or M-Pesa. Your ticket stays on your phone',
  ),
];

/// First screen for signed-out users: swipeable intro slides plus sign-in
/// options. Serves as both the onboarding and the welcome screen.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const _Logo(),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page
                          ? AppColors.ink
                          : const Color(0xFFE3E7E5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              // Same side padding as the phone screen, so the buttons here
              // are exactly as wide as its Next button.
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  BlocBuilder<AuthBloc, AuthState>(
                    buildWhen: (p, c) => p.isLoading != c.isLoading,
                    builder: (context, state) => SizedBox(
                      width: double.infinity,
                      height: kControlHeight,
                      child: FilledButton(
                        key: const Key('continue_google'),
                        style: controlButtonStyle(
                          background: AppColors.ink,
                          foreground: Colors.white,
                        ),
                        onPressed: state.isLoading
                            ? null
                            : () => context
                                .read<AuthBloc>()
                                .add(const GoogleSignInRequested()),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 22,
                              width: 22,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              // Placeholder "G"; swap for the official Google
                              // logo asset to follow Google's branding rules.
                              child: const Text('G',
                                  style: TextStyle(
                                      color: Color(0xFF4285F4),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 12),
                            const Text('Continue with Google'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: kControlHeight,
                    child: FilledButton(
                      key: const Key('continue_phone'),
                      style: controlButtonStyle(
                        background: const Color(0xFFF1F0EC),
                        foreground: AppColors.ink,
                      ),
                      onPressed: () => context.push(AppRoutes.phone),
                      child: const Text('Continue with phone'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    key: const Key('continue_email'),
                    onPressed: () => context.push(AppRoutes.login),
                    child: const Text('Use email instead'),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'By continuing you agree to our Terms of Use and '
                    'Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // "B" in a box with rounded corners.
        Container(
          key: const Key('app_logo'),
          height: 32,
          width: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'B',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text('BookMe',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Simple illustration; replace with artwork when available.
          SizedBox(
            height: 240,
            width: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: -0.12,
                  child: Container(
                    height: 210,
                    width: 210,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(44),
                    ),
                  ),
                ),
                Container(
                  height: 130,
                  width: 130,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(slide.icon, size: 68, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(slide.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(slide.body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.4)),
        ],
      ),
    );
  }
}
