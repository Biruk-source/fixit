import 'package:flutter/material.dart';
import '../../models/job.dart';
import '../../models/worker.dart';
import '../../models/user.dart';
import '../../services/firebase_service.dart';
import '../payment/payment_screen.dart';

// Yo, this is our JobDetailScreen, gonna make it look fresh af
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

  // Same logic, just keeping it tight
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
    setState(() => _isLoading = true);
    try {
      if (widget.job.workerId != null) {
        final worker =
            await _firebaseService.getWorkerById(widget.job.workerId!);
        setState(() => _worker = worker);
      }
      if (_isJobSeeker && widget.job.applications.isNotEmpty) {
        final applicants =
            await _firebaseService.getJobApplicants(widget.job.id);
        setState(() => _applicants = applicants);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyForJob() async {
    setState(() => _isApplying = true);
    try {
      await _firebaseService.addApplicationToUser(widget.job.id);
      await _firebaseService.applyForJob(widget.job.id);
      setState(() => _hasApplied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Applied, you’re in!'),
            backgroundColor: Colors.greenAccent),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oops: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isApplying = false);
    }
  }

  Future<void> _assignWorker(String workerId) async {
    setState(() => _isLoading = true);
    try {
      await _firebaseService.assignJobToWorker(widget.job.id, workerId);
      await _loadJobDetails();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Worker locked in!'),
            backgroundColor: Colors.greenAccent),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markJobAsCompleted() async {
    setState(() => _isLoading = true);
    try {
      await _firebaseService.updateJobStatus(
          widget.job.id, widget.job.clientId, widget.job.seekerId, 'completed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Job done, nice!'),
            backgroundColor: Colors.greenAccent),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ultra-dark bg with a slick gradient
      backgroundColor: const Color(0xFF080808),
      body: CustomScrollView(
        slivers: [
          // SliverAppBar with a futuristic edge
          SliverAppBar(
            expandedHeight: 240.0, // Taller for that bold presence
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1521791136064-7986c2920216?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
                    fit: BoxFit.cover,
                  ),
                  // Neon-edged dark overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      border: Border.all(
                          color: Colors.tealAccent.withOpacity(0.3), width: 2),
                    ),
                  ),
                ],
              ),
              title: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.tealAccent.withOpacity(0.4),
                        blurRadius: 10)
                  ],
                ),
                child: Text(
                  widget.job.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                    shadows: [Shadow(color: Colors.tealAccent, blurRadius: 8)],
                  ),
                ),
              ),
              centerTitle: true,
            ),
            backgroundColor:
                const Color(0xFF0D1B2A), // Midnight blue with swagger
            elevation: 8,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            actions: [
              if (_isJobSeeker && widget.job.status != 'completed')
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: Colors.white, size: 28),
                  color: const Color(0xFF1A1A1A),
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  onSelected: (value) {
                    if (value == 'edit') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Edit job dropping soon, fam!')),
                      );
                    } else if (value == 'delete') {
                      _showDeleteConfirmation();
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit,
                            color: Colors.tealAccent, size: 26),
                        title: Text('Edit Job',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete,
                            color: Colors.redAccent, size: 26),
                        title: Text('Delete Job',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Colors.tealAccent, strokeWidth: 3))
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF080808),
                          Color(0xFF141414)
                        ], // Smooth dark flow
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(
                          28.0), // Extra padding for that luxe feel
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildJobStatusChip(),
                          const SizedBox(height: 24),
                          // Budget with a bold neon chip
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.tealAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: Colors.tealAccent.withOpacity(0.5),
                                  width: 2),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.tealAccent.withOpacity(0.3),
                                    blurRadius: 12)
                              ],
                            ),
                            child: Text(
                              '\$${widget.job.budget.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.tealAccent,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Location and date with slick cards
                          _buildDetailRow(
                            icon: Icons.location_on,
                            title: 'Location',
                            value: widget.job.location,
                          ),
                          const SizedBox(height: 20),
                          _buildDetailRow(
                            icon: Icons.calendar_today,
                            title: 'Posted on',
                            value:
                                '${widget.job.createdAt.day}/${widget.job.createdAt.month}/${widget.job.createdAt.year}',
                          ),
                          const SizedBox(height: 36),
                          // Description with a premium dark card
                          const Text(
                            'Job Description',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.tealAccent,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(color: Colors.tealAccent, blurRadius: 8)
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141414),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: Colors.tealAccent.withOpacity(0.3),
                                  width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 16)
                              ],
                            ),
                            child: Text(
                              widget.job.description,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                height: 1.7,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          // Assigned worker section
                          if (widget.job.status == 'assigned' &&
                              _worker != null)
                            _buildAssignedWorkerCard(),
                          // Applicants section
                          if (_isJobSeeker &&
                              widget.job.status == 'open' &&
                              _applicants.isNotEmpty)
                            _buildApplicantsSection(),
                          // Action buttons
                          const SizedBox(height: 36),
                          _buildActionButtons(),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

// Status chip with a bold neon vibe
  Widget _buildJobStatusChip() {
    Color chipColor;
    String statusText;

    switch (widget.job.status) {
      case 'open':
        chipColor = Colors.tealAccent;
        statusText = 'Open for applications';
        break;
      case 'assigned':
        chipColor = Colors.orangeAccent;
        statusText = 'In progress';
        break;
      case 'completed':
        chipColor = Colors.greenAccent;
        statusText = 'Completed';
        break;
      default:
        chipColor = Colors.grey;
        statusText = 'Unknown';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: chipColor.withOpacity(0.4), blurRadius: 12)
        ],
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

// Detail row with a sharp dark card
  Widget _buildDetailRow(
      {required IconData icon, required String title, required String value}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.tealAccent.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.tealAccent, size: 26),
          const SizedBox(width: 14),
          Text(
            '$title: ',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Assigned worker card with a handsome dark glow
  Widget _buildAssignedWorkerCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assigned Professional',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.tealAccent,
            letterSpacing: 1.2,
            shadows: [Shadow(color: Colors.tealAccent, blurRadius: 8)],
          ),
        ),
        const SizedBox(height: 24),
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.tealAccent.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 16)
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundImage: NetworkImage(_worker!.profileImage),
                backgroundColor: Colors.grey[900],
                child: _worker!.profileImage.isEmpty
                    ? const Icon(Icons.person, size: 45, color: Colors.white70)
                    : null,
                foregroundColor: Colors.tealAccent.withOpacity(0.2),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _worker!.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _worker!.profession,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${_worker!.rating} (${_worker!.completedJobs} jobs)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.tealAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.tealAccent.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.tealAccent.withOpacity(0.3),
                          blurRadius: 10)
                    ],
                  ),
                  child: const Icon(Icons.phone,
                      color: Colors.tealAccent, size: 26),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calling ${_worker!.name}...')),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
      ],
    );
  }

