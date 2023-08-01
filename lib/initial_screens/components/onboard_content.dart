import 'package:flutter/material.dart';
import 'package:mycommunity/initial_screens/components/landed_content.dart';
import 'package:mycommunity/initial_screens/components/sing_up_form.dart';
import 'package:mycommunity/initial_screens/signup/personal/components/body.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardContent extends StatefulWidget {
  const OnboardContent({Key? key}) : super(key: key);

  @override
  State<OnboardContent> createState() => _OnboardContentState();
}

class _OnboardContentState extends State<OnboardContent> {
  late PageController _pageController;
  // double _progress;
  @override
  void initState() {
    _pageController = PageController()
      ..addListener(() {
        setState(() {});
      });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double progress =
        _pageController.hasClients ? (_pageController.page ?? 0) : 0;

    return SizedBox(
      height: 400 + progress * 140,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              const SizedBox(height: 16),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  children: const [
                    LandingContent(),
                    SignUpForm(),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            height: 56,
            bottom: 32 + progress * 30,
            right: 16,
            child: GestureDetector(
              onTap: () async {
                if (_pageController.page == 0) {
                  _pageController.animateToPage(1,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.ease);
                }
                if (_pageController.page == 1) {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('seenOnboarding', true);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const PersonalSignupBody();
                      },
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    stops: [0.4, 0.8],
                    colors: [
                      Color.fromARGB(255, 239, 104, 80),
                      Color.fromARGB(255, 139, 33, 146)
                    ],
                  ),
                ),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 92 + progress * 35,
                        child: Stack(
                          fit: StackFit.passthrough,
                          children: [
                            Opacity(
                              opacity: 1 - progress,
                              child: const Text("Get Started", style: TextStyle(fontFamily: 'Raleway')),
                            ),
                            Opacity(
                              opacity: progress,
                                child: const Text(
                                  "Create account",
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                  softWrap: false,
                                  style: TextStyle(
                                    fontFamily: 'Raleway',
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            )
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: Colors.white,
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
