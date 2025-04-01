import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'jobs/job_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await _firebaseService.getUserNotifications();
      
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    await _firebaseService.markNotificationAsRead(notificationId);
    _loadNotifications();
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    // Mark as read when tapped
    if (!(notification['isRead'] as bool? ?? false)) {
      await _markAsRead(notification['id'] as String);
    }
    
    // Handle different notification types
    final notificationType = notification['type'] as String? ?? '';
    final notificationData = notification['data'] as Map<String, dynamic>? ?? {};
    
    if (notificationType.contains('job') && notificationData.containsKey('jobId')) {
      final jobId = notificationData['jobId'] as String;
      
      // Get the job details
      try {
        final job = await _firebaseService.getJobById(jobId);
        if (job != null && mounted) {
          // Navigate to job detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobDetailScreen(job: job),
            ),
          ).then((_) => _loadNotifications());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job not found or has been deleted')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading job: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you get notifications, they will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final String title = notification['title'] as String? ?? 'Notification';
    final String body = notification['body'] as String? ?? '';
    final bool isRead = notification['isRead'] as bool? ?? false;
    final DateTime? createdAt = (notification['createdAt'] as Timestamp?)?.toDate();
    
    // Get notification type and icon
    final String type = notification['type'] as String? ?? '';
    IconData notificationIcon;
    Color iconColor;
    
    if (type.contains('job_request')) {
      notificationIcon = Icons.work_outline;
      iconColor = Colors.blue;
    } else if (type.contains('job_accepted')) {
      notificationIcon = Icons.check_circle_outline;
      iconColor = Colors.green;
    } else if (type.contains('job_rejected')) {
      notificationIcon = Icons.cancel_outlined;
      iconColor = Colors.red;
    } else if (type.contains('job_completed')) {
      notificationIcon = Icons.task_alt;
      iconColor = Colors.purple;
    } else if (type.contains('job_started')) {
      notificationIcon = Icons.engineering;
      iconColor = Colors.orange;
    } else if (type.contains('job_cancelled')) {
      notificationIcon = Icons.block;
      iconColor = Colors.grey;
    } else {
      notificationIcon = Icons.notifications;
      iconColor = Colors.blue;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      elevation: isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRead 
            ? BorderSide.none 
            : BorderSide(color: Theme.of(context).primaryColor, width: 1),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(
                  notificationIcon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      createdAt != null
                          ? DateFormat.yMMMd().add_jm().format(createdAt)
                          : 'Just now',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
