import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/firebase_service.dart';
import '../models/user.dart';
import '../models/job.dart';
import 'auth/login_screen.dart';
import 'jobs/job_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  AppUser? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await _firebaseService.getCurrentUserProfile();
      setState(() {
        _userProfile = userData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _firebaseService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? const Center(child: Text('User profile not found'))
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    final bool isWorker =
        _userProfile!.role == 'worker' || _userProfile!.role == 'professional';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header with avatar
          _buildProfileHeader(),

          const SizedBox(height: 24),

          // Profile sections
          _buildProfileStats(),

          const SizedBox(height: 16),
          const Divider(),

          // Job History section
          _buildJobHistory(),

          const SizedBox(height: 16),
          const Divider(),

          // Settings section
          _buildSettings(),

          const SizedBox(height: 24),

          // Edit profile button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Navigate to edit profile screen
                if (isWorker) {
                  Navigator.pushNamed(context, '/professional-setup');
                } else {
                  _showEditProfileDialog();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final profileData = _userProfile!;
    final name = profileData.name;
    final userType = profileData.role == 'worker' ? 'Professional' : 'Client';
    final profileImage = profileData.profileImage;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showImagePickerOptions(context),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        profileImage != null && profileImage.isNotEmpty
                            ? NetworkImage(profileImage)
                            : const AssetImage('assets/images/default_profile.png')
                                as ImageProvider,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade500,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                userType,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorHeader() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Could not load profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please try again later',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
      });

      // Upload the image to Firebase Storage
      final imageFile = File(pickedFile.path);
      final imageUrl = await _firebaseService.uploadProfileImage(imageFile);

      setState(() {
        _isLoading = false;
      });

      if (imageUrl != null) {
        // Reload profile data to display the new image
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to update profile picture. Try again.')),
        );
      }
    }
  }

  Widget _buildProfileStats() {
    final bool isWorker =
        _userProfile!.role == 'worker' || _userProfile!.role == 'professional';

    if (isWorker) {
      // Worker stats
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Professional Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Stats cards
          Row(
            children: [
              _buildStatCard(
                'Jobs Completed',
                '${_userProfile!.jobsCompleted ?? 0}',
                Icons.task_alt,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Rating',
                '${(_userProfile!.rating ?? 0.0).toStringAsFixed(1)}',
                Icons.star,
                Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                'Experience',
                '${_userProfile!.experience ?? 0} years',
                Icons.work_history,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Reviews',
                '${_userProfile!.reviewCount ?? 0}',
                Icons.rate_review,
                Colors.purple,
              ),
            ],
          ),
        ],
      );
    } else {
      // Client stats
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Client Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Stats cards
          Row(
            children: [
              _buildStatCard(
                'Jobs Posted',
                '${_userProfile!.jobsPosted ?? 0}',
                Icons.post_add,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Payments',
                '${_userProfile!.paymentsComplete ?? 0}',
                Icons.payment,
                Colors.green,
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobHistory() {
    return FutureBuilder<List<dynamic>>(
      future: _loadJobHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Error loading job history: ${snapshot.error}'));
        }

        final jobs = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Job History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/jobs');
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            jobs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text(
                        'No job history yet',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: jobs.length > 3
                        ? 5
                        : jobs.length, // Show max 3 jobs in profile
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return _buildJobHistoryItem(job);
                    },
                  ),
          ],
        );
      },
    );
  }

  Widget _buildJobHistoryItem(Job job) {
    final String status = job.status;
    final Color statusColor = _getStatusColor(status);
    final IconData statusIcon = _getStatusIcon(status);
    final String title = job.title.isEmpty ? 'Untitled Job' : job.title;
    final String location =
        job.location.isEmpty ? 'Unknown Location' : job.location;
    final String budget = '${job.budget.toStringAsFixed(0)} ETB';
    final String description =
        job.description.isEmpty ? 'No description provided' : job.description;
    final String workerName =
        job.workerName.isEmpty ? 'Not assigned' : job.workerName;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailScreen(job: job),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Status Icon with a subtle background
              CircleAvatar(
                radius: 24,
                backgroundColor: statusColor.withOpacity(0.1),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),

              // Job Details (Title, Location, Budget, Description, Worker Name)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Job Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis, // Keeps the text neat
                    ),
                    const SizedBox(height: 6),

                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Budget
                    Row(
                      children: [
                        const Icon(Icons.monetization_on,
                            size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          budget,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Assigned Worker
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          'Worker: $workerName',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.blue;
      case 'assigned':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Icons.work_outline;
      case 'assigned':
        return Icons.person_search;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Settings list
        _buildSettingItem(
          'Notifications',
          'Manage your notification preferences',
          Icons.notifications,
          () => _showNotificationSettings(),
        ),

        _buildSettingItem(
          'Payment Methods',
          'Manage your payment methods',
          Icons.payment,
          () => _navigateToPaymentMethods(),
        ),

        _buildSettingItem(
          'Privacy & Security',
          'Manage your privacy and security settings',
          Icons.security,
          () => _showPrivacySettings(),
        ),

        _buildSettingItem(
          'Account',
          'Manage your account settings',
          Icons.account_circle,
          () => _showAccountSettings(),
        ),

        _buildSettingItem(
          'Help & Support',
          'Get help and contact support',
          Icons.help,
          () => _showHelpAndSupport(),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Future<List<dynamic>> _loadJobHistory() async {
    try {
      final isWorker = _userProfile!.role == 'worker' ||
          _userProfile!.role == 'professional';
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return [];

      // Call the getUserJobs method with the correct named parameters
      final jobs = await _firebaseService.getUserJobs(
          userId: user.uid, isWorker: isWorker);

      return jobs;
    } catch (e) {
      print('Error loading job history: $e');
      return [];
    }
  }

  // Action handlers
  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Profile Picture'),
        content: const Text('This feature will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    // Show dialog to edit basic profile info
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text('This feature will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    _showSettingsDialog('Notification Settings',
        'Customize how and when you receive notifications');
  }

  void _navigateToPaymentMethods() {
    _showSettingsDialog(
        'Payment Methods', 'Add or remove payment methods for your account');
  }

  void _showPrivacySettings() {
    _showSettingsDialog(
        'Privacy & Security', 'Manage your privacy and security settings');
  }

  void _showAccountSettings() {
    _showSettingsDialog(
        'Account Settings', 'Update your account information and preferences');
  }

  void _showHelpAndSupport() {
    _showSettingsDialog('Help & Support', 'Get help and contact support');
  }

  void _showSettingsDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.engineering,
              size: 64,
              color: Colors.amber[700],
            ),
            const SizedBox(height: 16),
            Text(content),
            const SizedBox(height: 16),
            const Text(
              'This feature is coming soon!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
