import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../models/worker.dart';
import '../../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

// Yo, let’s define a custom green theme for the whole screen
const Color kPrimaryGreen = Color(0xFF2E7D32); // Deep forest green
const Color kAccentGreen = Color(0xFF66BB6A); // Fresh lime green
const Color kLightGreen = Color(0xFFE8F5E9); // Soft green background

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

  // Controllers for the form fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();

  // Extra state for cool features
  DateTime? _selectedDate;
  DateTime _focusedDay = DateTime.now();
  List<File> _attachments = [];
  bool _isUrgent = false; // New feature: mark job as urgent

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

  // Load preselected worker if passed in
  Future<void> _loadPreselectedWorker() async {
    if (widget.preselectedWorkerId != null) {
      setState(() => _isLoading = true);
      try {
        final worker =
            await _firebaseService.getWorkerById(widget.preselectedWorkerId!);
        setState(() {
          _selectedWorker = worker;
          if (worker != null) _locationController.text = worker.location;
        });
      } catch (e) {
        print('Error loading worker: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Upload attachments to Firebase Storage with a clean vibe
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
        final ref = storage.ref().child('job_attachments/$fileName');
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        downloadUrls.add(url);
      }
    } catch (e) {
      print('Error uploading attachments: $e');
      rethrow;
    }
    return downloadUrls;
  }

  // Create the job with all the dope details
  Future<void> _createJob() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        List<String> attachmentUrls =
            _attachments.isNotEmpty ? await _uploadAttachments() : [];
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
          'isUrgent': _isUrgent, // New feature: urgent flag
        };

        if (_selectedWorker != null)
          jobData['applications'] = [_selectedWorker!.id];
        await _firebaseService.createJob(jobData);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Job posted successfully!'),
            backgroundColor: kAccentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Pick files with a smooth flow
  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf'],
      );
      if (result != null) {
        setState(() =>
            _attachments = result.paths.map((path) => File(path!)).toList());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error picking files: $e'),
            backgroundColor: Colors.redAccent),
      );
    }
  }

  // Pop up that slick calendar
  void _showCalendarDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kLightGreen,
        title:
            const Text('Pick a Date', style: TextStyle(color: kPrimaryGreen)),
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
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(
                  color: kPrimaryGreen, fontWeight: FontWeight.bold),
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                  color: kAccentGreen, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(
                  color: kPrimaryGreen.withOpacity(0.5),
                  shape: BoxShape.circle),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: kPrimaryGreen)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightGreen, // Light green backdrop
      appBar: AppBar(
        title: const Text('Post a Job'),
        backgroundColor: kPrimaryGreen,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kAccentGreen))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected worker card with green accents
                    if (_selectedWorker != null)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage:
                                    NetworkImage(_selectedWorker!.profileImage),
                                onBackgroundImageError: (_, __) {},
                                child: _selectedWorker!.profileImage.isEmpty
                                    ? const Icon(Icons.person,
                                        color: kPrimaryGreen)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedWorker!.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryGreen,
                                      ),
                                    ),
                                    Text(_selectedWorker!.profession,
                                        style: const TextStyle(
                                            color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Text(
                                '${_selectedWorker!.priceRange.toInt()} ETB/hr',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: kAccentGreen),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Job Title field with green borders
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Job Title',
                        hintText: 'e.g. Fix Leaking Sink',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: kAccentGreen, width: 2),
                        ),
                        labelStyle: const TextStyle(color: kPrimaryGreen),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Gimme a job title, fam!'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Description field with some green flair
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Job Description',
                        hintText: 'Tell us the deets...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: kAccentGreen, width: 2),
                        ),
                        labelStyle: const TextStyle(color: kPrimaryGreen),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Don’t leave this blank, yo!';
                        if (value.length < 30)
                          return 'Make it juicy, at least 30 chars!';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Budget field with a green money vibe
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Budget (ETB)',
                        hintText: 'How much you droppin’?',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: kAccentGreen, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.attach_money,
                            color: kPrimaryGreen),
                        labelStyle: const TextStyle(color: kPrimaryGreen),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Gotta set a budget, homie!';
                        if (double.tryParse(value) == null)
                          return 'Numbers only, fam!';
                        if (double.parse(value) <= 0)
                          return 'Can’t be zero or less, yo!';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Location field with green pin
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        hintText: 'Where’s this goin’ down?',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: kAccentGreen, width: 2),
                        ),
                        prefixIcon:
                            const Icon(Icons.location_on, color: kPrimaryGreen),
                        labelStyle: const TextStyle(color: kPrimaryGreen),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Where’s the spot, fam?'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Additional Details header
                    const Text(
                      'Extra Vibes',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryGreen),
                    ),
                    const SizedBox(height: 16),

                    // Calendar picker tile
                    ListTile(
                      title: Text(
                        _selectedDate == null
                            ? 'When’s it happenin’?'
                            : 'Set for: ${_selectedDate!.toString().split(' ')[0]}',
                        style: const TextStyle(color: kPrimaryGreen),
                      ),
                      subtitle: const Text('Tap to pick a date'),
                      leading: const Icon(Icons.calendar_today,
                          color: kPrimaryGreen),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 16, color: kPrimaryGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: kPrimaryGreen),
                      ),
                      tileColor: Colors.white,
                      onTap: _showCalendarDialog,
                    ),
                    const SizedBox(height: 12),

                    // File picker tile
                    ListTile(
                      title: const Text('Add Pics or Docs',
                          style: TextStyle(color: kPrimaryGreen)),
                      subtitle: Text(
                        _attachments.isEmpty
                            ? 'Upload some goodies'
                            : '${_attachments.length} files ready',
                      ),
                      leading:
                          const Icon(Icons.attach_file, color: kPrimaryGreen),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 16, color: kPrimaryGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: kPrimaryGreen),
                      ),
                      tileColor: Colors.white,
                      onTap: _pickFiles,
                    ),

                    // Show selected attachments with a green twist
                    if (_attachments.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _attachments
                            .map((file) => Chip(
                                  label: Text(file.path.split('/').last),
                                  backgroundColor:
                                      kAccentGreen.withOpacity(0.2),
                                  deleteIconColor: kPrimaryGreen,
                                  onDeleted: () =>
                                      setState(() => _attachments.remove(file)),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // New feature: Urgent job toggle
                    SwitchListTile(
                      title: const Text('Urgent Job?',
                          style: TextStyle(color: kPrimaryGreen)),
                      subtitle: const Text('Need it done ASAP?'),
                      value: _isUrgent,
                      activeColor: kAccentGreen,
                      onChanged: (value) => setState(() => _isUrgent = value),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: kPrimaryGreen),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Post button with that green pop
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createJob,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccentGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                        ),
                        child: const Text('Post That Job!',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
