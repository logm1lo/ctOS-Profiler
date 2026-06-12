![image](https://github.com/logm1lo/ctOS-Profiler/blob/master/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png)

# ctOS - Profiler

ctOS - Profiler is a mobile application inspired by the *Watch Dogs* series. It provides on-device real-time face recognition, tracking, and detailed target profiling using LiteRT (TensorFlow Lite).

## Table of Contents

* [Features](#features)
* [Tech Stack](#tech-stack)
* [Quick Start](#quick-start)
* [Repository Structure](#repository-structure)
* [Architecture](#architecture)
* [Performance Optimizations](#performance-optimizations)
* [Common Errors](#common-errors)
* [License](#license)

## Features

* **AI Face Detection & Recognition:** Real-time tracking and matching using high-performance models (FaceNet, MobileFaceNet).
* **Multi-Sample Support:** Enhanced recognition accuracy by storing multiple face samples (embeddings) per target, allowing for reliable matching across different lighting and angles.
* **Refine Profile:** On-the-fly accuracy upgrades. Add new samples to existing profiles directly from the HUD when a match is found.
* **Deep Profiling:** Generate and edit detailed digital dossiers for targets, including:
    * **Demographics:** Name, age, birth date, and occupation.
    * **Biometrics:** Height (cm) and weight (kg) tracking.
    * **Socio-Economic Status:** Automated income level assessment.
    * **Risk Assessment:** Real-time threat level calculation (0-100%).
    * **Personality Profiling:** Analysis of positive and negative behavioral traits.
* **Local Database:** Secure on-device storage for face embeddings and profiles via sqflite.

## Tech Stack

* **Framework:** Flutter (target SDK >= 3.1.0)
* **Languages:** Dart, Kotlin, Java, C++
* **AI Engine:** LiteRT (TensorFlow Lite / `face_detection_tflite`)
* **Computer Vision:** Optimized image processing pipeline.
* **Database:** sqflite (SQLite)
* **Build System:** Gradle (AGP 8.9.1), Java 17
* **State Management:** Riverpod (v2)

## Quick Start

### Prerequisites

* **Flutter SDK:** Stable channel (>= 3.1.0)
* **Android SDK:** Platform 36 (compileSdk 36)
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
Create a `local.properties` file in the project root and specify your SDK paths:
```properties
sdk.dir=/path/to/android/sdk
flutter.sdk=/path/to/flutter
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
├── assets/models/         # Pre-trained TFLite models (FaceNet, MobileFaceNet)
├── buildSrc/              # Custom Gradle build logic and mock plugins
├── lib/                   # Flutter source code
│   ├── core/              # Shared utilities, themes, and global providers
│   ├── data/              # Data sources and repository implementations
│   ├── domain/            # Business logic, entities, and use cases
│   └── presentation/      # UI screens, HUD widgets, and Riverpod notifiers
├── pubspec.yaml           # Flutter dependencies and assets configuration
└── README.md              # Project documentation
```

## Architecture

The project follows a **Clean Architecture** pattern with a clear separation of concerns:

* **Presentation Layer:** Handles UI rendering and state management using Riverpod. Screens watch providers to react to real-time AI detections.
* **Domain Layer:** Defines the core entities (`FaceEntity`) and business rules (`MatchFace`).
* **Data Layer:** Implements data persistence and coordinates between local databases and models.
* **Native Infrastructure:** Leverages optimized image conversion and background isolates for heavy lifting like YUV-to-RGB conversion.

## Performance Optimizations

* **Adaptive Throttling:** The AI pipeline dynamically adjusts frame processing speed (target ~150ms) based on hardware capability, ensuring a smooth HUD experience.
* **In-Memory Caching:** Face embeddings are cached in memory after the first database load, reducing matching latency from milliseconds to microseconds.
* **Isolate Offloading:** Heavy image processing (rotation, YUV conversion) is performed in background isolates to prevent main thread blocking.
* **Efficient Similarity Math:** Tightened loops for Cosine Similarity calculations to minimize CPU overhead per frame.

## Common Errors

### AGP Version Conflict
If you see errors regarding Android Gradle Plugin (AGP) version 8.9.1, ensure your environment supports this version or run with `--android-skip-build-dependency-validation`.

### NDK Path Issues
Ensure `ndk.dir` or `sdk.dir` is correctly set in `local.properties`. Version **25.1.8937393** is strictly required for certain native bindings.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
