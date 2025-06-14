Fixit - On-Demand Service Marketplace
Fixit is a cross-platform mobile and web application, built with Flutter and Firebase, that connects clients with skilled professionals for a variety of on-demand services. It serves as a comprehensive two-sided marketplace, facilitating everything from job discovery and hiring to secure payments and user reviews.
The platform is designed with two primary user roles:
Clients: Individuals or businesses looking to hire professionals for specific tasks.
Professionals (Workers): Skilled individuals offering their services to clients.
Demo & Screenshots
Core User Journey
<img src="https://imgur.com/feCqGST.png" width="250"> <img src="https://imgur.com/S6Kd2oL.png" width="250"> <img src="https://imgur.com/Al5E3Ac.png" width="250">
Login Screen, Client Profile View, and Rating System.
Client Experience
A client can browse professionals, post jobs, manage their requests, and make payments.
<img src="https://imgur.com/ej3xYq3.png" width="410"> <img src="https://imgur.com/nXJjKpg.png" width="410">
Left: Client's Home Page with a grid of available professionals. Right: Detailed Worker Profile view for clients.
<img src="https://imgur.com/JGHj8oS.png" width="410"> <img src="https://imgur.com/SE10n3w.png" width="410">
Left: Client's Job Dashboard to track posted jobs. Right: View of a completed job.
Professional (Worker) Experience
A professional can create a detailed profile, showcase their work, find and apply for jobs, and manage their assignments.
<img src="https://imgur.com/jUzPnJ2.png" width="410"> <img src="https://imgur.com/b8OQdUF.png" width="410">
Left: Professional's Home Screen with a feed of open jobs. Right: Profile Settings and management page.
Key Features
For Clients
🔍 Browse & Search: Discover professionals by skill, name, or keywords.
👤 View Professional Profiles: Access detailed profiles including experience, bio, skills, work gallery (images/videos), and ratings.
📝 Post Jobs: Easily create and post job requests with descriptions, budget, location, and media attachments.
🤝 Hire Directly: Select and hire a professional for a specific job.
📊 Job Management Dashboard: Track the status of all posted jobs (Pending, In Progress, Completed).
💳 Secure Payments: Integrated payment system supporting methods like Telebirr and CBE Birr.
⭐ Rate & Review: Provide feedback and a star rating for professionals after a job is completed.
For Professionals
🛠️ Multi-Step Profile Creation: A guided wizard to build a complete and trustworthy profile.
🖼️ Rich Portfolio: Showcase expertise by uploading a profile photo, introductory video, work gallery images, and certification documents.
💰 Set Rates & Availability: Define a base hourly rate and set weekly work availability.
💼 Find Jobs: Browse a real-time feed of open jobs posted by clients.
✅ Apply & Manage Jobs: Apply for jobs, accept or decline offers, and track job progress from "Assigned" to "Completed".
🔔 Real-time Notifications: Receive updates on new job opportunities, applications, and job status changes.
Common Features
🔑 Secure Authentication: Robust user authentication using Email/Password and Phone verification via Firebase.
🎨 Dual Theme: Seamlessly switch between Light and Dark modes.
📱 Cross-Platform: A single codebase for Android, iOS, and Web, ensuring a consistent user experience.
Technology Stack
Frontend: Flutter
Programming Language: Dart
Backend: Firebase
Authentication: Firebase Authentication
Database: Cloud Firestore
Storage: Supabase Storage (for user-uploaded media like images and videos)
State Management: Provider / BLoC
Payment Integration: Telebirr, CBE Birr (manual proof upload)
Getting Started
To get a local copy up and running, follow these simple steps.
Prerequisites
Flutter SDK
An IDE such as Android Studio or VS Code
Installation
Set up Firebase:
Create a new project on the Firebase Console.
Set up Firestore Database and Firebase Authentication (enable Email/Password and Phone Sign-in).
Register your Android, iOS, and Web apps in the Firebase project settings.
Download the google-services.json file and place it in the android/app directory.
Download the GoogleService-Info.plist file and place it in the ios/Runner directory using Xcode.
Add your Firebase web configuration to a .env file or directly in your main.dart.
Clone the repo:
git clone https://github.com/your_username/fixit-project.git
Use code with caution.
Sh
Install packages:
flutter pub get
Use code with caution.
Sh
Run the app:
flutter run
