Student Assistant Application System
Central University of Technology, Free State
Department of Information Technology

📌 Project Overview
This mobile application manages the Student Assistant application process for IT modules in a structured and secure manner. It allows students to apply for positions, while administrative staff can review and manage these applications.

🛠 Tech Stack & Architecture
This project is built using Flutter and follows the MVVM (Model-View-ViewModel) architecture.

Frontend: Flutter & Dart
State Management: Provider
Backend: Supabase (Auth, Database, and File Storage)
Version Control: GitHub

🏗 MVVM Structure
We have strictly followed the MVVM pattern as required:
- Models: Defines the structure of AppUser and StudentApplication.
- Views: UI screens including Onboarding, Login, Student Home, and Admin Dashboard.
- ViewModels: Handles logic and state management using the Provider package.
- Services: Manages raw communication with the Supabase backend.

🚀 Key Features
Student Portal
- Authentication: Secure login via Supabase.
- Home Screen: View submitted applications and their current status.
- Application Form: Submit applications for up to two modules with field validation.
- Manage Applications: View details or delete pending applications.

Admin Portal
- Dashboard: View all student applications globally.
- Review: Access student information and uploaded supporting documentation.
- Decision Making: Approve or reject applications and update status.

📥 Installation & Setup
Clone the repository:
git clone <YOUR_REPOSITORY_URL>
Navigate to the project folder (update the folder name if yours differs):
cd <YOUR_PROJECT_FOLDER>
Install dependencies:
flutter pub get
Configure Supabase:
This project currently hardcodes the Supabase `url` and `anonKey` in `lib/main.dart` inside `Supabase.initialize(...)`.
If you use your own Supabase project, replace those values accordingly.
Run the application:
flutter run

👥 Group Contributions
Student Number: 210070123 — [Name]
Student Number: 210070456 — [Name]
Student Number: 210070789 — [Name]
Student Number: 2100701011 — [Name]

