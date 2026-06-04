#pragma once
#include <juce_gui_basics/juce_gui_basics.h>
#include <juce_graphics/juce_graphics.h>
#include <atomic>
#include <cstring>

namespace opensynth {

/// Real-time oscilloscope / waveform display for the synth output.
/// Reads from a lock-free circular buffer written by the audio thread.
class WaveformDisplay : public juce::Component,
                        private juce::Timer {
public:
    static constexpr int kRingSize = 4096;  // Must be power of 2

    WaveformDisplay()
    {
        setOpaque(false);
        writePos_.store(0, std::memory_order_relaxed);
        std::memset(ringL_, 0, sizeof(ringL_));
        std::memset(ringR_, 0, sizeof(ringR_));
        startTimerHz(60);  // 60 fps repaint
    }

    ~WaveformDisplay() override { stopTimer(); }

    /// Called from audio thread to push a stereo block into the ring buffer.
    void pushSamples(const float* left, const float* right, int numSamples) noexcept
    {
        int pos = writePos_.load(std::memory_order_relaxed);
        for (int i = 0; i < numSamples; ++i) {
            ringL_[pos & (kRingSize - 1)] = left[i];
            ringR_[pos & (kRingSize - 1)] = right[i];
            ++pos;
        }
        writePos_.store(pos, std::memory_order_release);
    }

    void paint(juce::Graphics& g) override
    {
        auto bounds = getLocalBounds().toFloat();
        float w = bounds.getWidth();
        float h = bounds.getHeight();

        // Background
        g.setColour(juce::Colour(0xFF1A0029));
        g.fillRoundedRectangle(bounds, 8.0f);

        // Grid lines
        g.setColour(juce::Colour(0x158F00FF));
        // Horizontal center line
        float cy = h * 0.5f;
        g.drawHorizontalLine(static_cast<int>(cy), 4.0f, w - 4.0f);
        // Quarter lines
        g.drawHorizontalLine(static_cast<int>(h * 0.25f), 4.0f, w - 4.0f);
        g.drawHorizontalLine(static_cast<int>(h * 0.75f), 4.0f, w - 4.0f);
        // Vertical lines
        for (int i = 1; i < 8; ++i) {
            float x = w * static_cast<float>(i) / 8.0f;
            g.drawVerticalLine(static_cast<int>(x), 4.0f, h - 4.0f);
        }

        // Snapshot the ring buffer for drawing
        int writePos = writePos_.load(std::memory_order_acquire);
        int displaySamples = std::min(static_cast<int>(w), kRingSize / 2);
        int startIdx = writePos - displaySamples;

        // Draw waveform — left channel (cyan)
        g.setColour(juce::Colour(0xFF00F0FF));
        {
            juce::Path pathL;
            bool first = true;
            for (int i = 0; i < displaySamples; ++i) {
                float sample = ringL_[(startIdx + i) & (kRingSize - 1)];
                float x = w * static_cast<float>(i) / static_cast<float>(displaySamples);
                float y = cy - sample * (h * 0.4f);
                if (first) { pathL.startNewSubPath(x, y); first = false; }
                else pathL.lineTo(x, y);
            }
            g.strokePath(pathL, juce::PathStrokeType(1.5f));
        }

        // Draw waveform — right channel (hot pink, slightly transparent)
        g.setColour(juce::Colour(0xBBFF7EDB));
        {
            juce::Path pathR;
            bool first = true;
            for (int i = 0; i < displaySamples; ++i) {
                float sample = ringR_[(startIdx + i) & (kRingSize - 1)];
                float x = w * static_cast<float>(i) / static_cast<float>(displaySamples);
                float y = cy - sample * (h * 0.4f);
                if (first) { pathR.startNewSubPath(x, y); first = false; }
                else pathR.lineTo(x, y);
            }
            g.strokePath(pathR, juce::PathStrokeType(1.0f));
        }

        // Glow effect — redraw left channel with thick translucent stroke
        g.setColour(juce::Colour(0x30FF00FF));
        {
            juce::Path pathGlow;
            bool first = true;
            for (int i = 0; i < displaySamples; ++i) {
                float sample = ringL_[(startIdx + i) & (kRingSize - 1)];
                float x = w * static_cast<float>(i) / static_cast<float>(displaySamples);
                float y = cy - sample * (h * 0.4f);
                if (first) { pathGlow.startNewSubPath(x, y); first = false; }
                else pathGlow.lineTo(x, y);
            }
            g.strokePath(pathGlow, juce::PathStrokeType(4.0f));
        }

        // Title
        g.setColour(juce::Colour(0xFF00F0FF));
        g.setFont(juce::Font(juce::FontOptions(10.0f)));
        g.drawText("OSC", 6, 2, 30, 14, juce::Justification::left);
    }

    void resized() override {}

private:
    void timerCallback() override { repaint(); }

    float ringL_[kRingSize];
    float ringR_[kRingSize];
    std::atomic<int> writePos_;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(WaveformDisplay)
};

} // namespace opensynth
