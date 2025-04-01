import 'package:flutter/material.dart';
import '../../models/job.dart';
import '../../models/worker.dart';
import '../../models/user.dart';
import '../../services/firebase_service.dart';
import '../payment/payment_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;

  const JobDetailScreen({Key? key, required this.job}) : super(key: key);

  @override
  _JobDetailScreenState createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  bool _isApplying = false;
  bool _hasApplied = false;
  bool _isWorker = false;
  bool _isJobSeeker = false;
  Worker? _worker;
  List<Map<String, dynamic>> _applicants = [];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadJobDetails();
  }

  Future<void> _checkUserRole() async {
    final userProfile = await _firebaseService.getCurrentUserProfile();
    final userId = _firebaseService.getCurrentUser()?.uid;

    if (userProfile != null && userId != null) {
      setState(() {
        _isWorker = userProfile.role == 'worker';
        _isJobSeeker = widget.job.seekerId == userId;
        _hasApplied = widget.job.applications.contains(userId);
      });
    }
  }

  Future<void> _loadJobDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load assigned worker details if any
      if (widget.job.workerId != null) {
        final worker =
            await _firebaseService.getWorkerById(widget.job.workerId!);
        setState(() {
          _worker = worker;
        });
      }

      // Load applicants if user is the job seeker
      if (_isJobSeeker && widget.job.applications.isNotEmpty) {
        final applicants =
            await _firebaseService.getJobApplicants(widget.job.id);
        setState(() {
          _applicants = applicants;
        });
      }
    } catch (e) {
      print('Error loading job details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _applyForJob() async {
    setState(() {
      _isApplying = true;
    });

    try {
      await _firebaseService.addApplicationToUser(widget.job.id);
      await _firebaseService.applyForJob(widget.job.id);
      setState(() {
        _hasApplied = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isApplying = false;
      });
    }
  }

  Future<void> _assignWorker(String workerId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _firebaseService.assignJobToWorker(widget.job.id, workerId);
      await _loadJobDetails();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Worker assigned successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markJobAsCompleted() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _firebaseService.updateJobStatus(
          widget.job.id, widget.job.clientId, widget.job.seekerId, 'completed');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job marked as completed!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Go back to job dashboard
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: [
          if (_isJobSeeker && widget.job.status != 'completed')
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  // Navigate to edit job screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit job coming soon!')),
                  );
                } else if (value == 'delete') {
                  _showDeleteConfirmation();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit Job'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title:
                        Text('Delete Job', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildJobStatusBanner(),
                  const SizedBox(height: 16),

                  // Title and budget
                  Text(
                    widget.job.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.attach_money, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        '\$${widget.job.budget.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location and date
                  _buildInfoRow(
                      Icons.location_on, 'Location', widget.job.location),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.calendar_today, 'Posted on',
                      '${widget.job.createdAt.day}/${widget.job.createdAt.month}/${widget.job.createdAt.year}'),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.job.description,
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Assigned worker section
                  if (widget.job.status == 'assigned' && _worker != null)
                    _buildAssignedWorkerSection(),

                  // Applicants section for job poster
                  if (_isJobSeeker &&
                      widget.job.status == 'open' &&
                      _applicants.isNotEmpty)
                    _buildApplicantsSection(),

                  // Action buttons based on user role and job status
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildJobStatusBanner() {
    Color bannerColor;
    String statusMessage;
    IconData statusIcon;

    switch (widget.job.status) {
      case 'open':
        bannerColor = Colors.blue;
        statusMessage = 'This job is open for applications';
        statusIcon = Icons.access_time;
        break;
      case 'assigned':
        bannerColor = Colors.orange;
        statusMessage = 'This job is in progress';
        statusIcon = Icons.engineering;
        break;
      case 'completed':
        bannerColor = Colors.green;
        statusMessage = 'This job has been completed';
        statusIcon = Icons.check_circle;
        break;
      default:
        bannerColor = Colors.grey;
        statusMessage = 'Unknown status';
        statusIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        border: Border.all(color: bannerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: bannerColor),
          const SizedBox(width: 12),
          Text(
            statusMessage,
            style: TextStyle(
              fontSize: 16,
              color: bannerColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAssignedWorkerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assigned Professional',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(_worker!.profileImage),
                onBackgroundImageError: (e, s) => {},
                child: _worker!.profileImage.isEmpty
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _worker!.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _worker!.profession,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_worker!.rating} (${_worker!.completedJobs} jobs)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.phone, color: Colors.blue),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calling ${_worker!.name}...')),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildApplicantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Applicants (${_applicants.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _applicants.length,
          itemBuilder: (context, index) {
            final applicant = _applicants[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: applicant['profileImage'] != null
                          ? NetworkImage(applicant['profileImage'])
                          : null,
                      child: applicant['profileImage'] == null
                          ? const Icon(Icons.person, size: 25)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            applicant['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            applicant['profession'] ?? 'Professional',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (applicant['rating'] != null)
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${applicant['rating']} (${applicant['completedJobs'] ?? 0} jobs)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _assignWorker(applicant['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Hire'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActionButtons() {
    // Worker viewing an open job they haven't applied to
    if (_isWorker && widget.job.status == 'open' && !_hasApplied) {
      return ElevatedButton(
        onPressed: _isApplying ? null : _applyForJob,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size.fromHeight(50),
        ),
        child: _isApplying
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Apply for This Job',
                style: TextStyle(fontSize: 16),
              ),
      );
    }

    // Worker viewing an open job they have applied to
    if (_isWorker && widget.job.status == 'open' && _hasApplied) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'You have applied for this job',
                style: TextStyle(fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }

    // Worker assigned to this job
    if (_isWorker &&
        widget.job.status == 'assigned' &&
        widget.job.workerId == _firebaseService.getCurrentUser()?.uid) {
      return Column(
        children: [
          ElevatedButton(
            onPressed: () => _markJobAsCompleted(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.green,
            ),
            child: const Text(
              'Mark as Completed',
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon!')),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text(
              'Contact Client',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      );
    }

    // Client viewing their own job
    if (_isJobSeeker) {
      if (widget.job.status == 'open') {
        // If open and no applications
        if (widget.job.applications.isEmpty) {
          return Column(
            children: [
              const Text(
                'No applications yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Sharing feature coming soon!')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text(
                  'Share this Job',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          );
        }
      } else if (widget.job.status == 'assigned') {
        return Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(job: widget.job),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Pay Now',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat feature coming soon!')),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                'Message Worker',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      } else if (widget.job.status == 'completed') {
        return Column(
          children: [
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review feature coming soon!')),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                'Leave a Review',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                'Post Similar Job',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      }
    }

    // Default - just view details
    return const SizedBox.shrink();
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job'),
        content: const Text('Are you sure you want to delete this job?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firebaseService.deleteJob(widget.job.id);
                Navigator.pop(context); // Go back to job dashboard
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Job deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting job: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
