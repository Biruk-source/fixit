import 'package:flutter/material.dart';
import '../models/worker.dart';
import '../models/job.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart'; // Import the new AuthService
import 'worker_detail_screen.dart';
import 'jobs/create_job_screen.dart';
import 'jobs/job_detail_screen.dart'; // Add missing import for JobDetailScreen
import 'notifications_screen.dart';
import 'job_history_screen.dart';
import 'professional_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService(); // Add AuthService
  bool _isLoading = true;
  String _userType = 'client'; // Default to client
  AppUser? _currentUser; // Store the current user profile

  // For client view (showing workers)
  List<Worker> _workers = [];
  List<Worker> _filteredWorkers = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedLocation = 'All';
  List<String> _locations = [
    'All',
    'Adama',
    'Addis Ababa',
    'Bahir Dar',
    'Hawassa',
    'Mekelle'
  ];

  // For professional view (showing jobs)
  List<Job> _jobs = [];
  List<Job> _filteredJobs = [];
  String _selectedJobStatus = 'All';
  List<String> _jobStatuses = ['All', 'Open', 'Assigned', 'Completed'];
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _determineUserTypeAndLoadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final userProfile = await _authService.getCurrentUserProfile();
      if (userProfile == null) {
        print('User profile not found in _loadCurrentUserId');
        return;
      }

      final userRole = userProfile.role;
      bool isClient = userRole == 'client';

      setState(() {
        currentUserId = userProfile.id;
      });

      if (isClient) {
        print('Current user is a client');
      } else {
        print('Current user is a professional');
      }
    } catch (e) {
      print('Error in _loadCurrentUserId: $e');
    }
  }

  Future<void> _determineUserTypeAndLoadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use our new AuthService instead of FirebaseService
      final userProfile = await _authService.getCurrentUserProfile();

      if (userProfile == null) {
        print('User profile not found - defaulting to client view');
        setState(() {
          _userType = 'client';
          _currentUser = null;
        });
      } else {
        print(
            'User profile loaded: ${userProfile.name}, Role: ${userProfile.role}');
        setState(() {
          _currentUser = userProfile;
          // Map the role to our expected user type
          _userType = userProfile.role == 'worker' ? 'worker' : 'client';
        });
      }

      // Load data based on user type
      if (_userType == 'client') {
        await _loadWorkers();
      } else {
        await _loadJobs();
      }
    } catch (e) {
      print('Error determining user type: $e');
      // Default to client view on error
      setState(() {
        _userType = 'client';
      });
      await _loadWorkers();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadWorkers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get current user profile to determine user type
      final userProfile = await _firebaseService.getCurrentUserProfile();

      if (userProfile == null) {
        print('No user profile found');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userType = userProfile.role as String? ?? 'client';
      bool _isClient = userType == 'client';

      if (_isClient) {
        // If client, fetch worker list from professionals collection
        final workers =
            await _firebaseService.getWorkers(location: _selectedLocation);

        if (workers.isEmpty) {
          print('No workers found - attempting to create sample data');
          await _createSampleWorkersIfNeeded();

          // Try loading again after creating samples
          final updatedWorkers =
              await _firebaseService.getWorkers(location: _selectedLocation);

          setState(() {
            _workers = updatedWorkers;
            _filteredWorkers = updatedWorkers;
            _isLoading = false;
          });
          return;
        }

        // Generate list of all locations for filtering
        final Set<String> locations = {'All'};
        for (var worker in workers) {
          if (worker.location.isNotEmpty) {
            locations.add(worker.location);
          }
        }

        setState(() {
          _workers = workers;
          _filteredWorkers = workers;
          _locations = locations.toList()..sort();
          _isLoading = false;
        });
      } else {
        // If professional, load jobs instead of workers
        final jobs = await _firebaseService.getJobs();

        setState(() {
          _jobs = jobs;
          _filteredJobs = jobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading workers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to create sample workers if none exist
  Future<void> _createSampleWorkersIfNeeded() async {
    try {
      // Check if we already have workers
      final existingWorkers = await _firebaseService.getWorkers();
      if (existingWorkers.isNotEmpty) {
        print(
            'Found ${existingWorkers.length} existing workers, not creating samples.');
        return;
      }

      // Create some sample workers for demo purposes
      final sampleWorkers = [
        {
          'name': 'Abebe Kebede',
          'profession': 'Electrician',
          'experience': 5,
          'priceRange': 500.0,
          'location': 'Addis Ababa',
          'skills': ['Wiring', 'Installation', 'Repairs'],
          'about':
              'Experienced electrician specializing in home and office installations.',
          'profileImage': 'https://randomuser.me/api/portraits/men/1.jpg',
        },
        {
          'name': 'Sara Haile',
          'profession': 'Plumber',
          'experience': 3,
          'priceRange': 450.0,
          'location': 'Adama',
          'skills': ['Pipe Fitting', 'Leak Repair', 'Installation'],
          'about':
              'Professional plumber providing quality services for residential and commercial properties.',
          'profileImage': 'https://randomuser.me/api/portraits/women/2.jpg',
        },
        {
          'name': 'Dawit Mengistu',
          'profession': 'Carpenter',
          'experience': 7,
          'priceRange': 600.0,
          'location': 'Bahir Dar',
          'skills': ['Furniture Making', 'Cabinet Installation', 'Wood Repair'],
          'about':
              'Skilled carpenter with expertise in custom furniture design and woodworking.',
          'profileImage': 'https://randomuser.me/api/portraits/men/3.jpg',
        },
        {
          'name': 'Tigist Bekele',
          'profession': 'Cleaner',
          'experience': 2,
          'priceRange': 300.0,
          'location': 'Addis Ababa',
          'skills': ['Home Cleaning', 'Office Cleaning', 'Deep Cleaning'],
          'about':
              'Thorough and efficient cleaner providing excellent services for homes and offices.',
          'profileImage': 'https://randomuser.me/api/portraits/women/4.jpg',
        },
      ];

      // Add sample workers to Firebase
      for (var worker in sampleWorkers) {
        await _firebaseService.createSampleWorker(
          name: worker['name'] as String,
          profession: worker['profession'] as String,
          experience: worker['experience'] as int,
          priceRange: worker['priceRange'] as double,
          location: worker['location'] as String,
          skills: (worker['skills'] as List<dynamic>).cast<String>(),
          about: worker['about'] as String,
          profileImage: worker['profileImage'] as String,
        );
      }

      // Reload workers after creating samples
      final updatedWorkers = await _firebaseService.getWorkers();
      setState(() {
        _workers = updatedWorkers;
        _filteredWorkers = updatedWorkers;
      });

      print('Created and loaded ${updatedWorkers.length} sample workers');
    } catch (e) {
      print('Error creating sample workers: $e');
    }
  }

  Future<void> _loadJobs() async {
    try {
      // Load open jobs for professionals
      var jobs = await _firebaseService.getJobs(
          status: _selectedJobStatus == 'All'
              ? null
              : _selectedJobStatus.toLowerCase());

      setState(() {
        _jobs = jobs;
        _filteredJobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading jobs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterWorkers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredWorkers = _workers;
      });
      return;
    }

    setState(() {
      _filteredWorkers = _workers.where((worker) {
        final nameMatch =
            worker.name.toLowerCase().contains(query.toLowerCase());
        final professionMatch =
            worker.profession.toLowerCase().contains(query.toLowerCase());
        final skillsMatch = worker.skills
            .any((skill) => skill.toLowerCase().contains(query.toLowerCase()));
        return nameMatch || professionMatch || skillsMatch;
      }).toList();
    });
  }

  void _filterJobs(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredJobs = _jobs;
      });
      return;
    }

    setState(() {
      _filteredJobs = _jobs.where((job) {
        final titleMatch =
            job.title.toLowerCase().contains(query.toLowerCase());
        final descriptionMatch =
            job.description.toLowerCase().contains(query.toLowerCase());
        return titleMatch || descriptionMatch;
      }).toList();
    });
  }

  void _filterByLocation(String location) {
    setState(() {
      _selectedLocation = location;
      if (location == 'All') {
        _filteredWorkers = _workers;
      } else {
        _filteredWorkers =
            _workers.where((worker) => worker.location == location).toList();
      }
    });
  }

  void _filterByJobStatus(String status) {
    setState(() {
      _selectedJobStatus = status;
      _isLoading = true;
    });

    // Reload jobs with filter
    _loadJobs();
  }

  void _navigateToCreateJob() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateJobScreen()),
    ).then((_) {
      // Refresh jobs list when returning from create job screen
      if (_userType == 'professional') {
        _loadJobs();
      }
    });
  }

  void navigateToCreateProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const ProfessionalSetupScreen())).then((_) {
      // Refresh jobs list when returning from create job screen
      if (_userType == 'professional') {
        _loadJobs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            _userType == 'client' ? 'Find Professionals' : 'Available Jobs'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              alignment: Alignment.topRight,
              children: [
                const Icon(Icons.notifications),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const JobHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_userType == 'client') {
                _loadWorkers();
              } else {
                _loadJobs();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter area
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.indigo[900]!, Colors.indigo[700]!],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search field
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 247, 231, 214),
                    borderRadius: BorderRadius.circular(30.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 49, 60, 35)
                            .withOpacity(0.5),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: _userType == 'client'
                          ? 'Search by skill, profession, or name...'
                          : 'Search for jobs...',
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.indigo),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onChanged:
                        _userType == 'client' ? _filterWorkers : _filterJobs,
                  ),
                ),
                const SizedBox(height: 16),

                // Label for filters
                const Text(
                  'Filter by:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),

                // Filter chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _userType == 'client'
                        ? _locations.map((location) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text(location),
                                selected: _selectedLocation == location,
                                onSelected: (selected) {
                                  if (selected) {
                                    _filterByLocation(location);
                                  }
                                },
                                backgroundColor: Colors.white,
                                selectedColor: Colors.amber[400],
                                checkmarkColor: Colors.indigo[900],
                                labelStyle: TextStyle(
                                  color: _selectedLocation == location
                                      ? Colors.indigo[900]
                                      : Colors.black87,
                                  fontWeight: _selectedLocation == location
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 2,
                              ),
                            );
                          }).toList()
                        : _jobStatuses.map((status) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text(status),
                                selected: _selectedJobStatus == status,
                                onSelected: (selected) {
                                  if (selected) {
                                    _filterByJobStatus(status);
                                  }
                                },
                                backgroundColor:
                                    const Color.fromARGB(255, 145, 33, 33),
                                selectedColor:
                                    const Color.fromARGB(255, 248, 194, 31),
                                checkmarkColor: Colors.indigo[900],
                                labelStyle: TextStyle(
                                  color: _selectedJobStatus == status
                                      ? Colors.indigo[900]
                                      : Colors.black87,
                                  fontWeight: _selectedJobStatus == status
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 2,
                              ),
                            );
                          }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Content area title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _userType == 'client'
                      ? 'Available Professionals'
                      : 'Job Opportunities',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lato',
                    color: Color.fromARGB(221, 51, 203, 0),
                  ),
                ),
                Text(
                  _userType == 'client'
                      ? '${_filteredWorkers.length} found'
                      : '${_filteredJobs.length} found',
                  style: TextStyle(
                    color: const Color.fromARGB(224, 208, 3, 245),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Content area (workers or jobs)
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.indigo))
                : _userType == 'client'
                    ? _buildWorkersListView()
                    : _buildJobsListView(),
          ),
        ],
      ),
      // FAB for clients to post new jobs
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _userType == 'client'
            ? _navigateToCreateJob
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfessionalSetupScreen(),
                  ),
                ),
        backgroundColor: _userType == 'client'
            ? const Color.fromARGB(255, 93, 52, 239)
            : const Color.fromARGB(255, 4, 243, 0),
        icon: const Icon(Icons.add),
        label: Text(
          _userType == 'client' ? 'Post a Job' : 'Create Profile',
          style: const TextStyle(color: Colors.white),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildWorkersListView() {
    return _filteredWorkers.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'No network connection',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(
                        255, 31, 242, 200), // Move color inside TextStyle
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Please check your internet connection and try again.',
                  style: TextStyle(
                      fontSize: 14,
                      color: const Color.fromARGB(255, 31, 242, 200),
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
              ],
            ),
          )
        : ListView.builder(
            itemCount: _filteredWorkers.length,
            itemBuilder: (context, index) {
              final worker = _filteredWorkers[index];
              return WorkerCard(worker: worker);
            },
          );
  }

  Widget _buildJobsListView() {
    return _filteredJobs.isEmpty
        ? const Center(child: Text('No jobs available'))
        : ListView.builder(
            itemCount: _filteredJobs.length,
            itemBuilder: (context, index) {
              final job = _filteredJobs[index];
              return JobCard(
                job: job,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JobDetailScreen(job: job),
                    ),
                  ).then((_) => _loadJobs()); // Refresh after viewing details
                },
              );
            },
          );
  }
}