// Applicants section with dope dark cards
  Widget _buildApplicantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Applicants',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.tealAccent,
                letterSpacing: 1.2,
                shadows: [Shadow(color: Colors.tealAccent, blurRadius: 8)],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.tealAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.tealAccent.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                      color: Colors.tealAccent.withOpacity(0.3), blurRadius: 10)
                ],
              ),
              child: Text(
                '${_applicants.length}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.tealAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ..._applicants.map((applicant) => _buildApplicantCard(applicant)),
      ],
    );
  }

// Applicant card with a sharp, handsome glow
  Widget _buildApplicantCard(Map<String, dynamic> applicant) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: Colors.tealAccent.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 16)
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundImage: applicant['profileImage'] != null
                ? NetworkImage(applicant['profileImage'])
                : null,
            backgroundColor: Colors.grey[900],
            child: applicant['profileImage'] == null
                ? const Icon(Icons.person, size: 35, color: Colors.white70)
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  applicant['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  applicant['profession'] ?? 'Professional',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    letterSpacing: 0.8,
                  ),
                ),
                if (applicant['rating'] != null)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${applicant['rating']} (${applicant['completedJobs'] ?? 0} jobs)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          letterSpacing: 0.5,
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
              backgroundColor: Colors.tealAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              elevation: 6,
              shadowColor: Colors.black54,
            ),
            child: const Text(
              'Hire',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

// Action buttons with a bold, neon swagger
  Widget _buildActionButtons() {
    // Worker viewing an open job they haven't applied to
    if (_isWorker && widget.job.status == 'open' && !_hasApplied) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isApplying ? null : _applyForJob,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.tealAccent,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            shadowColor: Colors.tealAccent.withOpacity(0.5),
          ),
          child: _isApplying
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: Colors.black),
                )
              : const Text(
                  'Apply for This Job',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 1.2),
                ),
        ),
      );
    }

    // Worker viewing an open job they have applied to
    if (_isWorker && widget.job.status == 'open' && _hasApplied) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: Colors.tealAccent.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.tealAccent, size: 26),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'You have applied for this job',
                style: TextStyle(
                    fontSize: 16, color: Colors.white70, letterSpacing: 0.5),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cancel feature coming soon!')),
                );
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _markJobAsCompleted(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 8,
                shadowColor: Colors.greenAccent.withOpacity(0.5),
              ),
              child: const Text(
                'Mark as Completed',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact feature coming soon!')),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                side: const BorderSide(color: Colors.tealAccent, width: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text(
                'Contact Client',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.tealAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Client viewing their own job
    if (_isJobSeeker) {
      if (widget.job.status == 'open' && widget.job.applications.isEmpty) {
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.tealAccent.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.4), blurRadius: 10)
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.people_alt_outlined,
                      size: 48, color: Colors.tealAccent),
                  const SizedBox(height: 16),
                  Text(
                    'No applications yet',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Sharing feature coming soon!')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  side: const BorderSide(color: Colors.tealAccent, width: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.share, size: 24, color: Colors.tealAccent),
                    const SizedBox(width: 10),
                    const Text(
                      'Share this Job',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.tealAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      } else if (widget.job.status == 'assigned') {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PaymentScreen(job: widget.job)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  shadowColor: Colors.tealAccent.withOpacity(0.5),
                ),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat feature coming soon!')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  side: const BorderSide(color: Colors.tealAccent, width: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  'Message Worker',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.tealAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        );
      } else if (widget.job.status == 'completed') {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Review feature coming soon!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  shadowColor: Colors.tealAccent.withOpacity(0.5),
                ),
                child: const Text(
                  'Leave a Review',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature coming soon!')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  side: const BorderSide(color: Colors.tealAccent, width: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  'Post Similar Job',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.tealAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        );
      }
    }

    return const SizedBox.shrink();
  }

  // Delete confirmation with a modern dialog
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Job',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('You sure you wanna ditch this job?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nah, keep it')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firebaseService.deleteJob(widget.job.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Job gone, peace!'),
                      backgroundColor: Colors.greenAccent),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text('Yup, delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
