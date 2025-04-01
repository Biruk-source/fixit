import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this for direct Firestore access
import '../services/firebase_service.dart';

class ProfessionalSetupScreen extends StatefulWidget {
  const ProfessionalSetupScreen({Key? key}) : super(key: key);

  @override
  _ProfessionalSetupScreenState createState() =>
      _ProfessionalSetupScreenState();
}

class _ProfessionalSetupScreenState extends State<ProfessionalSetupScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Profile image
  File? _profileImage;
  String? _uploadedImageUrl;

  // Form fields
  String? _profession;
  final _experienceController = TextEditingController();
  final _priceRangeController = TextEditingController();
  final _locationController = TextEditingController();
  final _aboutController = TextEditingController();

  // Skills
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
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProfile = await _firebaseService.getCurrentUserProfile();
      if (userProfile != null && userProfile.role == 'worker') {
        // Fetch worker-specific data from 'professionals' collection
        final workerDoc = await FirebaseFirestore.instance
            .collection('professionals')
            .doc(userProfile.id)
            .get();

        if (workerDoc.exists) {
          final workerData = workerDoc.data() as Map<String, dynamic>;
          setState(() {
            _profession = workerData['profession'] as String?;
            if (workerData['experience'] != null) {
              _experienceController.text = workerData['experience'].toString();
            }
            if (workerData['priceRange'] != null) {
              _priceRangeController.text = workerData['priceRange'].toString();
            }
            if (workerData['location'] != null) {
              _locationController.text = workerData['location'] as String;
            }
            if (workerData['about'] != null) {
              _aboutController.text = workerData['about'] as String;
            }
            if (workerData['skills'] != null) {
              _selectedSkills.addAll(
                  (workerData['skills'] as List<dynamic>).cast<String>());
            }
            if (workerData['profileImage'] != null) {
              _uploadedImageUrl = workerData['profileImage'] as String;
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_selectedSkills.contains(skill)) {
      setState(() {
        _selectedSkills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _selectedSkills.remove(skill);
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedSkills.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one skill')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Upload image if new one was selected
        if (_profileImage != null) {
          _uploadedImageUrl =
              await _firebaseService.uploadProfileImage(_profileImage!);
        }

        // Save profile using FirebaseService
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
          const SnackBar(content: Text('Profile saved successfully!')),
        );

        // Return to previous screen
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile image
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: _profileImage != null
                                      ? FileImage(_profileImage!)
                                      : _uploadedImageUrl != null
                                          ? NetworkImage(_uploadedImageUrl!)
                                          : null,
                                  child: _profileImage == null &&
                                          _uploadedImageUrl == null
                                      ? const Icon(Icons.person,
                                          size: 60, color: Colors.grey)
                                      : null,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap to change profile image',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Profession dropdown
                    const Text(
                      'Profession',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _profession,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      hint: const Text('Select your profession'),
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
                          child: Text(value),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your profession';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _profession = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Experience
                    const Text(
                      'Years of Experience',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _experienceController,
                      decoration: InputDecoration(
                        hintText: 'Enter your years of experience',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your experience';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price Range
                    const Text(
                      'Price Range (ETB/hr)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _priceRangeController,
                      decoration: InputDecoration(
                        hintText: 'Enter your hourly rate',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your price range';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Location
                    const Text(
                      'Location',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'Enter your location (city)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Skills
                    const Text(
                      'Skills',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _skillController,
                            decoration: InputDecoration(
                              hintText: 'Add your skills',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addSkill,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Common skills suggestions
                    const Text(
                      'Common Skills:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Wrap(
                      spacing: 8,
                      children: _commonSkills
                          .where((skill) => !_selectedSkills.contains(skill))
                          .take(6)
                          .map((skill) => ActionChip(
                                label: Text(skill),
                                backgroundColor: Colors.grey[200],
                                onPressed: () {
                                  setState(() {
                                    _selectedSkills.add(skill);
                                  });
                                },
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),

                    // Selected skills
                    if (_selectedSkills.isNotEmpty) ...[
                      const Text(
                        'Your Skills:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _selectedSkills
                            .map((skill) => Chip(
                                  label: Text(skill),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () => _removeSkill(skill),
                                  backgroundColor: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1),
                                  deleteIconColor:
                                      Theme.of(context).primaryColor,
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // About
                    const Text(
                      'About',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _aboutController,
                      decoration: InputDecoration(
                        hintText:
                            'Tell clients about yourself and your services',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please provide some information about yourself';
                        }
                        if (value.length < 20) {
                          return 'Please provide a more detailed description (min 20 characters)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Profile',
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
