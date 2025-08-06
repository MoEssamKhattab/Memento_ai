# Memento - AI Personal Assistant

**Memento** is an intelligent Flutter-based mobile application that serves as your personal AI assistant. The app leverages Google's Gemma AI model to provide voice-enabled interactions, smart reminders, and context-aware assistance while prioritizing user privacy with offline AI processing.

## 📱 Features

### Core Functionality
- **Voice Interaction**: Natural speech-to-text and text-to-speech capabilities
- **AI Agent System**: Powered by Google Gemma AI model for intelligent responses
- **Smart Reminders**: Location-based and time-based notifications
- **Offline Processing**: Privacy-focused local AI processing without cloud dependency
- **Background Service**: Continuous listening and assistance in passive mode
- **Multi-Platform Support**: Android, iOS, Windows, macOS, Linux, and Web

### User Management
- **Authentication System**: Secure login and signup functionality
- **Profile Management**: Personalized user profiles and preferences
- **Subscription Tiers**: Free and premium subscription options
- **Settings & Customization**: Comprehensive app configuration options

### Advanced Features
- **Agent-Based Architecture**: Modular AI system with specialized agent nodes
- **Database Integration**: Local SQLite database for data persistence
- **Real-time Notifications**: Smart notification system with timezone support
- **Location Services**: GPS-based triggers and location-aware features
- **Volume Control Integration**: Automatic volume adjustment for better UX

## 🏗️ Architecture

### Project Structure
```
lib/
├── main.dart                    # Application entry point
├── agents/                      # AI Agent system
│   ├── agent.dart              # Main agent orchestrator
│   ├── agent_nodes.dart        # Specialized agent nodes
│   ├── database_service.dart   # Database operations
│   ├── prompts.dart            # AI prompts and templates
│   ├── schemas.dart            # Data schemas
│   └── state.dart              # Agent state management
├── backend/                     # Backend services
│   ├── auth_service.dart       # Authentication logic
│   ├── handle_query.dart       # Query processing
│   └── settings_service.dart   # Settings management
├── pages/                       # UI screens
│   ├── home_page.dart          # Main application screen
│   ├── login_page.dart         # User authentication
│   ├── signup_page.dart        # User registration
│   ├── onboarding_page.dart    # First-time user experience
│   ├── profile_page.dart       # User profile management
│   ├── settings_page.dart      # App configuration
│   ├── subscriptions_page.dart # Subscription plans
│   └── subscription_details_page.dart
├── services/                    # Core services
│   ├── gemma_service.dart      # AI model integration
│   └── response_generator.dart # AI response processing
├── utils/                       # Utilities
│   └── notification_helper.dart # Notification management
└── widgets/                     # Reusable UI components
    ├── custom_appbar.dart      # Custom app bar
    └── memento_drawer.dart     # Navigation drawer
```

### Agent System
The app implements a sophisticated agent-based architecture:
- **Router**: Directs queries to appropriate specialized nodes
- **Agent Nodes**: Handle specific types of requests (reminders, questions, etc.)
- **Response Generator**: Processes AI model outputs
- **State Management**: Maintains conversation context and user preferences

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: Version 3.7.2 or higher
- **Dart**: Compatible version with Flutter SDK
- **Android Studio** or **VS Code** with Flutter extensions
- **Device Requirements**: 
  - Android 6.0+ (API level 23+)
  - iOS 12.0+
  - Minimum 4GB RAM recommended for AI model

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd GPV2
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure platform-specific settings**
   - **Android**: Ensure `android/app/google-services.json` is properly configured
   - **iOS**: Configure signing certificates and provisioning profiles

