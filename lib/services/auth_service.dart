import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if user is logged in
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Trim inputs to avoid whitespace issues
      email = email.trim();
      password = password.trim();
      
      print('Attempting to sign in with email: $email');
      
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('Successfully signed in user: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      // Trim inputs to avoid whitespace issues
      email = email.trim();
      password = password.trim();
      
      print('Attempting to create user with email: $email');
      
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('Successfully created user: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  // Create user profile in Firestore
  Future<void> createUserProfile({
    required String name,
    required String email,
    required String phone,
    required String userType,
    String? profession,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found for profile creation');
        throw Exception('User not authenticated');
      }

      final userData = {
        'name': name.trim(),
        'email': email.trim(),
        'phoneNumber': phone.trim(),
        'userType': userType,
        'role': userType == 'client' ? 'client' : 'worker',
        'location': '',
        'favoriteWorkers': [],
        'postedJobs': [],
        'appliedJobs': [],
        'createdAt': FieldValue.serverTimestamp(),
      };

      String collectionName = userType == 'client' ? 'clients' : 'professionals';
      
      print('Creating profile in $collectionName collection for user: ${user.uid}');
      await _firestore.collection(collectionName).doc(user.uid).set(userData);
      
      // Also create entry in workers collection if professional
      if (userType != 'client' && profession != null && profession.isNotEmpty) {
        await _firestore.collection('workers').doc(user.uid).set({
          'id': user.uid,
          'name': name.trim(),
          'profession': profession.trim(),
          'skills': [],
          'location': '',
          'experience': 0,
          'priceRange': 0.0,
          'rating': 0.0,
          'completedJobs': 0,
          'phoneNumber': phone.trim(),
          'email': email.trim(),
          'profileImage': '',
        });
      }
      
      print('Successfully created user profile');
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  // Get current user profile
  Future<AppUser?> getCurrentUserProfile() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found for profile retrieval');
        return null;
      }
      
      print('Attempting to retrieve profile for user: ${user.uid}');
      
      // Check in professionals collection first
      final professionalDoc = await _firestore.collection('professionals').doc(user.uid).get();
      if (professionalDoc.exists && professionalDoc.data() != null) {
        final data = professionalDoc.data()!;
        data['id'] = user.uid; // Ensure ID is set
        print('Found professional profile for ${user.uid}');
        return AppUser.fromJson(data);
      }
      
      // Then check in clients collection
      final clientDoc = await _firestore.collection('clients').doc(user.uid).get();
      if (clientDoc.exists && clientDoc.data() != null) {
        final data = clientDoc.data()!;
        data['id'] = user.uid; // Ensure ID is set
        print('Found client profile for ${user.uid}');
        return AppUser.fromJson(data);
      }
      
      // If no profile found, return null
      print('No profile found for user ${user.uid}');
      return null;
    } catch (e) {
      print('Error retrieving user profile: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('User signed out');
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
}
