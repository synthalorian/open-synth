import 'dart:io';
import 'package:path/path.dart' as path;

/// Resolves SFZ sample paths for the current platform.
///
/// On mobile (Android/iOS), Flutter bundles assets automatically so the
/// relative asset path is returned as-is. The native code or Flutter's
/// asset system handles extraction.
///
/// On desktop (Linux, macOS, Windows), Flutter does NOT bundle arbitrary
/// files into the release bundle. The `assets/samples/` directory must be
/// either:
///   1. Copied next to the executable (deployment step), or
///   2. Resolved relative to the executable's directory at runtime.
///
/// This utility tries multiple resolution strategies and returns the first
/// existing path, or the last-resort path if none exist.
///
/// Usage:
///   final resolved = resolveSamplePath('assets/samples/VSCO-2-CE-1.1.0/UprightPiano.sfz');
///   engine.loadSfzFile(resolved);
String resolveSamplePath(String assetPath) {
  // On mobile, return as-is — Flutter handles asset extraction
  if (Platform.isAndroid || Platform.isIOS) {
    return assetPath;
  }

  // Strategy 1: If the path already exists as an absolute or relative path
  // from the current working directory, use it directly.
  if (File(assetPath).existsSync()) {
    return assetPath;
  }

  // Strategy 2: Resolve relative to the executable directory.
  // The executable is at e.g. build/linux/x64/release/bundle/open_synth
  // and samples should be at build/linux/x64/release/bundle/assets/samples/...
  final exePath = Platform.resolvedExecutable;
  final exeDir = File(exePath).parent.path;
  final exeRelativePath = path.join(exeDir, assetPath);
  if (File(exeRelativePath).existsSync()) {
    return exeRelativePath;
  }

  // Strategy 3: Check one level up from executable (some build layouts).
  final parentDir = File(exeDir).parent.path;
  final parentRelativePath = path.join(parentDir, assetPath);
  if (File(parentRelativePath).existsSync()) {
    return parentRelativePath;
  }

  // Strategy 4: Check if there's a data/flutter_assets copy.
  final flutterAssetsPath = path.join(exeDir, 'data', 'flutter_assets', assetPath);
  if (File(flutterAssetsPath).existsSync()) {
    return flutterAssetsPath;
  }

  // Strategy 5: Development mode — resolve relative to project root.
  // Try walking up from CWD to find the project root (contains pubspec.yaml).
  Directory dir = Directory.current;
  for (int i = 0; i < 5; i++) {
    final pubspec = File(path.join(dir.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final projectPath = path.join(dir.path, assetPath);
      if (File(projectPath).existsSync()) {
        return projectPath;
      }
      break;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }

  // Fallback: return the exe-relative path even if it doesn't exist.
  // The caller (engine.loadSfzFile) will fail gracefully and log the error.
  return exeRelativePath;
}

/// Resolves the base samples directory for the current platform.
///
/// Returns the directory that contains the `assets/samples/` tree,
/// or null if it cannot be found.
String? resolveSamplesBaseDir() {
  if (Platform.isAndroid || Platform.isIOS) {
    return null; // Mobile uses Flutter asset system
  }

  final exePath = Platform.resolvedExecutable;
  final exeDir = File(exePath).parent.path;

  // Check exeDir/assets/samples
  final candidate1 = Directory(path.join(exeDir, 'assets', 'samples'));
  if (candidate1.existsSync()) return candidate1.path;

  // Check exeDir/data/flutter_assets/assets/samples
  final candidate2 = Directory(path.join(exeDir, 'data', 'flutter_assets', 'assets', 'samples'));
  if (candidate2.existsSync()) return candidate2.path;

  // Development: check project root
  Directory dir = Directory.current;
  for (int i = 0; i < 5; i++) {
    final pubspec = File(path.join(dir.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final candidate = Directory(path.join(dir.path, 'assets', 'samples'));
      if (candidate.existsSync()) return candidate.path;
      break;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }

  return null;
}

/// Whether the sample library appears to be available at runtime.
bool get samplesAvailable {
  final baseDir = resolveSamplesBaseDir();
  if (baseDir == null) return false;
  final vscoDir = Directory(path.join(baseDir, 'VSCO-2-CE-1.1.0'));
  return vscoDir.existsSync();
}
