import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/firebase_service.dart';

class ProfessionalSetupScreen extends StatefulWidget {
  const ProfessionalSetupScreen({Key? key}) : super(key: key);

  @override
  _ProfessionalSetupScreenState createState() => _ProfessionalSetupScreenState();
}

class _ProfessionalSetupScreenState extends State<ProfessionalSetupScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Form controllers
  final _professionController = TextEditingController();
  final _experienceController = TextEditingController();
  final _priceRangeController = TextEditingController();
  final _aboutController = TextEditingController();
  
  // Selected values
  String _selectedLocation = 'Addis Ababa';
  final List<String> _locations = ['Adama', 'Addis Ababa', 'Bahir Dar', 'Hawassa', 'Mekelle'];
  
  // Skills
  final List<String> _availableSkills = [
    'Plumbing', 'Electrical', 'Carpentry', 'Painting', 'Masonry', 
    'Tiling', 'Roofing', 'HVAC', 'Appliance Repair', 'Cleaning',
    'Landscaping', 'Welding', 'Flooring', 'Drywall', 'Moving'
  ];
  final List<String> _selectedSkills = [];
  
  // Profile image
  File? _profileImage;
  
  @override
  void dispose() {
    _professionController.dispose();
    _experienceController.dispose();
    _priceRangeController.dispose();
    _aboutController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }
  
  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
  }
  
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSkills.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one skill')),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Upload profile image if selected
        String? profileImageUrl;
        if (_profileImage != null) {
          profileImageUrl = await _firebaseService.uploadProfileImage(_profileImage!);
        }
        
        // Save professional profile data
        await _firebaseService.updateUserProfile({
          'profession': _professionController.text,
          'experience': int.parse(_experienceController.text),
          'priceRange': double.parse(_priceRangeController.text),
          'location': _selectedLocation,
          'skills': _selectedSkills,
          'about': _aboutController.text,
          'profileImage': profileImageUrl,
          'profileComplete': true,
          'rating': 0.0,
          'reviewCount': 0,
          'completedJobs': 0,
        });
        
        // Create worker document
        await _firebaseService.createWorkerProfile(
          profession: _professionController.text,
          experience: int.parse(_experienceController.text),
          priceRange: double.parse(_priceRangeController.text),
          location: _selectedLocation,
          skills: _selectedSkills,
          about: _aboutController.text,
          profileImage: profileImageUrl,
        );
        
        if (!mounted) return;
        
        // Show success message and navigate to home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile setup complete!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
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
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: _profileImage != null 
                                  ? FileImage(_profileImage!) 
                                  : null,
                              child: _profileImage == null
                                  ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _pickImage,
                            child: const Text('Add Profile Picture'),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Text(
                      'Professional Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Profession field
                    TextFormField(
                      controller: _professionController,
                      decoration: const InputDecoration(
                        labelText: 'Profession',
                        hintText: 'e.g. Plumber, Electrician, Carpenter',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your profession';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Experience field
                    TextFormField(
                      controller: _experienceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Years of Experience',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your years of experience';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Price range field
                    TextFormField(
                      controller: _priceRangeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Hourly Rate (ETB)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your hourly rate';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid rate';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Location dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedLocation,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                      items: _locations.map((location) {
                        return DropdownMenuItem(
                          value: location,
                          child: Text(location),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLocation = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Skills selection
                    const Text(
                      'Select Your Skills',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableSkills.map((skill) {
                        final isSelected = _selectedSkills.contains(skill);
                        return FilterChip(
                          label: Text(skill),
                          selected: isSelected,
                          onSelected: (_) => _toggleSkill(skill),
                          backgroundColor: Colors.grey[200],
                          selectedColor: Colors.blue.withOpacity(0.3),
                          checkmarkColor: Colors.blue,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    
                    // About field
                    TextFormField(
                      controller: _aboutController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'About Yourself',
                        hintText: 'Tell clients about your experience, qualifications, and expertise',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter information about yourself';
                        }
                        if (value.length < 50) {
                          return 'Please enter at least 50 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Complete Profile',
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
