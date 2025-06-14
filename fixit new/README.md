#
# PROJECT: Fixit - On-Demand Service Marketplace (Mobile & Web)
# VERSION: 1.0.0 (Alpha)
# PLATFORMS: Android, iOS, Web
# STACK: Flutter, Dart, Firebase, Supabase
#
######################################################################################

#
# ======= TABLE OF CONTENTS =======
#
# 1.  PROJECT OVERVIEW
# 2.  CORE CONCEPTS
# 3.  TECHNOLOGY STACK
# 4.  FEATURE DEEP DIVE
# 5.  BACKEND SCHEMA (FIRESTORE & SUPABASE)
# 6.  SCREEN & COMPONENT BREAKDOWN
# 7.  KEY USER WORKFLOWS
# 8.  SETUP AND INSTALLATION
# 9.  TODO & FUTURE ENHANCEMENTS
#
######################################################################################

#
# ======= 1. PROJECT OVERVIEW =======
#
# Fixit is a full-stack, two-sided marketplace application. It connects two primary user types:
# - CLIENTS: Users who need a service performed.
# - PROFESSIONALS (WORKERS): Users who provide skilled services.
# The application facilitates the entire lifecycle of a service job, from initial posting
# and discovery to hiring, communication, payment, and final review.
#

#
# ======= 2. CORE CONCEPTS =======
#
# - User Roles: The entire application logic branches based on the user's role,
#   which is determined at sign-up.
#   - `role: 'client'` -> Can post jobs, browse workers, hire, pay, and review.
#   - `role: 'professional'` -> Can complete a profile, browse jobs, apply, get hired, and be reviewed.
#
# - Job Lifecycle: A job progresses through a defined state machine.
#   - `STATUS_OPEN`: A job posted by a client, visible to professionals.
#   - `STATUS_APPLIED`: A professional has applied for the job.
#   - `STATUS_PENDING`: A professional has been assigned but has not yet accepted.
#   - `STATUS_ACCEPTED`: The professional has accepted the job. The work is now active.
#   - `STATUS_IN_PROGRESS`: The job is actively being worked on.
#   - `STATUS_COMPLETED`: The job has been marked as complete by the professional.
#   - `STATUS_PAID`: The client has successfully paid for the completed job.
#   - `STATUS_CANCELLED`: The job was cancelled by either party.
#

#
# ======= 3. TECHNOLOGY STACK =======
#
# --- Frontend ---
# - Framework: Flutter 3.x
# - Language: Dart
# - State Management: Provider / BLoC (deduced from complexity)
# - HTTP Client: Dio / http
# - Image/Video Handling: image_picker, video_player
#
# --- Backend ---
# - Service Provider: Firebase (BaaS)
# - Database: Cloud Firestore (NoSQL, Real-time)
# - Authentication: Firebase Authentication (Email/Pass, Phone)
# - File Storage: Supabase Storage (For larger media files)
#
# --- UI/UX ---
# - Theming: Material Design with custom theming for Light/Dark modes.
# - Language Support: Primary language is Amharic, with some English text.
#

