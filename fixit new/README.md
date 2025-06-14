<div align="center">
<img src="https://imgur.com/feCqGST.png" width="150" alt="Fixit Login">
🔧 Fixit - On-Demand Service Marketplace 🔧
A feature-rich, cross-platform app built with Flutter and Firebase, connecting clients with skilled professionals. Think Uber, but for home services!
</div>
<div align="center">
![alt text](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)

![alt text](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

![alt text](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)

![alt text](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)

![alt text](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)
</div>
✨ Project Showcase
Fixit is a two-sided marketplace with distinct, tailored experiences for both Clients looking for help and Professionals offering their skills.
🧑‍💼 The Client Experience
Clients can effortlessly find talent, post jobs, and manage the entire hiring process from their pocket.
Find a Pro 🔎	Hire & Manage 📝	Rate Your Pro ⭐
<img src="https://imgur.com/ej3xYq3.png" width="260">	<img src="https://imgur.com/JGHj8oS.png" width="260">	<img src="https://imgur.com/Al5E3Ac.png" width="260">
Browse a grid of top-rated professionals.	Track all your job posts from one dashboard.	Leave valuable feedback after a job is done.
🛠️ The Professional Experience
Professionals get a powerful platform to build their brand, showcase their work, and find new job opportunities.
Find Jobs 💼	Build Your Profile 👤	Manage Your Work 📋
<img src="https://imgur.com/jUzPnJ2.png" width="260">	<img src="https://imgur.com/b8OQdUF.png" width="260">	<img src="https://imgur.com/SE10n3w.png" width="260">
A live feed of open jobs posted by clients.	A detailed settings page to perfect your profile.	View completed jobs and payment history.
🚀 Core Features
The app is packed with features designed for a seamless user experience.
Feature Area	For Clients 🤝	For Professionals 🛠️
Discovery	🔍 Browse & Search Pros<br>👤 View Detailed Profiles<br>🎞️ Watch Intro Videos	💼 Browse Open Job Feed<br>🔔 Real-time Job Alerts<br>📊 Filter by Category
Hiring	📝 Post Job Requests<br>📅 Schedule Service Dates<br>🤝 Hire Professionals Directly	✅ Apply for Jobs<br>👍 Accept/Decline Offers<br>💬 (Upcoming) In-App Chat
Management	📊 Job Status Dashboard<br>💳 Secure Payment System<br>⭐️ Rate & Review System	📋 Personal Work Dashboard<br>📈 Track Active/Completed Jobs<br>💰 View Earnings History
Profile	👤 Simple Client Profile<br>✨ View Past Hires	🛠️ Multi-Step Profile Builder<br>🖼️ Rich Media Portfolio<br>可用性 Set Availability & Rates
Auth	🔑 Email, Phone, & Google Auth<br>🔒 Secure & Persistent Login	🔑 Email, Phone, & Google Auth<br>✅ Email Verification
💻 Tech Stack & Architecture
This project leverages a modern, scalable stack to deliver a robust cross-platform experience.
Component	Technology	Purpose
UI Framework	
![alt text](https://img.shields.io/badge/Flutter-blue?style=flat-square&logo=flutter)
Building beautiful, natively compiled applications for mobile & web from a single codebase.
Language	
![alt text](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart)
The language of Flutter. Optimized for client-side development.
Database	
![alt text](https://img.shields.io/badge/Firestore-FFCA28?style=flat-square&logo=firebase)
NoSQL, real-time database for storing all app data like users, jobs, and reviews.
Authentication	
![alt text](https://img.shields.io/badge/Auth-FFA611?style=flat-square&logo=firebase)
Handles all user sign-up, login, and session management.
File Storage	
![alt text](https://img.shields.io/badge/Storage-3ECF8E?style=flat-square&logo=supabase)
Stores all user-uploaded media (profile pictures, videos, gallery images).
State Mgmt	Provider / BLoC	Manages the application state efficiently.
🏛️ Simplified Architecture
graph TD
    subgraph "Flutter App (Mobile & Web)"
        A[Client UI]
        B[Professional UI]
    end

    subgraph "Backend Services"
        C[Firebase Auth]
        D[Cloud Firestore]
        E[Supabase Storage]
    end

    A --- C
    B --- C
    A --- D
    B --- D
    A --- E
    B --- E
Use code with caution.
Mermaid
<br>
<details>
<summary><b>📂 Click to view the detailed Firestore Data Schema</b></summary>
{
  "users": {
    "userId": {
      "uid": "string",
      "email": "string",
      "name": "string",
      "role": "client | professional",
      "createdAt": "timestamp"
    }
  },
  "professionals": {
    "professionalId": {
      "name": "string",
      "profession": "string",
      "about": "string",
      "experience": 4,
      "skills": ["Electrical Wiring", "Computer Repair"],
      "hourlyRate": 800,
      "rating": 4.8,
      "profileImageUrl": "supabase_url",
      "introVideoUrl": "supabase_url",
      "galleryImageUrls": ["url1", "url2"],
      "weeklyAvailability": {
        "Mon": { "start": "09:00", "end": "17:00", "isActive": true }
      }
    }
  },
  "jobs": {
    "jobId": {
      "title": "Fix my house electric",
      "description": "I need you today...",
      "budget": 800,
      "location": "addis abeba bole",
      "clientId": "client_uid",
      "professionalId": "professional_uid",
      "status": "accepted",
      "createdAt": "timestamp",
      "scheduledFor": "timestamp"
    }
  },
  "reviews": {
    "reviewId": {
      "professionalId": "prof_uid",
      "clientId": "client_uid",
      "rating": 5,
      "comment": "This man is gud",
      "createdAt": "timestamp"
    }
  }
}
Use code with caution.
Json
</details>
🚀 Getting Started
Ready to run the project? Follow these steps.
Clone the Repository
git clone https://github.com/your-username/fixit-project.git
cd fixit-project
Use code with caution.
Bash
Set Up Firebase & Supabase
You'll need to create your own Firebase project and a Supabase project.
In Firebase, enable Authentication (Email/Password & Phone) and Firestore.
In Supabase, set up a Storage bucket for your media.
Place your google-services.json (Android) and GoogleService-Info.plist (iOS) files in the correct directories.
Create a .env file in the root and add your API keys.
Install Dependencies
flutter pub get
Use code with caution.
Bash
Run the App!
flutter run
Use code with caution.
Bash
🗺️ Future Roadmap
In-App Chat: Real-time messaging between clients and professionals.
Map Integration: A map view to visualize job and professional locations.
Real Payment Gateway: Integrate a full payment API like Stripe or a local alternative.
Advanced Search Filters: Allow users to filter by price range, distance, and more.
Admin Dashboard: A web-based panel for managing the platform.
❤️ Contributing
Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are greatly appreciated.
Fork the Project
Create your Feature Branch (git checkout -b feature/AmazingFeature)
Commit your Changes (git commit -m 'Add some AmazingFeature')
Push to the Branch (git push origin feature/AmazingFeature)
Open a Pull Request
<div align="center">
Made with ❤️ and Flutter
</div>
