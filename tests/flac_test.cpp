#include <juce_audio_formats/juce_audio_formats.h>
#include <iostream>

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: flac_test <file.flac>\n";
        return 1;
    }
    juce::AudioFormatManager fmt;
    fmt.registerBasicFormats();
    juce::File f(argv[1]);
    auto* reader = fmt.createReaderFor(f);
    if (!reader) {
        std::cerr << "FAILED: Could not create reader for " << argv[1] << "\n";
        return 1;
    }
    std::cout << "Format: " << reader->getFormatName() << "\n";
    std::cout << "Channels: " << reader->numChannels << "\n";
    std::cout << "SampleRate: " << reader->sampleRate << "\n";
    std::cout << "Length: " << reader->lengthInSamples << "\n";
    
    juce::AudioBuffer<float> buf(2, 256);
    buf.clear();
    reader->read(buf.getArrayOfWritePointers(), 2, 0, 256);
    float maxAbs = 0.0f;
    for (int ch = 0; ch < 2; ++ch) {
        auto* data = buf.getReadPointer(ch);
        for (int i = 0; i < 256; ++i)
            maxAbs = std::max(maxAbs, std::fabs(data[i]));
    }
    std::cout << "First 256 samples maxAbs: " << maxAbs << "\n";
    delete reader;
    return 0;
}