#
# ======= 4. FEATURE DEEP DIVE =======
#
# --- 4.1. Authentication Module (`auth/`) ---
#
#   - [x] Dual Sign-Up Flow
#         - User selects role: "Client" (አግልግሎት ፈላጊ) or "Professional" (ባለሙያ).
#   - [x] Email & Password Registration
#         - Input fields for Full Name, Email, Phone (Required), Password, Confirm Password.
#         - Validation for all fields.
#   - [x] Email Verification
#         - Post-registration, an email is sent to the user's provided address.
#         - A dedicated screen prompts the user to check their email.
#         - The user account is marked as `emailVerified: false` until the link is clicked.
#         - A "Resend Email" option is available.
#   - [x] Login (`login_screen.dart`)
#         - https://imgur.com/feCqGST.png
#         - Fields for Email and Password.
#         - Password visibility toggle.
#         - "Forgot Password?" link.
#   - [x] Google Sign-In (Optional)
#         - A dedicated "Sign in with Google" button.
#   - [x] Session Persistence
#         - User remains logged in across app restarts until explicitly logging out.
#
# --- 4.2. Professional Onboarding & Profile (`professional/`) ---
#
#   - [x] Multi-Step Profile Creation Wizard
#         - A progress bar indicates completion percentage (`Profile Strength`).
#   - [x] Step 1: Profile Photo
#         - Option to upload a friendly photo from the device gallery.
#   - [x] Step 2: About You
#         - `Full Name`
#         - `Primary Profession` (e.g., 'electric')
#         - `Public Contact Number`
#         - `Primary City or Town` (e.g., '123456')
#   - [x] Step 3: Your Expertise
#         - `Years of Professional Experience` (e.g., '4')
#         - `Professional Bio` (A text area to describe work ethic, skills, etc.)
#   - [x] Step 4: Skill Selection
#         - A categorized, expandable list of skills.
#         - Categories observed: `IT & Electronics`.
#         - Skills observed: `Computer Repair`, `Networking Setup`, `Electrical Wiring`.
#         - Multiple skills can be selected via checkboxes.
#   - [x] Step 5: Media Showcase
#         - `Add Video Introduction`: Upload a short video.
#         - `Your Work Gallery`: Upload up to 6 images showcasing past work.
#         - `Certifications & Licenses`: Upload up to 6 images of credentials.
#   - [x] Step 6: Business Details
#         - `Your Base Rate`: Set an hourly rate in ETB.
#         - `Your Weekly Availability`: Set available start/end times for each day of the week (Mon-Sun).
#
# --- 4.3. Client-Side Functionality (`client/`) ---
#
#   - [x] Home Screen (`ej3xYq3.png`)
#         - Displays a grid of available professionals (`ProfessionalCard` widget).
#         - Each card shows: Profile Image, Name, Profession, Rating, Hourly Rate.
#         - Search bar for keywords.
#         - Filter button.
#   - [x] Worker Profile View (`nXJjKpg.png`)
#         - A detailed view when a client taps on a professional.
#         - Shows all professional details: bio, experience, skills, gallery, video, reviews.
#         - "Hire" button.
#   - [x] Job Posting (`modernhome.dart` related)
#         - A form to create a new job request.
#         - `Job Title`
#         - `Description`
#         - `Budget (ETB)`
#         - `Location`
#         - `Attachments` (Upload photos/videos related to the job)
#         - `Schedule Date` (Date picker)
#   - [x] Job Management Dashboard (`JGHj8oS.png`)
#         - Lists all jobs posted by the client.
#         - Tabs to filter by status: `Open`, `Pending`, `Accepted`, `Completed`.
#   - [x] Payment Flow
#         - Triggered after a job is marked "Completed".
#         - Displays Order Summary (Job Title, Service Fee, Total Amount).
#         - Payment method selection: `Telebirr` or `CBE Birr`.
#         - For CBE Birr, an option to upload proof of payment is available.
#   - [x] Rating & Review System (`Al5E3Ac.png`)
#         - A screen to rate the professional on a 5-star scale.
#         - A text field to leave a detailed review.
#         - Visible on the professional's public profile.
#   - [x] Client Profile View (`S6Kd2oL.png`)
#         - Shows client's basic info.
#         - Stats for jobs posted and completed.
#
# --- 4.4. Professional-Side Functionality (`worker/`) ---
#
#   - [x] Home Screen / Job Feed (`jUzPnJ2.png`)
#         - A list/grid of "Recent Open Jobs".
#         - Each job card shows: Title, description snippet, location, budget.
#   - [x] Job Details View
#         - Shows full details of a job posting.
#         - Includes any attachments uploaded by the client.
#         - "Apply for This Job" button.
#   - [x] My Work Dashboard
#         - Tabs: `Assigned Jobs`, `My Application`, `Active Work`.
#         - `Assigned Jobs`: Shows jobs the professional has been hired for but hasn't accepted.
#         - Provides `Accept` and `Decline` options.
#         - `Active Work`: Shows jobs that have been accepted.
#         - Provides a `Mark Complete` button.
#   - [x] Notifications
#         - Real-time notifications for:
#           - New job postings matching skills ("Yo, New Gig Dropped!").
#           - Job status updates (e.g., changed to completed/accepted).
#

