import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:my_app1/screens/post_job_screen.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/jobs/create_job_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/job_history_screen.dart';
import 'screens/professional_setup_screen.dart'; // Import the ProfessionalSetupScreen
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'screens/jobs/job_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FixIt',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          color: Colors.blue,
          elevation: 0,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/home': (context) => const MainScreen(),
        '/login': (context) => const LoginScreen(),
        '/professional-setup': (context) => const ProfessionalSetupScreen(),
        '/jobs': (context) => const JobDashboardScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/post-job': (context) => const CreateJobScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    try {
      if (authService.isUserLoggedIn()) {
        return const MainScreen();
      } else {
        return const LoginScreen();
      }
    } catch (e) {
      print('Error in AuthWrapper: $e');
      return const LoginScreen();
    }
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String _userType = 'client';
  bool _isLoading = true;
  final AuthService _authService = AuthService();
  late List<Widget> _screens;
  late List<GButton> _navItems; // Changed from GNavItem to GButton

  @override
  void initState() {
    super.initState();
    _determineUserType();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _determineUserType();
  }

  Future<void> _determineUserType() async {
    try {
      setState(() => _isLoading = true);
      final userProfile = await _authService.getCurrentUserProfile();
      if (userProfile != null) {
        setState(() {
          _userType = userProfile.role == 'worker' ? 'professional' : 'client';
          _isLoading = false;
        });
        _initializeScreensAndNavItems();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error determining user type: $e');
    }
  }

  void _initializeScreensAndNavItems() {
    if (_userType == 'professional') {
      _screens = [
        const HomeScreen(),
        const ProfileScreen(),
        const JobDashboardScreen(),
        const ProfessionalSetupScreen(),
      ];

      _navItems = [
        GButton(
          icon: LineIcons.briefcase,
          text: 'Jobs',
        ),
        GButton(
          icon: LineIcons.user,
          text: 'Profile',
        ),
        GButton(
          icon: LineIcons.syncIcon,
          text: 'My job',
        ),
        GButton(
          icon: LineIcons.edit,
          text: 'Profile',
        ),
      ];
    } else {
      _screens = [
        const HomeScreen(),
        const CreateJobScreen(),
        const ProfileScreen(),
        const JobHistoryScreen(),
      ];

      _navItems = [
        GButton(
          icon: LineIcons.home,
          text: 'Home',
        ),
        GButton(
          icon: LineIcons.plusCircle,
          text: 'Post Job',
        ),
        GButton(
          icon: LineIcons.user,
          text: 'Profile',
        ),
        GButton(
          icon: LineIcons.history,
          text: 'History',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 3,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: GNav(
              rippleColor: Colors.blueAccent.withOpacity(0.3),
              hoverColor: Colors.blueAccent.withOpacity(0.2),
              gap: 8,
              activeColor: Colors.white,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Colors.blueAccent.withOpacity(0.3),
              color: Colors.white70,
              tabs: _navItems,
              selectedIndex: _selectedIndex,
              onTabChange: (index) => setState(() => _selectedIndex = index),
            ),
          ),
        ),
      ),
    );
  }
}
