import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../services/pref_service.dart';
import 'role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(bottom: 80),
        child: PageView(
          controller: _controller,
          onPageChanged: (index) {
            setState(() => isLastPage = index == 2);
          },
          children: [
            _buildPage(
              color: Colors.white,
              image: 'https://i.pinimg.com/736x/83/e9/99/83e999fcb40750b2e2a777d8cc497810.jpg',
              title: 'Find Top Services',
              subtitle: 'Connect with reliable service providers in your local area easily.',
            ),
            _buildPage(
              color: Colors.white,
              image: 'https://i.pinimg.com/736x/1e/e4/53/1ee453e7e6a44b0c78c11e65ba6a007c.jpg',
              title: 'Offer Your Expertise',
              subtitle: 'Are you a professional? Grow your business by reaching more clients.',
            ),
            _buildPage(
              color: Colors.white,
              image: 'https://i.pinimg.com/736x/ab/3e/29/ab3e29bf3c5f217b86837b3660d4d7c4.jpg',
              title: 'Secure & Reliable',
              subtitle: 'Enjoy secure transactions and transparent service reviews.',
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 80,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => _controller.jumpToPage(2),
              child: Text('SKIP', style: TextStyle(color: Colors.red[900])),
            ),
            Center(
              child: SmoothPageIndicator(
                controller: _controller,
                count: 3,
                effect: WormEffect(
                  spacing: 16,
                  dotColor: Colors.black26,
                  activeDotColor: Colors.red[900]!,
                ),
                onDotClicked: (index) => _controller.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeIn,
                ),
              ),
            ),
            isLastPage
                ? TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);

                await PrefService.setFirstLaunchComplete();

                if (!mounted) return;

                navigator.pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const RoleSelectionScreen(),
                  ),
                );
              },
                    child: Text('DONE', style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold)),
                  )
                : TextButton(
                    onPressed: () => _controller.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    ),
                    child: Text('NEXT', style: TextStyle(color: Colors.red[900])),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required Color color,
    required String image,
    required String title,
    required String subtitle,
  }) {
    return Container(
      color: color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(image, width: 300),
          const SizedBox(height: 64),
          Text(
            title,
            style: TextStyle(
              color: Colors.red[900],
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