#
# ======= 5. BACKEND SCHEMA (FIRESTORE & SUPABASE) =======
#
# --- 5.1. Firestore Collections ---
#
# ```
# /users (collection)
#   /{userId} (document)
#     - uid: string
#     - email: string
#     - name: string
#     - phoneNumber: string
#     - profileImageUrl: string
#     - role: 'client' | 'professional'
#     - createdAt: timestamp
#
# /professionals (collection)
#   /{professionalId} (document) // professionalId == userId
#     - name: string
#     - profession: string
#     - phoneNumber: string
#     - location: string (or geopoint)
#     - about: string
#     - experience: number (years)
#     - skills: array<string>
#     - hourlyRate: number
#     - rating: number (average)
#     - ratingCount: number
#     - profileImageUrl: string (from Supabase)
#     - introVideoUrl: string (from Supabase)
#     - galleryImageUrls: array<string> (from Supabase)
#     - certificationImageUrls: array<string> (from Supabase)
#     - weeklyAvailability: map<day, {start: string, end: string, isActive: bool}>
#     - profileComplete: boolean
#
# /jobs (collection)
#   /{jobId} (document)
#     - title: string
#     - description: string
#     - budget: number
#     - location: string
#     - clientId: string (references /users/{userId})
#     - professionalId: string (references /users/{userId}, null until assigned)
#     - status: 'open' | 'pending' | 'accepted' | 'completed' | 'paid'
#     - createdAt: timestamp
#     - scheduledFor: timestamp
#     - attachmentUrls: array<string> (from Supabase)
#
# /reviews (collection)
#   /{reviewId} (document)
#     - professionalId: string
#     - clientId: string
#     - clientName: string
#     - jobId: string
#     - rating: number (1-5)
#     - comment: string
#     - createdAt: timestamp
#
# /notifications (collection)
#   /{notificationId} (document)
#     - recipientId: string
#     - title: string
#     - body: string
#     - type: 'new_job' | 'status_update'
#     - isRead: boolean
#     - createdAt: timestamp
# ```
#
# --- 5.2. Supabase Storage Buckets ---
#
# ```
# /public/
#   - profile_images/{userId}/...
#   - intro_videos/{userId}/...
#   - gallery_images/{professionalId}/{imageId}...
#   - certification_images/{professionalId}/{certId}...
#   - job_attachments/{jobId}/{attachmentId}...
# ```
#

#
# ======= 6. SCREEN & COMPONENT BREAKDOWN =======
#
# - `screens/`
#   - `auth/`
#     - `login_screen.dart`
#     - `register_screen.dart`
#     - `verify_email_screen.dart`
#   - `client/`
#     - `client_home_screen.dart`
#     - `worker_detail_screen.dart`
#     - `post_job_screen.dart`
#     - `client_job_dashboard.dart`
#     - `payment_screen.dart`
#     - `rate_worker_screen.dart` (`Al5E3Ac.png`)
#     - `client_profile_screen.dart` (`S6Kd2oL.png`)
#   - `professional/`
#     - `professional_home_screen.dart` (`jUzPnJ2.png`)
#     - `professional_onboarding/`
#       - `step1_photo.dart`
#       - `step2_about.dart`
#       - `...all 6 steps`
#     - `job_detail_screen.dart`
#     - `worker_job_dashboard.dart`
#   - `shared/`
#     - `profile_settings_screen.dart` (`b8OQdUF.png`)
#     - `notifications_screen.dart`
#
# - `widgets/`
#   - `professional_card.dart`       // Card shown on the client home screen
#   - `job_card.dart`                // Card shown on the professional home screen
#   - `custom_textfield.dart`        // Reusable text input field
#   - `custom_button.dart`           // Reusable primary button
#   - `star_rating_widget.dart`      // Interactive star rating input
#   - `availability_picker.dart`     // Widget for setting daily availability
#   - `progress_indicator_bar.dart`  // Profile strength / Job status progress bar
#

