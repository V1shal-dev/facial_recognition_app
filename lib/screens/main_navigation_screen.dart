import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  late PageController _pageController;

  final List<Widget> _screens = const [
    HomeScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            elevation: 0,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.deepPurple,
            unselectedItemColor: Colors.grey.shade400,
            selectedFontSize: 14,
            unselectedFontSize: 12,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 28),
                activeIcon: Icon(Icons.home, size: 28),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline, size: 28),
                activeIcon: Icon(Icons.person, size: 28),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}