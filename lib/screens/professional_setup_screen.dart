import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore still the GOAT
import '../services/firebase_service.dart';

// Yo, this is the futuristic pro setup screen, next-level vibes
class ProfessionalSetupScreen extends StatefulWidget {
  const ProfessionalSetupScreen({Key? key}) : super(key: key);

  @override
  _ProfessionalSetupScreenState createState() =>
      _ProfessionalSetupScreenState();
}

class _ProfessionalSetupScreenState extends State<ProfessionalSetupScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  // Profile pic stuff, futuristic twist
  File? _profileImage;
  String? _uploadedImageUrl;

  // Form fields, cyberpunk style
  String? _profession;
  final _experienceController = TextEditingController();
  final _priceRangeController = TextEditingController();
  final _locationController = TextEditingController();
  final _aboutController = TextEditingController();

  // Skills, neon glowin’
  final List<String> _selectedSkills = [];
  final _skillController = TextEditingController();
  final List<String> _commonSkills = [
    'Plumbing',
    'Electrical',
    'Carpentry',
    'Painting',
    'Cleaning',
    'Gardening',
    'Moving',
    'Assembly',
    'Repair',
    'Installation',
    'Cooking',
    'Tutoring',
    'Design',
    'Programming',
    'Writing',
  ];

  @override
  void initState() {
    super.initState();
    // Animation setup for that sci-fi entrance
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadUserProfile(); // Load it up with swagger
  }

  @override
  void dispose() {
    _animationController.dispose();
    _experienceController.dispose();
    _priceRangeController.dispose();
    _locationController.dispose();
    _aboutController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  // Fetch profile from Firebase, keep it slick
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final userProfile = await _firebaseService.getCurrentUserProfile();
      if (userProfile != null && userProfile.role == 'worker') {
        final workerDoc = await FirebaseFirestore.instance
            .collection('professionals')
            .doc(userProfile.id)
            .get();

        if (workerDoc.exists) {
          final workerData = workerDoc.data() as Map<String, dynamic>;
          setState(() {
            _profession = workerData['profession'];
            _experienceController.text =
                workerData['experience']?.toString() ?? '';
            _priceRangeController.text =
                workerData['priceRange']?.toString() ?? '';
            _locationController.text = workerData['location'] ?? '';
            _aboutController.text = workerData['about'] ?? '';
            _selectedSkills.addAll(
                (workerData['skills'] as List<dynamic>?)?.cast<String>() ?? []);
            _uploadedImageUrl = workerData['profileImage'];
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yo, profile load glitch: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Pick an image, cyber-style
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  // Add skill with neon flair
  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_selectedSkills.contains(skill)) {
      setState(() {
        _selectedSkills.add(skill);
        _skillController.clear();
      });
    }
  }

  // Remove skill, smooth exit
  void _removeSkill(String skill) {
    setState(() => _selectedSkills.remove(skill));
  }

  // Save profile, futuristic lock-in
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_selectedSkills.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yo, drop at least one skill!')),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        if (_profileImage != null) {
          _uploadedImageUrl =
              await _firebaseService.uploadProfileImage(_profileImage!);
        }

        await _firebaseService.createWorkerProfile(
          profession: _profession!,
          experience: int.parse(_experienceController.text),
          priceRange: double.parse(_priceRangeController.text),
          location: _locationController.text,
          skills: _selectedSkills,
          about: _aboutController.text,
          profileImage: _uploadedImageUrl,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile synced, you’re live!')),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed, my bad: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF00FFD1), // Neon cyan for that future pop
        scaffoldBackgroundColor: const Color(0xFF0A0A0A), // Deep void bg
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF00FFD1),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1A1A).withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF00FFD1), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF00FFD1), width: 2),
          ),
          hintStyle:
              const TextStyle(color: Colors.grey, fontFamily: 'Orbitron'),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontFamily: 'Orbitron'),
          bodyMedium: TextStyle(color: Colors.white70, fontFamily: 'Orbitron'),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26,
            fontFamily: 'Orbitron',
          ),
        ),
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Craft Your Cyber Profile'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          titleTextStyle: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 22,
            color: Color(0xFF00FFD1),
            shadows: [Shadow(color: Color(0xFF00FFD1), blurRadius: 10)],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                const Color(0xFF0A0A0A),
                const Color(0xFF1A1A1A).withOpacity(0.9)
              ],
            ),
          ),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00FFD1),
                    strokeWidth: 4,
                    backgroundColor: Colors.white12,
                  ),
                )
              : SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile image, holographic vibes
                            Center(
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: const Color(0xFF00FFD1),
                                            width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF00FFD1)
                                                .withOpacity(0.4),
                                            blurRadius: 15,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 80,
                                        backgroundColor:
                                            const Color(0xFF1A1A1A),
                                        backgroundImage: _profileImage != null
                                            ? FileImage(_profileImage!)
                                            : _uploadedImageUrl != null
                                                ? NetworkImage(
                                                    _uploadedImageUrl!)
                                                : null,
                                        child: _profileImage == null &&
                                                _uploadedImageUrl == null
                                            ? const Icon(Icons.person,
                                                size: 80, color: Colors.grey)
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Upload your hologram',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontFamily: 'Orbitron'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Profession, neon dropdown
                            _buildCyberTitle('Profession'),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _profession,
                              decoration: const InputDecoration(
                                  hintText: 'Your cyber-craft'),
                              dropdownColor: const Color(0xFF1A1A1A),
                              items: [
                                'Plumber',
                                'Electrician',
                                'Carpenter',
                                'Painter',
                                'Cleaner',
                                'Gardener',
                                'Chef',
                                'Tutor',
                                'Software Developer',
                                'Designer',
                                'Writer',
                                'Translator',
                                'Driver',
                                'Other',
                              ].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value,
                                      style:
                                          const TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Choose your craft, yo!'
                                      : null,
                              onChanged: (value) =>
                                  setState(() => _profession = value),
                            ),
                            const SizedBox(height: 24),

                            // Experience, glowing input
                            _buildCyberTitle('Experience'),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _experienceController,
                              decoration: const InputDecoration(
                                  hintText: 'Years in the grid'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Input your XP!';
                                if (int.tryParse(value) == null)
                                  return 'Numbers only, fam!';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Price range, neon money
                            _buildCyberTitle('Rate (ETB/hr)'),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _priceRangeController,
                              decoration: const InputDecoration(
                                  hintText: 'Your digital credits'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Set your rate!';
                                if (double.tryParse(value) == null)
                                  return 'Real digits, yo!';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Location, cyber coordinates
                            _buildCyberTitle('Location'),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                  hintText: 'Your sector'),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Drop your coords!'
                                      : null,
                            ),
                            const SizedBox(height: 24),

                            // Skills, holographic chips
                            _buildCyberTitle('Skills'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _skillController,
                                    decoration: const InputDecoration(
                                        hintText: 'Add a power-up'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _addSkill,
                                  child: const Text('Sync',
                                      style: TextStyle(color: Colors.black)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00FFD1)
                                        .withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Skill Matrix:',
                              style: TextStyle(
                                  color: Colors.grey, fontFamily: 'Orbitron'),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              children: _commonSkills
                                  .where((skill) =>
                                      !_selectedSkills.contains(skill))
                                  .take(6)
                                  .map((skill) => ActionChip(
                                        label: Text(skill),
                                        backgroundColor:
                                            const Color(0xFF1A1A1A),
                                        labelStyle: const TextStyle(
                                            color: Color(0xFF00FFD1)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          side: const BorderSide(
                                              color: Color(0xFF00FFD1),
                                              width: 1),
                                        ),
                                        onPressed: () => setState(
                                            () => _selectedSkills.add(skill)),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 20),
                            if (_selectedSkills.isNotEmpty) ...[
                              const Text(
                                'Active Skills:',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Orbitron'),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                children: _selectedSkills
                                    .map((skill) => Chip(
                                          label: Text(skill),
                                          deleteIcon:
                                              const Icon(Icons.close, size: 18),
                                          onDeleted: () => _removeSkill(skill),
                                          backgroundColor:
                                              const Color(0xFF00FFD1)
                                                  .withOpacity(0.2),
                                          labelStyle: const TextStyle(
                                              color: Colors.white),
                                          deleteIconColor:
                                              const Color(0xFF00FFD1),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                          elevation: 2,
                                          shadowColor: const Color(0xFF00FFD1),
                                        ))
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 24),

                            // About, cyber bio
                            _buildCyberTitle('Bio'),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _aboutController,
                              decoration: const InputDecoration(
                                  hintText: 'Your digital legend'),
                              maxLines: 6,
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Write your code!';
                                if (value.length < 20)
                                  return '20 chars min, level up!';
                                return null;
                              },
                            ),
                            const SizedBox(height: 40),

                            // Save button, neon pulse
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF00FFD1),
                                        const Color(0xFF00FFD1)
                                            .withOpacity(0.6),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00FFD1)
                                            .withOpacity(0.5),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  child: const Center(
                                    child: Text(
                                      'Upload to the Grid',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontFamily: 'Orbitron',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // Cyber title with neon glow
  Widget _buildCyberTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'Orbitron',
        shadows: [
          Shadow(color: Color(0xFF00FFD1), blurRadius: 8),
        ],
      ),
    );
  }
}
