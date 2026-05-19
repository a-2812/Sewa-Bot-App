import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DevIndexScreen extends StatelessWidget {
  const DevIndexScreen({super.key});

  final List<Map<String, String>> routes = const [
    {'name': 'Splash Screen', 'route': '/splash'},
    {'name': 'Role Selection', 'route': '/role'},
    {'name': 'Trace Viewer', 'route': '/trace'},
    {'name': 'Login', 'route': '/login'},
    {'name': 'Signup', 'route': '/signup'},
    {'name': 'Forgot Password', 'route': '/forgot-password'},
    {'name': 'Reset Password', 'route': '/reset-password'},
    {'name': 'Email Verification', 'route': '/verify-email'},
    {'name': 'User Home', 'route': '/user/home'},
    {'name': 'User Chat', 'route': '/user/chat'},
    {'name': 'User Providers', 'route': '/user/providers'},
    {'name': 'User Quote', 'route': '/user/quote'},
    {'name': 'User Booking', 'route': '/user/booking'},
    {'name': 'User Status', 'route': '/user/status'},
    {'name': 'User Dispute', 'route': '/user/dispute'},
    {'name': 'Provider Home', 'route': '/provider/home'},
    {'name': 'Provider Incoming Jobs', 'route': '/provider/jobs'},
    {'name': 'Provider Job Detail', 'route': '/provider/job'},
    {'name': 'Provider Active Job', 'route': '/provider/active'},
    {'name': 'Provider Earnings', 'route': '/provider/earnings'},
    {'name': 'Provider Profile', 'route': '/provider/profile'},
    {'name': 'Dummy Screen', 'route': '/dummy'},
    {'name': 'Agent Flow Visualization', 'route': '/agent-flow'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Screens (Dev Index)'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: routes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = routes[index];
          return Card(
            child: ListTile(
              title: Text(
                item['name']!,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                item['route']!,
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pushNamed(context, item['route']!);
              },
            ),
          );
        },
      ),
    );
  }
}
