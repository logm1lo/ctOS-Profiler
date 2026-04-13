![image](https://github.com/logm1lo/ctOS-Profiler/blob/master/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png)

# ctOS - Profiler

ctOS - Profiler is a mobile application inspired by the *Watch Dogs* series. It provides on-device real-time face recognition, tracking, and detailed target profiling using LiteRT (TensorFlow Lite).

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

* **AI Face Detection & Recognition:** Real-time tracking and matching using high-performance models (FaceNet, MobileFaceNet).
* **Deep Profiling:** Generate and edit detailed digital dossiers for targets, including:
    * **Demographics:** Name, age, birth date (DMY format), and occupation.
    * **Biometrics:** Height (cm) and weight (kg) tracking.
    * **Socio-Economic Status:** Automated income level assessment.
    * **Risk Assessment:** Real-time threat level calculation and monitoring.
    * **Personality Profiling:** Analysis of positive and negative behavioral traits.
* **Local Database:** Secure on-device storage for face embeddings and profiles via sqflite.

## Tech Stack

* **Framework:** Flutter
* **Languages:** Dart, Kotlin, Java, C++
* **AI Engine:** LiteRT (TensorFlow Lite / `face_detection_tflite`)
* **Computer Vision:** OpenCV (`dartcv4`)
* **Database:** sqflite (SQLite)
* **State Management:** Riverpod (v2)

## Quick Start

### Prerequisites

* **Flutter SDK:** Stable channel (>= 3.1.0)
* **Android SDK:** Platform 35
* **Android NDK:** Version **25.1.8937393** (Strictly required for native asset compilation)
* **Java:** Version 17

### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/logm1lo/ctOS-Profiler.git
```

2. **Get dependencies:**
```bash
flutter pub get
```

3. **Configure Environment:**
Create or edit `android/local.properties` and ensure the NDK path is explicitly set:
```properties
sdk.dir=C\:\\Users\\YourUser\\AppData\\Local\\Android\\Sdk
ndk.dir=C\:\\Users\\YourUser\\AppData\\Local\\Android\\Sdk\\ndk\\25.1.8937393
flutter.sdk=C\:\\path\\to\\flutter
```

4. **Run the App:**
```bash
flutter run
```

## Repository Structure

```
ctOS-Profiler/
├── android/               # Android platform-specific configuration
├── app/                   # Main Android application module (Kotlin/Gradle)
├── assets/models/         # Pre-trained TFLite models (FaceNet, etc.)
├── buildSrc/              # Custom Gradle build logic and mock plugins
├── lib/                   # Flutter source code
│   ├── core/              # Shared utilities, themes, and providers
│   ├── data/              # Data sources and repository implementations
│   ├── domain/            # Business logic, entities, and use cases
│   └── presentation/      # UI screens, widgets, and Riverpod notifiers
├── pubspec.yaml           # Flutter dependencies and assets configuration
└── README.md              # Project documentation
```

## Architecture

The project follows a **Clean Architecture** pattern with a Clear separation of concerns:

* **Presentation Layer:** Handles UI rendering and state management using Riverpod. Screens watch providers to react to real-time AI detections.
* **Domain Layer:** Defines the core entities (e.g., `FaceEntity`) and business rules (e.g., `MatchFace`).
* **Data Layer:** Implements data persistence and coordinates between local databases and native services.
* **Native Infrastructure:** Leverages JNI and Dart FFI to perform heavy lifting like YUV-to-RGB conversion and model inference.

## Common Errors

### NDK PathNotFoundException
If you encounter `PathNotFoundException: Directory listing failed` during build, ensure your `ndk.dir` in `local.properties` points to a complete NDK installation. Version **25.1.8937393** is recommended. Avoid using NDK versions that only contain an `.installer` folder.

### Duplicate Class io.flutter.Build
This usually occurs due to a conflict in the Flutter embedding. The project uses a custom `FlutterMockPlugin` in `buildSrc` to manage these dependencies. Ensure that library sub-projects use `compileOnly` for the Flutter embedding.

### Camera Controller "Bad State"
If you see errors related to `CameraControllerNotifier` after `dispose`, ensure that any asynchronous operations (like saving profiles) are guarded with `mounted` checks and that the provider is not being invalidated prematurely during navigation.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
