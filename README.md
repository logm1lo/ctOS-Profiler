![image](https://github.com/logm1lo/ctOS-Profiler/blob/master/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png)

# ctOS - Profiler

ctOS - Profiler is a sophisticated mobile surveillance and offensive security toolkit inspired by the *Watch Dogs* series. It merges real-time computer vision with hardware-level exploit engines and comprehensive OSINT integration, all wrapped in a visually immersive "Watch Dogs" HUD.

## Features

* **AI Face Detection & Recognition:** Real-time tracking and matching using high-performance models (FaceNet, MobileFaceNet).
* **Multi-Sample Support:** Enhanced recognition accuracy by storing multiple face samples (embeddings) per target.
* **Deep Profiling:** Generate digital dossiers including demographics, biometrics, and threat levels.
* **Automated OSINT Engine:** Integrates with FaceCheck.id and WhatsMyName to resolve physical identities to digital handles across 20+ social platforms.
* **WhisperPair (CVE-2025-36911):** Forced pairing with vulnerable Fast Pair peripherals bypassing user consent.
* **BLE Spam Engine:** High-frequency advertisement flooder targeting iOS, Android, and Samsung ecosystems.
* **BlueBorne Prober:** Remote vulnerability scanner utilizing L2CAP and SDP discovery.
* **NFC Skimmer:** Proximity-based card auditing with Mifare Classic dictionary attack module.
* **Network Interrogator:** Subnet discovery, port scanning, and node disruption.
* **Input Auditor:** Background keylogging via AccessibilityService.
* **Full-System Instrumentation:** Detailed structured logging (Logcat `ctOS_` tags) for total traceability.

## Tech Stack

* **Framework:** Flutter (target SDK >= 3.1.0)
* **Languages:** Dart, Kotlin, Java, C++
* **AI Engine:** LiteRT (TensorFlow Lite)
* **Native Core:** Android BluetoothLeAdvertiser, GATT, Accessibility
* **Database:** sqflite (SQLite)
* **State Management:** Riverpod (v2)

## Quick Start

### Prerequisites

*   **Flutter SDK:** Stable channel (**3.44.0**)
*   **Android SDK:** Platform 36 (compileSdk 36, targetSdk 36)
*   **Android NDK:** Version **25.1.8937393** (Strictly required for native exploit engine compilation)
*   **Java:** Version 17 (Required for AGP 8.11.1 compatibility)
*   **Dart:** Version **3.12.0**
*   **Build Environment:** Android Gradle Plugin (AGP) 8.11.1+
*   **Permissions:** Location, Bluetooth, and Accessibility services must be enabled for full functional tool access.

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

* **Presentation Layer:** Handles UI rendering (Watch Dogs HUD) and state management using Riverpod.
* **Domain Layer:** Defines core entities (`FaceEntity`) and business rules.
* **Data Layer:** Implements data persistence and coordinates between local databases and models.
* **Native Infrastructure:** Leverages optimized image conversion and background exploit engines in Kotlin.

## Performance Optimizations

* **Adaptive Throttling:** The AI pipeline dynamically adjusts frame processing speed (target ~150ms).
* **In-Memory Caching:** Face embeddings are cached for microsecond matching latency.
* **Isolate Offloading:** Heavy image processing (rotation, YUV conversion) is performed in background isolates.

## Common Errors

### AGP Version Conflict
If you see errors regarding Android Gradle Plugin (AGP) version 8.11.1, ensure your environment supports this version or run with `--android-skip-build-dependency-validation`.

### NDK Path Issues
Ensure `ndk.dir` or `sdk.dir` is correctly set in `local.properties`. Version **25.1.8937393** is strictly required for certain native exploit engines to compile correctly.

## ⚠Critical Security Disclaimer

**FOR RESEARCH AND EDUCATIONAL PURPOSES ONLY.**

ctOS-Profiler is a functional offensive security tool. It handles sensitive biometric data (PII) and utilizes techniques often flagged as malicious by mobile operating systems (BLE Spamming, Keylogging, Forced Pairing). Use only on hardware you own or have explicit permission to test.

## Code Credits & Acknowledgments

This project integrates and adapts core logic from the following groundbreaking security research and open-source projects:

*   **BlueBorne:** Based on research and PoC by [mailinneberg/BlueBorne](https://github.com/mailinneberg/BlueBorne).
*   **Bluetooth-LE-Spam:** Native advertising generators adapted from [simondankelmann/Bluetooth-LE-Spam](https://github.com/simondankelmann/Bluetooth-LE-Spam).
*   **WhisperPair:** Fast Pair exploit logic ported from [zalexdev/wpair-app](https://github.com/zalexdev/wpair-app).

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
