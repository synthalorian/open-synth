# Contributing to Open Synth

Thank you for your interest in contributing to Open Synth! This document outlines the guidelines for contributing to the project.

## Code of Conduct

Be respectful, constructive, and inclusive. We welcome contributors of all skill levels.

## How to Contribute

### Reporting Bugs

- Check existing issues first to avoid duplicates.
- Provide a clear description of the bug, steps to reproduce, expected vs. actual behavior.
- Include your OS, Flutter version, and any relevant logs.

### Suggesting Features

- Open an issue with the "enhancement" label.
- Describe the feature, its use case, and any implementation ideas.

### Pull Requests

1. Fork the repository and create a feature branch (`git checkout -b feature/my-feature`).
2. Make your changes with clear, focused commits.
3. Ensure the native library builds cleanly:
   ```bash
   cd native/build
   cmake .. -DCMAKE_BUILD_TYPE=Release
   make -j$(nproc)
   ```
4. Test your changes with `flutter run`.
5. Update documentation if needed.
6. Submit a pull request with a clear description.

## Development Setup

### Prerequisites

- Flutter SDK 3.11+
- CMake 3.20+
- C++17 compiler
- PortAudio (desktop) or Android NDK (mobile)

### Building the Native Library

```bash
cd native/build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

The shared library will be output to `native/libopenamp_dart_ffi.so` (Linux).

### Project Structure

```
open-synth/
├── lib/           # Flutter/Dart source
├── native/        # C++ DSP engine
│   ├── include/   # Headers
│   ├── src/       # Implementation
│   └── build/     # CMake build directory
├── assets/        # Presets, wavetables, images
├── docs/          # Documentation
└── test/          # Unit tests
```

## Coding Standards

### Dart
- Follow the [Dart style guide](https://dart.dev/effective-dart/style).
- Use `flutter analyze` to catch issues.

### C++
- C++17 standard.
- Prefer clear, readable code over clever optimizations.
- Document public APIs with comments.
- Keep the audio callback lock-free and real-time safe.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