4. **Generate app icons and splash screens**
   ```bash
   flutter pub run flutter_launcher_icons:main
   flutter pub run flutter_native_splash:create
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

### First-Time Setup
1. Launch the app and complete the onboarding process
2. Create an account or log in with existing credentials
3. Grant necessary permissions (microphone, notifications, location)
4. Choose your subscription plan (Basic/Plus)
5. Configure voice and notification preferences

## 🔧 Configuration

### Environment Setup
The app uses several environment-dependent features:

#### Permissions Required
- **Microphone**: For voice input and speech recognition
- **Notifications**: For reminders and alerts
- **Location**: For location-based triggers (Plus plan)
- **Storage**: For local AI model and data storage
- **Phone**: For integration with device features

#### AI Model Configuration
The app downloads and runs the Gemma AI model locally:
- Model size: ~2GB
- First launch requires internet for model download
- Subsequent usage works offline

### Subscription Plans

#### Basic Plan (Free)
- Voice mode with offline AI
- Basic reminders and notifications
- Passive mode limited to 2 hours/day
- Core assistant features

#### Plus Plan ($30/month)
- Unlimited passive mode
- Location-based triggers
- Advanced AI capabilities
- Priority support
- Enhanced customization options

## 🛠️ Development

### Dependencies

#### Core Flutter Dependencies
```yaml
flutter_gemma: ^0.9.0           # AI model integration
shared_preferences: ^2.2.2      # Local data storage
speech_to_text: ^7.0.0         # Voice input
flutter_tts: ^4.2.2            # Text-to-speech
flutter_local_notifications: ^19.1.0  # Notifications
permission_handler: ^12.0.0     # Permission management
```

#### Platform-Specific Features
```yaml
flutter_background_service: ^5.1.0    # Background processing
geolocator: ^14.0.1                   # Location services
connectivity_plus: ^6.1.4             # Network monitoring
real_volume: ^1.0.9                   # Volume control
```

#### Database & Storage
```yaml
sqflite: ^2.3.0                # Local database
path_provider: ^2.1.5          # File system access
```

### Building for Production

#### Android
```bash
flutter build apk --release
# or for App Bundle
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

#### Desktop Platforms
```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

### Testing
```bash
# Run unit tests
flutter test

# Run widget tests
flutter test test/widget_test.dart
```

## 🔒 Privacy & Security

### Data Protection
- **Local AI Processing**: All AI computations happen on-device
- **No Cloud Dependency**: Core features work without internet
- **Encrypted Storage**: User data encrypted using platform security
- **Minimal Data Collection**: Only necessary data for app functionality

### Permissions Usage
- **Microphone**: Only active during voice interactions
- **Location**: Used solely for location-based reminders (opt-in)
- **Notifications**: Required for reminder functionality
- **Storage**: For AI model and user data storage

## 🤝 Contributing

### Development Guidelines
1. Follow Flutter/Dart coding standards
2. Maintain agent-based architecture patterns
3. Ensure offline functionality for core features
4. Test thoroughly on multiple platforms
5. Document AI prompt changes

### Code Style
- Use meaningful variable and function names
- Comment complex AI logic and agent interactions
- Follow Flutter widget lifecycle best practices
- Implement proper error handling

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

### Troubleshooting

#### Common Issues
1. **AI Model Download Fails**: Ensure stable internet connection and sufficient storage
2. **Voice Recognition Not Working**: Check microphone permissions
3. **Notifications Not Appearing**: Verify notification permissions and timezone settings
4. **App Crashes on Startup**: Clear app data and restart

#### Performance Optimization
- Close other apps during AI model initialization
- Ensure device has sufficient RAM (4GB+ recommended)
- Keep app updated for latest optimizations

### Getting Help
- Check the troubleshooting section above
- Review Flutter documentation for platform-specific issues
- Contact support through the app's settings page

## 🔄 Updates & Roadmap

### Recent Updates
- Implemented agent-based AI architecture
- Added offline Gemma AI model integration
- Enhanced voice interaction capabilities
- Improved notification system

### Upcoming Features
- Enhanced location-based triggers
- Advanced AI conversation memory
- Integration with more third-party services
- Cross-device synchronization
- Advanced analytics and insights

---

**Memento** - Your intelligent, privacy-focused personal assistant that learns and adapts to help you stay organized and productive.