// Worker card for client view
class WorkerCard extends StatelessWidget {
  final Worker worker;

  const WorkerCard({Key? key, required this.worker}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkerDetailScreen(worker: worker),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        worker.profileImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Worker details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and rate
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                worker.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: Colors.green, width: 1),
                              ),
                              child: Text(
                                '${worker.priceRange.round()} ETB',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Profession with icon
                        Row(
                          children: [
                            Icon(
                              _getProfessionIcon(worker.profession),
                              size: 16,
                              color: Colors.indigo[700],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                worker.profession,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.indigo[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Rating and experience
                        Wrap(
                          spacing: 8, // gap between adjacent chips
                          runSpacing: 4, // gap between lines
                          children: [
                            // Rating
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 16),
                                  const SizedBox(width: 2),
                                  Text(
                                    worker.rating.toStringAsFixed(3),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Jobs completed
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.work_outline,
                                      color: Colors.blue, size: 14),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${worker.completedJobs} jobs',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Experience
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.insights,
                                      color: Colors.purple, size: 14),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${worker.experience} yrs',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.purple[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Location
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16,
                                color: Color.fromARGB(255, 136, 105, 103)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                worker.location,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Skills section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Skills:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: worker.skills.map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.indigo[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.indigo[200]!,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          skill,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.indigo[800],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Contact button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                WorkerDetailScreen(worker: worker),
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('Contact'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.indigo[700],
                        side: BorderSide(color: Colors.indigo[700]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Book Now button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CreateJobScreen(preselectedWorkerId: worker.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text('Book Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[700],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getProfessionIcon(String profession) {
    profession = profession.toLowerCase();
    if (profession.contains('plumb')) return Icons.plumbing;
    if (profession.contains('electric')) return Icons.electrical_services;
    if (profession.contains('carpenter')) return Icons.handyman;
    if (profession.contains('paint')) return Icons.format_paint;
    if (profession.contains('clean')) return Icons.cleaning_services;
    if (profession.contains('garden')) return Icons.yard;
    if (profession.contains('cook') || profession.contains('chef'))
      return Icons.restaurant;
    if (profession.contains('teach') || profession.contains('tutor'))
      return Icons.school;
    if (profession.contains('driver')) return Icons.directions_car;
    if (profession.contains('security')) return Icons.security;
    // Default icon
    return Icons.work;
  }
}

// Job card for professional view
class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const JobCard({Key? key, required this.job, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Budget with icon
                        Row(
                          children: [
                            const Icon(Icons.monetization_on,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              '${job.budget.toStringAsFixed(0)} ETB',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(job.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _getStatusColor(job.status), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(job.status),
                          size: 14,
                          color: _getStatusColor(job.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          job.status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(job.status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.description,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Location and time details
              Row(
                children: [
                  // Location
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.location_on,
                              size: 16, color: Colors.red[700]),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Location',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                job.location,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Posted time
                  if (job.createdAt != null)
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.access_time,
                                size: 16, color: Colors.blue[700]),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Posted',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  _getTimeAgo(job.createdAt!),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    _getButtonText(job.status),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getButtonText(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Apply Now';
      case 'assigned':
        return 'View Details';
      case 'completed':
        return 'View Summary';
      default:
        return 'View Job';
    }
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
        return Icons.hourglass_top;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'just now';
    }
  }
}