#
# ======= 7. KEY USER WORKFLOWS =======
#
# --- 7.1. Worker Registration & Onboarding ---
# 1. User selects "Professional" at sign-up.
# 2. User provides credentials and registers.
# 3. User verifies their email address.
# 4. Upon first login, user is redirected to the multi-step profile creation wizard.
# 5. User provides all required information (photo, bio, skills, rates, etc.).
# 6. On final step, a `professional` document is created in Firestore with `profileComplete: true`.
# 7. User is navigated to the professional home screen (`jUzPnJ2.png`).
#
# --- 7.2. Client Job Posting & Hiring ---
# 1. Client logs in and lands on the home screen (`ej3xYq3.png`).
# 2. Client finds a professional they like and navigates to their profile (`nXJjKpg.png`).
# 3. Client clicks "Hire".
# 4. A job posting form appears, pre-filled with the selected professional.
# 5. Client fills in job details (title, budget, etc.) and submits.
# 6. A new document is created in the `jobs` collection with `status: 'pending'`.
# 7. The professional receives a notification about the new job offer.
#
# --- 7.3. Job Completion & Payment ---
# 1. Professional navigates to their "Active Work" dashboard.
# 2. After finishing the work, they click "Mark Complete".
# 3. The job status in Firestore is updated to `completed`.
# 4. The Client receives a notification that the job is complete and payment is due.
# 5. The Client navigates to their dashboard, sees the completed job, and initiates payment.
# 6. Client chooses a payment method and completes the transaction.
# 7. The job status is updated to `paid`.
# 8. The client is prompted to leave a review (`Al5E3Ac.png`).
#

#
# ======= 8. SETUP AND INSTALLATION =======
#
# 1. **Clone Repository**
#    ```sh
#    git clone <your-repository-url>
#    cd <repository-folder>
#    ```
#
# 2. **Configure Firebase**
#    - Visit https://console.firebase.google.com/ and create a new project.
#    - Go to Project Settings -> General. Add an Android, iOS, and Web app.
#    - For Android, use `com.example.fixit` as package name (or update `build.gradle`). Download `google-services.json` and place it in `android/app/`.
#    - For Web, copy the Firebase config object.
#    - In Firestore, create the collections as defined in Section 5.
#    - In Authentication -> Sign-in method, enable "Email/Password" and "Phone".
#
# 3. **Configure Supabase**
#    - Visit https://app.supabase.com/ and create a new project.
#    - Go to Storage and create the public buckets as defined in Section 5.
#    - Go to Project Settings -> API and copy your Project URL and anon key.
#
# 4. **Set Environment Variables**
#    - Create a `.env` file in the root of the project.
#    - Add your Firebase and Supabase credentials:
#      ```
#      FIREBASE_API_KEY=...
#      FIREBASE_AUTH_DOMAIN=...
#      # ... and other firebase web keys
#      SUPABASE_URL=...
#      SUPABASE_ANON_KEY=...
#      ```
#
# 5. **Run Flutter**
#    ```sh
#    flutter pub get
#    flutter run
#    ```
#

#
# ======= 9. TODO & FUTURE ENHANCEMENTS =======
#
# - [ ] Implement in-app chat between clients and professionals.
# - [ ] Add a map view for locating professionals and jobs.
# - [ ] Integrate a real payment gateway API instead of manual proof upload.
# - [ ] Develop a dispute resolution system.
# - [ ] Add advanced filtering options (by price, distance, rating).
# - [ ] Create an admin panel for user and job management.
# - [ ] Refactor state management for better scalability.
# - [ ] Add comprehensive unit and integration tests.
#
######################################################################################
# END OF FILE
######################################################################################
