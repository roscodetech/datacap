# DataCap

A powerful cross-platform Flutter application for ML data collection. Capture, organize, and manage photos and videos in structured datasets for machine learning model training.

Built by [ROSCODE TECH](https://github.com/roscodetech)

---

## Features

### Data Capture
- **Photo Capture** - Take photos using device camera or select from gallery
- **Video Recording** - Record videos with full audio support
- **Web Camera Support** - Native HTML5 camera integration for Chrome/web browsers
- **Batch Upload** - Queue multiple items and upload all at once

### Dataset Management
- **Hierarchical Organization** - Structure data as `Dataset → Class → Media`
- **Dataset Browser** - Navigate through datasets with an intuitive UI
- **Quick Add** - Capture directly into a specific dataset/class context
- **Rename & Delete** - Full CRUD operations on datasets, classes, and media items

### Media Gallery
- **Tabbed Interface** - View All, Photos, Videos, or Datasets
- **Video Playback** - Full-screen video player with controls
- **Video Thumbnails** - Auto-generated first-frame thumbnails
- **Pull to Refresh** - Sync with cloud storage on demand

### Cloud Integration
- **Firebase Storage** - Secure cloud storage for all media
- **Firebase Authentication** - Email/password and anonymous sign-in
- **Smart Caching** - Minimizes reads with intelligent in-memory caching
- **Real-time Sync** - Changes reflect immediately across devices

### User Experience
- **Dark/Light Mode** - Automatic theme based on system preference
- **Responsive Design** - Works on mobile, tablet, and desktop
- **Progress Tracking** - Visual feedback during uploads
- **Offline Queue** - Queue items for upload when online

---

## Screenshots

| Home | Capture | Gallery | Datasets |
|:----:|:-------:|:-------:|:--------:|
| Dashboard with stats | Photo/Video capture | Media grid view | Dataset browser |

---

## Getting Started

### Prerequisites

- Flutter SDK (3.4.1 or higher)
- Dart SDK (3.4.1 or higher)
- Firebase project with Storage and Authentication enabled
- Android Studio / Xcode (for mobile development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/roscodetech/datacap.git
   cd datacap
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   For Android:
   - Add your `google-services.json` to `android/app/`

   For iOS:
   - Add your `GoogleService-Info.plist` to `ios/Runner/`

   For Web:
   - Update Firebase options in `lib/main.dart`

4. **Configure CORS (for web)**
   ```bash
   gsutil cors set cors.json gs://your-bucket-name.appspot.com
   ```

5. **Run the app**
   ```bash
   # For web
   flutter run -d chrome

   # For Android
   flutter run -d android

   # For iOS
   flutter run -d ios
   ```

---

## Project Structure

```
lib/
├── core/
│   └── theme/
│       ├── app_colors.dart      # Color palette
│       ├── app_spacing.dart     # Spacing constants
│       └── app_theme.dart       # Theme configuration
├── models/
│   └── media_data.dart          # Data models
├── providers/
│   └── media_provider.dart      # State management
├── screens/
│   ├── home_screen.dart         # Main dashboard
│   ├── capture_screen.dart      # Photo/video capture
│   ├── gallery_screen.dart      # Media gallery
│   ├── dataset_browser_screen.dart  # Dataset navigation
│   ├── video_player_screen.dart # Video playback
│   ├── sign_in_screen.dart      # Authentication
│   └── web_camera_screen.dart   # Web camera interface
├── services/
│   ├── upload_services.dart     # Firebase Storage operations
│   ├── web_camera_service.dart  # Web camera abstraction
│   └── web_camera_web.dart      # HTML5 camera implementation
├── widgets/
│   ├── media_input_form.dart    # Dataset/class input
│   ├── media_list_view.dart     # Media list component
│   ├── video_thumbnail.dart     # Video preview widget
│   └── ...
└── main.dart                    # App entry point
```

---

## Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.4+ |
| Language | Dart 3.4+ |
| Backend | Firebase (Storage, Auth) |
| State Management | Provider |
| Video Playback | video_player |
| Image Handling | image_picker |
| Permissions | permission_handler |

---

## Firebase Storage Structure

```
datasets/
├── dataset_name_1/
│   ├── class_label_a/
│   │   ├── photo_001.jpg
│   │   ├── photo_002.jpg
│   │   └── video_001.mp4
│   └── class_label_b/
│       └── ...
└── dataset_name_2/
    └── ...
```

---

## Configuration

### Android Requirements
- Min SDK: 23 (Android 6.0)
- Target SDK: 34 (Android 14)
- Gradle: 8.7
- AGP: 8.6.0
- Kotlin: 2.1.0

### Permissions Required
- Camera
- Microphone (for video recording)
- Storage (read/write)
- Internet

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

This project is proprietary software owned by ROSCODE TECH.

---

## Contact

**ROSCODE TECH**
- GitHub: [@roscodetech](https://github.com/roscodetech)

---

<p align="center">
  <strong>DataCap</strong> - Streamline your ML data collection workflow
</p>
