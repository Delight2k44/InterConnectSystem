/*
 * Student Numbers: (all your group member numbers here)
 * Student Names: (all your group member names here)
 * Question: Onboarding Screen
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// NOTE: This project currently has no route manager in place in the repo.
// If your project includes `routes/route_manager.dart`, re-enable the import and
// replace `Navigator.pushReplacementNamed` below accordingly.
// import '../../routes/route_manager.dart';

// ─── Data Model ──────────────────────────────────────────────────────────────

class OnboardingPageData {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final List<Color> gradient;

  const OnboardingPageData({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.gradient,
  });
}

// ─── Main Widget ─────────────────────────────────────────────────────────────

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _animController;
  int _currentPage = 0;
  bool _isLastPage = false;

  static const _pageDuration = Duration(milliseconds: 500);
  static const _pageCurve = Curves.easeInOutCubic;

  final List<OnboardingPageData> _pages = const [
    OnboardingPageData(
      icon: Icons.school_rounded,
      color: Color(0xFF1565C0),
      title: 'Welcome to SA System',
      description:
          'The official Student Assistant Application System for the Central University of Technology, Free State.',
      gradient: [Color(0xFF1565C0), Color(0xFF42A5F5)],
    ),
    OnboardingPageData(
      icon: Icons.edit_document,
      color: Color(0xFF2E7D32),
      title: 'Apply with Ease',
      description:
          'Students can apply for Student Assistant positions for first, second, and third year modules quickly and easily.',
      gradient: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
    ),
    OnboardingPageData(
      icon: Icons.track_changes_rounded,
      color: Color(0xFF6A1B9A),
      title: 'Track Your Application',
      description:
          'Monitor the status of your application in real time. Know instantly when your application is approved or rejected.',
      gradient: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
    ),
    OnboardingPageData(
      icon: Icons.admin_panel_settings_rounded,
      color: Color(0xFFC62828),
      title: 'Managed by IT Department',
      description:
          'Administrative staff can review, approve, or reject applications securely through the Admin Portal.',
      gradient: [Color(0xFFC62828), Color(0xFFEF5350)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ─── Navigation Logic ──────────────────────────────────────────────────────

  Future<void> _completeOnboarding() async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (!mounted) return;

    // Placeholder navigation. Replace with your actual route names.
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _nextPage() {
    HapticFeedback.selectionClick();

    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: _pageDuration,
        curve: _pageCurve,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
      _isLastPage = index == _pages.length - 1;
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentData = _pages[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: _pageDuration,
        curve: _pageCurve,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              currentData.gradient[0].withOpacity(0.05),
              currentData.gradient[1].withOpacity(0.02),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Bar ───────────────────────────────────────────────────
              _buildTopBar(),

              // ── Page Content ──────────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) => _OnboardingPage(
                    data: _pages[index],
                    isActive: index == _currentPage,
                    animation: _animController,
                  ),
                ),
              ),

              // ── Bottom Controls ───────────────────────────────────────────
              _buildBottomControls(currentData.color),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Sub-Builders ──────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page counter
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey<int>(_currentPage),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _pages[_currentPage].color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentPage + 1} / ${_pages.length}',
                style: TextStyle(
                  color: _pages[_currentPage].color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // Skip button
          TextButton.icon(
            onPressed: _completeOnboarding,
            icon: const Icon(Icons.skip_next_rounded, size: 18),
            label: const Text('Skip'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(Color activeColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress dots
          _PageIndicators(
            count: _pages.length,
            currentIndex: _currentPage,
            activeColor: activeColor,
          ),

          const SizedBox(height: 32),

          // Navigation button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    activeColor,
                    activeColor.withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _nextPage,
                  borderRadius: BorderRadius.circular(16),
                  splashColor: Colors.white.withOpacity(0.2),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Row(
                        key: ValueKey<bool>(_isLastPage),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isLastPage ? 'Get Started' : 'Next',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              _isLastPage
                                  ? Icons.arrow_forward_rounded
                                  : Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: _isLastPage ? 22 : 18,
                              key: ValueKey<bool>(_isLastPage),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated Page Content ───────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;
  final bool isActive;
  final AnimationController animation;

  const _OnboardingPage({
    required this.data,
    required this.isActive,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Animated Icon ───────────────────────────────────────────────
          _AnimatedIconContainer(
            data: data,
            isActive: isActive,
            animation: animation,
          ),

          const SizedBox(height: 48),

          // ── Title ───────────────────────────────────────────────────────
          _AnimatedText(
            text: data.title,
            isActive: isActive,
            animation: animation,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: data.color,
              height: 1.2,
              letterSpacing: -0.5,
            ),
            delay: 0.2,
          ),

          const SizedBox(height: 20),

          // ── Description ─────────────────────────────────────────────────
          _AnimatedText(
            text: data.description,
            isActive: isActive,
            animation: animation,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.7,
              letterSpacing: 0.2,
            ),
            delay: 0.35,
          ),
        ],
      ),
    );
  }
}

// ─── Animated Icon with Pulse Effect ─────────────────────────────────────────

class _AnimatedIconContainer extends StatefulWidget {
  final OnboardingPageData data;
  final bool isActive;
  final AnimationController animation;

  const _AnimatedIconContainer({
    required this.data,
    required this.isActive,
    required this.animation,
  });

  @override
  State<_AnimatedIconContainer> createState() =>
      _AnimatedIconContainerState();
}

class _AnimatedIconContainerState extends State<_AnimatedIconContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.animation, _pulseAnimation]),
      builder: (context, child) {
        final pageAnim = CurvedAnimation(
          parent: widget.animation,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
        );

        final scale = widget.isActive
            ? _pulseAnimation.value * pageAnim.value
            : pageAnim.value;

        final opacity = widget.isActive ? 1.0 : pageAnim.value;

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              height: 160,
              width: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.data.gradient[0].withOpacity(0.15),
                    widget.data.gradient[1].withOpacity(0.08),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.data.color.withOpacity(0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.data.gradient
                          .map((c) => c.withOpacity(0.2))
                          .toList(),
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.data.icon,
                    size: 60,
                    color: widget.data.color,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Animated Text Widget ────────────────────────────────────────────────────

class _AnimatedText extends StatelessWidget {
  final String text;
  final bool isActive;
  final AnimationController animation;
  final TextStyle style;
  final double delay;

  const _AnimatedText({
    required this.text,
    required this.isActive,
    required this.animation,
    required this.style,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final intervalStart = delay;
        final intervalEnd = (delay + 0.4).clamp(0.0, 1.0);

        final anim = CurvedAnimation(
          parent: animation,
          curve: Interval(intervalStart, intervalEnd, curve: Curves.easeOut),
        );

        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.4),
              end: Offset.zero,
            ).animate(anim),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
        );
      },
    );
  }
}

// ─── Page Indicators ─────────────────────────────────────────────────────────

class _PageIndicators extends StatelessWidget {
  final int count;
  final int currentIndex;
  final Color activeColor;

  const _PageIndicators({
    required this.count,
    required this.currentIndex,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 32 : 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

