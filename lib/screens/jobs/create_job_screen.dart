import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../models/worker.dart';
import '../../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class CreateJobScreen extends StatefulWidget {
  final String? preselectedWorkerId;

  const CreateJobScreen({Key? key, this.preselectedWorkerId}) : super(key: key);

  @override
  _CreateJobScreenState createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  Worker? _selectedWorker;

  // Form controllers
  final _titleController = TextEditingController();

  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();

  // New state variables
  DateTime? _selectedDate;
  DateTime _focusedDay = DateTime.now();
  List<File> _attachments = [];

  @override
  void initState() {
    super.initState();
    _loadPreselectedWorker();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadPreselectedWorker() async {
    if (widget.preselectedWorkerId != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final worker =
            await _firebaseService.getWorkerById(widget.preselectedWorkerId!);
        setState(() {
          _selectedWorker = worker;
          if (worker != null) {
            _locationController.text = worker.location;
          }
        });
      } catch (e) {
        print('Error loading worker: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<String>> _uploadAttachments() async {
    final firebase_storage.FirebaseStorage storage =
        firebase_storage.FirebaseStorage.instance;
    List<String> downloadUrls = [];
    try {
      final user = _firebaseService.getCurrentUser();
      if (user == null) throw 'User not logged in';

      for (var file in _attachments) {
        final fileName =
            '${user.uid}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      }
    } catch (e) {
      print('Error uploading attachments: $e');
      rethrow;
    }
    return downloadUrls;
  }

  Future<void> _createJob() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Upload attachments if any
        List<String> attachmentUrls = [];
        if (_attachments.isNotEmpty) {
          attachmentUrls = await _uploadAttachments();
        }

        final jobData = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'budget': double.parse(_budgetController.text),
          'location': _locationController.text,
          'status': 'open',
          'createdAt': FieldValue.serverTimestamp(),
          'scheduledDate':
              _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
          'attachments': attachmentUrls,
        };

        if (_selectedWorker != null) {
          jobData['applications'] = [_selectedWorker!.id];
        }

        final jobId = await _firebaseService.createJob(jobData);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.preselectedWorkerId != null) {
          Navigator.pop(context);
        }
        Navigator.pop(context);
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
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf'],
      );

      if (result != null) {
        setState(() {
          _attachments = result.paths.map((path) => File(path!)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error picking files: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _showCalendarDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Date'),
        content: SizedBox(
          width: double.maxFinite,
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
                _focusedDay = focusedDay;
              });
              Navigator.pop(context);
            },
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Job'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedWorker != null)
                      Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selected Professional',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage: NetworkImage(
                                        _selectedWorker!.profileImage),
                                    onBackgroundImageError: (_, __) {},
                                    child: _selectedWorker!.profileImage.isEmpty
                                        ? const Icon(Icons.person, size: 20)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedWorker!.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(_selectedWorker!.profession),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${_selectedWorker!.priceRange.toInt()} ETB/hr',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Job Title',
                        hintText:
                            'e.g. Fix Leaking Sink, Install Air Conditioner',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a job title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Job Description',
                        hintText: 'Describe the job in detail...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a job description';
                        }
                        if (value.length < 30) {
                          return 'Description should be at least 30 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Budget (ETB)',
                        hintText: 'Your budget for this job',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your budget';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Budget must be greater than zero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'Where is the job located?',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the job location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Additional Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(_selectedDate == null
                          ? 'When do you need this done?'
                          : 'Scheduled for: ${_selectedDate!.toString().split(' ')[0]}'),
                      subtitle: const Text('Select date'),
                      leading: const Icon(Icons.calendar_today),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      onTap: _showCalendarDialog,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('Add photos or attachments'),
                      subtitle: Text(_attachments.isEmpty
                          ? 'Upload images or documents'
                          : '${_attachments.length} files selected'),
                      leading: const Icon(Icons.attach_file),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      onTap: _pickFiles,
                    ),
                    if (_attachments.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _attachments
                            .map((file) => Chip(
                                  label: Text(file.path.split('/').last),
                                  onDeleted: () {
                                    setState(() {
                                      _attachments.remove(file);
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createJob,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Post Job',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
