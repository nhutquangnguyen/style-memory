# StyleMemory

**Help hair stylists remember clients' styles with photos and notes**

StyleMemory is a Flutter mobile application designed specifically for hair stylists to track and remember their clients' hairstyles through photos and detailed notes. The app provides a clean, professional interface for managing client visits, capturing systematic photos, and maintaining a visual history of each client's styling journey.

## 🚀 Features

### Core Functionality
- **Client Management**: Add and organize client information with contact details
- **4-Photo Capture System**: Systematic photo capture (front, back, left, right views)
- **Visit Tracking**: Record service details, notes, and products used for each visit
- **Photo Gallery**: Browse through a client's complete styling history
- **Search & Filter**: Quickly find clients with search functionality

### Authentication & Security
- Username/password authentication via Supabase
- Row-level security ensuring data privacy
- Secure photo storage with user-scoped access

### User Experience
- Clean, minimal design with neutral color palette
- Intuitive navigation with bottom tabs
- Loading states and error handling throughout
- Responsive design optimized for mobile devices

## 🛠 Tech Stack

- **Frontend**: Flutter 3.19+ with Dart
- **Backend**: Supabase (PostgreSQL, Authentication, Storage)
- **State Management**: Provider
- **Navigation**: go_router
- **Image Processing**: image package for compression
- **Camera**: camera package for photo capture

## 📱 Screens Overview

1. **Welcome Screen**: App introduction with branding
2. **Authentication**: Sign up and login flows
3. **Clients List**: Home screen showing all clients with search
4. **Client Profile**: Individual client details with visit history
5. **Add Client**: Form to create new client records
6. **Camera Capture**: Guided 4-step photo capture workflow
7. **Add Notes**: Visit details form with service notes
8. **Visit Details**: Full-screen photo viewer with visit information
9. **Settings**: User profile management and app preferences

## 🏗 Project Structure

```
lib/
├── main.dart                 # App entry point with providers
├── models/                   # Data models
│   ├── client.dart
│   ├── photo.dart
│   ├── user_profile.dart
│   ├── visit.dart
│   └── models.dart          # Barrel exports
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── camera_provider.dart
│   ├── clients_provider.dart
│   ├── visits_provider.dart
│   └── providers.dart       # Barrel exports
├── screens/                  # UI screens
│   ├── auth/                # Authentication flows
│   ├── camera/              # Photo capture workflow
│   ├── clients/             # Client management
│   ├── visits/              # Visit details
│   └── settings_screen.dart
├── services/                 # Business logic
│   ├── supabase_service.dart
│   └── photo_service.dart
├── theme/                    # Design system
│   └── app_theme.dart
├── utils/                    # Utilities
│   └── app_router.dart
└── widgets/                  # Reusable components
    ├── common/
    └── forms/
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.19.0 or later)
- Dart SDK (3.3.0 or later)
- iOS Simulator / Android Emulator or physical device
- Supabase account

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd style_memory
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Supabase backend**
   - Follow the detailed guide in `supabase_setup.md`
   - Create your Supabase project
   - Run the provided SQL schema
   - Set up storage bucket and policies

4. **Update configuration**
   ```bash
   # Copy the example environment file
   cp .env.example .env

   # Edit .env with your actual Supabase credentials
   # SUPABASE_URL=https://your-project-id.supabase.co
   # SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6...
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### Environment Setup

The app uses environment variables for secure credential management:

```bash
# .env file (already added to .gitignore)
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
```

**Important**: Never commit the `.env` file to version control. Use `.env.example` as a template.

### Permissions

The app requires camera permissions for photo capture:

**iOS** (ios/Runner/Info.plist):
```xml
<key>NSCameraUsageDescription</key>
<string>StyleMemory needs camera access to capture client photos</string>
```

**Android** (android/app/src/main/AndroidManifest.xml):
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

## 📊 Database Schema

The app uses four main tables with Row Level Security:

- **user_profiles**: User account information
- **clients**: Client contact details and metadata
- **visits**: Individual styling session records
- **photos**: Photo metadata with storage paths

All data is scoped to individual users through RLS policies.

## 🔒 Security

- **Row Level Security**: All database access is user-scoped
- **Private Storage**: Photos are stored in private Supabase buckets
- **Authentication**: JWT-based session management
- **Data Isolation**: Complete separation between user accounts

## 🎨 Design System

StyleMemory uses a minimal, professional design system:

- **Colors**: Neutral palette with whites, grays, and subtle accents
- **Typography**: Clear hierarchy with consistent font weights
- **Spacing**: Systematic spacing scale (4px, 8px, 16px, 24px, 32px)
- **Components**: Consistent buttons, cards, and form elements

## 📸 Photo Management

- **Compression**: Images are automatically compressed before upload
- **Naming Convention**: `{userId}/{visitId}/{photoType}.jpg`
- **Size Limits**: Optimized to 1024x1024px maximum
- **Types**: Four systematic angles (front, back, left, right)

## 🧪 Testing

Run tests with:
```bash
flutter test
```

The app includes:
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for key user flows

## 🚢 Deployment

### iOS
1. Configure signing certificates
2. Build with `flutter build ios --release`
3. Upload to App Store Connect

### Android
1. Generate signing keys
2. Build with `flutter build apk --release`
3. Upload to Google Play Console

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Check the [supabase_setup.md](supabase_setup.md) guide for backend issues
- Review the troubleshooting section in the setup guide
- File issues on the GitHub repository

## 🔄 Future Enhancements

Potential features for future versions:
- Photo editing and filters
- Client appointment scheduling
- Export capabilities (PDF reports)
- Cloud backup and sync
- Multi-stylist salon support
- Before/after photo comparisons
- Client communication features

---

**StyleMemory** - Making every client's style unforgettable 💇‍♀️
