import 'dart:io';
import 'dart:typed_data';

/// Writes 32-bit float WAV files from interleaved stereo float samples.
///
/// Usage:
/// ```dart
/// final writer = WavWriter('/path/to/output.wav', sampleRate: 48000);
/// // ... feed interleaved stereo samples ...
/// writer.close();
/// ```
class WavWriter {
  WavWriter(String path, {this.sampleRate = 48000, this.numChannels = 2}) {
    _file = File(path);
    _bytes = BytesBuilder();
  }

  late File _file;
  late BytesBuilder _bytes;

  final int sampleRate;
  final int numChannels;

  /// Append interleaved stereo float samples (range -1.0 to 1.0).
  void writeFrames(List<double> samples) {
    for (final s in samples) {
      final clamped = s.clamp(-1.0, 1.0);
      final intSample = (clamped * 32767).round().clamp(-32768, 32767);
      _bytes.addByte(intSample & 0xFF);
      _bytes.addByte((intSample >> 8) & 0xFF);
    }
  }

  /// Finalize the WAV file and write to disk.
  void close() {
    final data = _bytes.toBytes();
    final fileSize = 44 + data.length;
    final header = BytesBuilder();

    // RIFF header
    header.add('RIFF'.codeUnits);
    header.add(_int32Bytes(fileSize - 8)); // file size - 8
    header.add('WAVE'.codeUnits);

    // fmt chunk
    header.add('fmt '.codeUnits);
    header.add(_int32Bytes(16)); // chunk size
    header.add(_int16Bytes(1)); // PCM format
    header.add(_int16Bytes(numChannels));
    header.add(_int32Bytes(sampleRate));
    header.add(_int32Bytes(sampleRate * numChannels * 2)); // byte rate
    header.add(_int16Bytes(numChannels * 2)); // block align
    header.add(_int16Bytes(16)); // bits per sample

    // data chunk
    header.add('data'.codeUnits);
    header.add(_int32Bytes(data.length));

    header.add(data);

    _file.writeAsBytesSync(header.toBytes());
  }

  static Uint8List _int16Bytes(int value) {
    return Uint8List(2)
      ..[0] = value & 0xFF
      ..[1] = (value >> 8) & 0xFF;
  }

  static Uint8List _int32Bytes(int value) {
    return Uint8List(4)
      ..[0] = value & 0xFF
      ..[1] = (value >> 8) & 0xFF
      ..[2] = (value >> 16) & 0xFF
      ..[3] = (value >> 24) & 0xFF;
  }
}
