#include "recorder.h"
#include <cstring>
#include <cmath>
#include <algorithm>

namespace opensynth {

// ── WAV Writer ────────────────────────────────────────────────────────────────

WavWriter::WavWriter() = default;
WavWriter::~WavWriter() { close(); }

static void writeU16(std::FILE* f, uint16_t v) {
    uint8_t b[2] = {static_cast<uint8_t>(v), static_cast<uint8_t>(v >> 8)};
    std::fwrite(b, 1, 2, f);
}

static void writeU32(std::FILE* f, uint32_t v) {
    uint8_t b[4] = {static_cast<uint8_t>(v), static_cast<uint8_t>(v >> 8),
                    static_cast<uint8_t>(v >> 16), static_cast<uint8_t>(v >> 24)};
    std::fwrite(b, 1, 4, f);
}

bool WavWriter::open(const char* path, int sampleRate, int channels, WavBitDepth bits) {
    close();
    file_ = std::fopen(path, "wb");
    if (!file_) return false;

    sampleRate_ = sampleRate;
    channels_ = channels;
    bitDepth_ = bits;
    framesWritten_ = 0;

    writeHeader();
    return true;
}

void WavWriter::writeHeader() {
    if (!file_) return;

    int bits = static_cast<int>(bitDepth_);
    int bytesPerSample = bits / 8;
    int blockAlign = channels_ * bytesPerSample;
    int byteRate = sampleRate_ * blockAlign;

    // RIFF header
    std::fwrite("RIFF", 1, 4, file_);
    writeU32(file_, 0); // file size placeholder
    std::fwrite("WAVE", 1, 4, file_);

    // fmt chunk
    std::fwrite("fmt ", 1, 4, file_);
    writeU32(file_, 16); // fmt chunk size
    writeU16(file_, bits == 32 ? 3 : 1); // 1 = PCM, 3 = IEEE float
    writeU16(file_, static_cast<uint16_t>(channels_));
    writeU32(file_, static_cast<uint32_t>(sampleRate_));
    writeU32(file_, static_cast<uint32_t>(byteRate));
    writeU16(file_, static_cast<uint16_t>(blockAlign));
    writeU16(file_, static_cast<uint16_t>(bits));

    // data chunk
    std::fwrite("data", 1, 4, file_);
    dataChunkPos_ = static_cast<uint32_t>(std::ftell(file_));
    writeU32(file_, 0); // data size placeholder
}

void WavWriter::finalizeHeader() {
    if (!file_) return;

    // Update RIFF chunk size
    std::fseek(file_, 4, SEEK_SET);
    uint32_t fileSize = static_cast<uint32_t>(std::ftell(file_)) - 8;
    writeU32(file_, fileSize);

    // Update data chunk size
    std::fseek(file_, dataChunkPos_, SEEK_SET);
    int bytesPerSample = static_cast<int>(bitDepth_) / 8;
    uint32_t dataSize = framesWritten_ * channels_ * bytesPerSample;
    writeU32(file_, dataSize);
}

void WavWriter::close() {
    if (file_) {
        finalizeHeader();
        std::fclose(file_);
        file_ = nullptr;
    }
}

bool WavWriter::writeInterleaved(const float* samples, uint32_t numFrames) {
    if (!file_) return false;

    int bits = static_cast<int>(bitDepth_);
    int totalSamples = numFrames * channels_;

    if (bits == 16) {
        std::vector<int16_t> buf(totalSamples);
        for (int i = 0; i < totalSamples; ++i) {
            float s = std::clamp(samples[i], -1.0f, 1.0f);
            buf[i] = static_cast<int16_t>(s * 32767.0f);
        }
        std::fwrite(buf.data(), sizeof(int16_t), totalSamples, file_);
    } else if (bits == 24) {
        std::vector<uint8_t> buf(totalSamples * 3);
        for (int i = 0; i < totalSamples; ++i) {
            float s = std::clamp(samples[i], -1.0f, 1.0f);
            int32_t v = static_cast<int32_t>(s * 8388607.0f);
            buf[i * 3] = static_cast<uint8_t>(v);
            buf[i * 3 + 1] = static_cast<uint8_t>(v >> 8);
            buf[i * 3 + 2] = static_cast<uint8_t>(v >> 16);
        }
        std::fwrite(buf.data(), 1, totalSamples * 3, file_);
    } else if (bits == 32) {
        std::fwrite(samples, sizeof(float), totalSamples, file_);
    }

    framesWritten_ += numFrames;
    return true;
}

// ── Recorder ──────────────────────────────────────────────────────────────────

Recorder::Recorder() = default;
Recorder::~Recorder() = default;

void Recorder::startRecording(const char* path) {
    if (state_.load() == TransportState::RECORDING) return;
    if (writer_.open(path, sampleRate_, 2, bitDepth_)) {
        recordedFrames_.store(0);
        state_.store(TransportState::RECORDING);
    }
}

void Recorder::stop() {
    if (state_.load() == TransportState::STOPPED) return;
    state_.store(TransportState::STOPPED);
    writer_.close();
}

void Recorder::process(const float* left, const float* right, uint32_t numFrames) {
    if (state_.load() != TransportState::RECORDING) return;

    std::lock_guard<std::mutex> lock(bufMutex_);
    interleaveBuf_.resize(numFrames * 2);
    for (uint32_t i = 0; i < numFrames; ++i) {
        interleaveBuf_[i * 2] = left[i];
        interleaveBuf_[i * 2 + 1] = right[i];
    }
    writer_.writeInterleaved(interleaveBuf_.data(), numFrames);
    recordedFrames_.fetch_add(numFrames);
}

} // namespace opensynth
