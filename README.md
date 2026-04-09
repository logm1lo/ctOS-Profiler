# ctOS - Profiler

ctOS - Profiler is a mobile application inspired by the Watch Dogs series, built with Flutter and LiteRT (TensorFlow Lite). It provides on-device face recognition and tracking with a focus on privacy and performance.

## Table of Contents

* [Features](#features)
* [Tech Stack](#tech-stack)
* [Quick Start](#quick-start)
* [Repository Structure](#repository-structure)
* [Architecture](#architecture)
* [Testing](#testing)
* [Contributing](#contributing)
* [Common Errors](#common-errors)
* [License](#license)

## Features

* AI Face Detection: Real-time tracking and recognition using LiteRT.
* Local Storage: Secure storage for face embeddings and logs via sqflite.
* Native Bridge: High-performance camera handling and AI inference via JNI.
* State Management: Reactive and predictable data flow using Riverpod.

## Tech Stack

* Framework: Flutter
* Languages: Dart, Kotlin, Java, C++
* AI Engine: LiteRT (TensorFlow Lite)
* Database: sqflite (SQLite)
* State Management: Riverpod

## Quick Start

### Prerequisites

* Flutter SDK (Stable)
* Android Studio / SDK Platform 35
* Android NDK (Version 25.1.8937393)
* Java 17

### Installation

1. Clone the repository:
```bash
git clone https://github.com/logm1lo/ctOS-Profiler.git
```

2. Get dependencies:
```bash
flutter pub get
```

3. Configuration:
Check `local.properties` in the `android/` folder to ensure your SDK and NDK paths are correct.

4. Run:
```bash
flutter run
```

## Repository Structure

```
ctOS-Profiler/
├── android/               # Android platform files
├── app/                   # Main Android application module
├── assets/models/         # TFLite models and AI assets
├── buildSrc/              # Custom build logic and mock plugins
├── gradle/                # Gradle wrapper and global scripts
├── lib/                   # Flutter source code
│   ├── core/              # Utilities and shared themes
│   ├── data/              # Database and repository implementations
│   ├── domain/            # Business logic and data entities
│   └── presentation/      # UI screens and state providers
├── test/                  # Unit and widget tests
├── build.gradle           # Root build script
├── flutter_mock.gradle    # Custom Flutter build configuration
├── pubspec.yaml           # Flutter project metadata
└── settings.gradle.kts    # Project structure configuration
```

## Architecture

The project uses a layered architecture to keep code clean and maintainable:

* **Presentation:** Manages UI and state via Riverpod providers.
* **Domain:** Contains the core business logic and data models.
* **Data:** Handles persistent storage (SQLite) and native communication.
* **Native Layer:** Manages hardware-heavy tasks like camera frame processing and TFLite execution.

## Testing

Run the full test suite with:
```bash
flutter test
```

## Contributing

Contributions are welcome. Please follow the standard fork-and-pull-request workflow. Ensure your code is formatted (`flutter format .`) and passes all tests before submitting.

## Common Errors

### Duplicate Class Errors
If you run into `Duplicate class io.flutter.Build`, it is likely a conflict between debug and release embeddings. This is handled by the `FlutterMockPlugin` in `buildSrc`. Library dependencies should use `compileOnly` for the Flutter embedding to avoid bundling it multiple times.

### NDK Configuration
The native components require a specific NDK version (25.1.x). If compilation fails, check your NDK installation path in `local.properties`.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
