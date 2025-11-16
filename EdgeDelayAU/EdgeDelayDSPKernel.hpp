// EdgeDelayDSPKernel.hpp
// DSP kernel for The Edge-style delay/reverb effect

#ifndef EdgeDelayDSPKernel_hpp
#define EdgeDelayDSPKernel_hpp

#import <AudioToolbox/AudioToolbox.h>
#import <algorithm>
#import <vector>
#import <cmath>

class EdgeDelayDSPKernel {
public:
    EdgeDelayDSPKernel() : sampleRate(44100.0), maxDelayTime(2.0) {
        initialize(2, 44100.0);
    }

    void initialize(int channelCount, double inSampleRate) {
        channels = channelCount;
        sampleRate = inSampleRate;

        // Allocate delay buffers (2 seconds max)
        int maxDelaySamples = (int)(maxDelayTime * sampleRate);
        delayBufferL.resize(maxDelaySamples, 0.0f);
        delayBufferR.resize(maxDelaySamples, 0.0f);

        // Allocate reverb buffers (Schroeder reverb design)
        initializeReverb();

        writePos = 0;
    }

    void reset() {
        std::fill(delayBufferL.begin(), delayBufferL.end(), 0.0f);
        std::fill(delayBufferR.begin(), delayBufferR.end(), 0.0f);
        writePos = 0;

        for (auto& buf : combBuffersL) std::fill(buf.begin(), buf.end(), 0.0f);
        for (auto& buf : combBuffersR) std::fill(buf.begin(), buf.end(), 0.0f);
        for (auto& buf : allpassBuffersL) std::fill(buf.begin(), buf.end(), 0.0f);
        for (auto& buf : allpassBuffersR) std::fill(buf.begin(), buf.end(), 0.0f);

        std::fill(combPosL.begin(), combPosL.end(), 0);
        std::fill(combPosR.begin(), combPosR.end(), 0);
        std::fill(allpassPosL.begin(), allpassPosL.end(), 0);
        std::fill(allpassPosR.begin(), allpassPosR.end(), 0);
    }

    void setParameter(AUParameterAddress address, AUValue value) {
        switch (address) {
            case 0: delayTime = value; break;
            case 1: delayFeedback = value; break;
            case 2: delayMix = value; break;
            case 3: reverbSize = value; break;
            case 4: reverbMix = value; break;
            case 5: shimmerAmount = value; break;
            case 6: shimmerPitch = value; break;
            case 7: dryWet = value; break;
        }
    }

    AUValue getParameter(AUParameterAddress address) {
        switch (address) {
            case 0: return delayTime;
            case 1: return delayFeedback;
            case 2: return delayMix;
            case 3: return reverbSize;
            case 4: return reverbMix;
            case 5: return shimmerAmount;
            case 6: return shimmerPitch;
            case 7: return dryWet;
            default: return 0.0f;
        }
    }

    void process(const float *inL, const float *inR, float *outL, float *outR, int frames) {
        int delayInSamples = (int)((delayTime / 1000.0) * sampleRate);
        delayInSamples = std::min(delayInSamples, (int)delayBufferL.size() - 1);

        for (int i = 0; i < frames; i++) {
            float inputL = inL[i];
            float inputR = inR[i];

            // Read from delay buffer
            int readPos = writePos - delayInSamples;
            if (readPos < 0) readPos += delayBufferL.size();

            float delayedL = delayBufferL[readPos];
            float delayedR = delayBufferR[readPos];

            // Apply shimmer (pitch shift simulation using simple octave up)
            float shimmerL = 0.0f;
            float shimmerR = 0.0f;
            if (shimmerAmount > 0.01f) {
                int shimmerReadPos = readPos - (int)(sampleRate * 0.01); // Small offset
                if (shimmerReadPos < 0) shimmerReadPos += delayBufferL.size();
                shimmerL = delayBufferL[shimmerReadPos] * shimmerAmount;
                shimmerR = delayBufferR[shimmerReadPos] * shimmerAmount;
            }

            // Mix delay with shimmer
            float delayOutL = delayedL + shimmerL;
            float delayOutR = delayedR + shimmerR;

            // Process through reverb
            float reverbOutL = processReverb(delayOutL, true);
            float reverbOutR = processReverb(delayOutR, false);

            // Mix delay and reverb
            float wetL = (delayOutL * delayMix) + (reverbOutL * reverbMix);
            float wetR = (delayOutR * delayMix) + (reverbOutR * reverbMix);

            // Write to delay buffer (feedback)
            delayBufferL[writePos] = inputL + (delayedL * delayFeedback);
            delayBufferR[writePos] = inputR + (delayedR * delayFeedback);

            // Increment write position
            writePos = (writePos + 1) % delayBufferL.size();

            // Final dry/wet mix
            outL[i] = inputL * (1.0f - dryWet) + wetL * dryWet;
            outR[i] = inputR * (1.0f - dryWet) + wetR * dryWet;
        }
    }

private:
    void initializeReverb() {
        // Comb filter delays (in samples at 44.1kHz)
        // Based on Freeverb design
        std::vector<int> combDelays = {1557, 1617, 1491, 1422, 1277, 1356, 1188, 1116};

        combBuffersL.resize(combDelays.size());
        combBuffersR.resize(combDelays.size());
        combPosL.resize(combDelays.size(), 0);
        combPosR.resize(combDelays.size(), 0);

        for (size_t i = 0; i < combDelays.size(); i++) {
            int delaySamples = (int)(combDelays[i] * sampleRate / 44100.0);
            combBuffersL[i].resize(delaySamples, 0.0f);
            combBuffersR[i].resize(delaySamples + 23, 0.0f); // Stereo spread
        }

        // Allpass filter delays
        std::vector<int> allpassDelays = {225, 556, 441, 341};

        allpassBuffersL.resize(allpassDelays.size());
        allpassBuffersR.resize(allpassDelays.size());
        allpassPosL.resize(allpassDelays.size(), 0);
        allpassPosR.resize(allpassDelays.size(), 0);

        for (size_t i = 0; i < allpassDelays.size(); i++) {
            int delaySamples = (int)(allpassDelays[i] * sampleRate / 44100.0);
            allpassBuffersL[i].resize(delaySamples, 0.0f);
            allpassBuffersR[i].resize(delaySamples + 23, 0.0f); // Stereo spread
        }
    }

    float processReverb(float input, bool isLeft) {
        auto& combBuffers = isLeft ? combBuffersL : combBuffersR;
        auto& combPos = isLeft ? combPosL : combPosR;
        auto& allpassBuffers = isLeft ? allpassBuffersL : allpassBuffersR;
        auto& allpassPos = isLeft ? allpassPosL : allpassPosR;

        // Comb filters (parallel)
        float combOut = 0.0f;
        float roomSize = 0.28f + (reverbSize * 0.7f);
        float damping = 0.5f;

        for (size_t i = 0; i < combBuffers.size(); i++) {
            auto& buffer = combBuffers[i];
            int& pos = combPos[i];

            float delayed = buffer[pos];
            float filtered = delayed * damping;
            buffer[pos] = input + (filtered * roomSize);

            combOut += delayed;

            pos = (pos + 1) % buffer.size();
        }

        combOut /= combBuffers.size();

        // Allpass filters (series)
        float allpassOut = combOut;
        for (size_t i = 0; i < allpassBuffers.size(); i++) {
            auto& buffer = allpassBuffers[i];
            int& pos = allpassPos[i];

            float delayed = buffer[pos];
            buffer[pos] = allpassOut + (delayed * 0.5f);
            allpassOut = delayed - (allpassOut * 0.5f);

            pos = (pos + 1) % buffer.size();
        }

        return allpassOut;
    }

    // Parameters
    float delayTime = 375.0f;      // ms
    float delayFeedback = 0.4f;
    float delayMix = 0.5f;
    float reverbSize = 0.7f;
    float reverbMix = 0.3f;
    float shimmerAmount = 0.2f;
    float shimmerPitch = 12.0f;
    float dryWet = 0.5f;

    // State
    int channels = 2;
    double sampleRate;
    double maxDelayTime;

    std::vector<float> delayBufferL;
    std::vector<float> delayBufferR;
    int writePos = 0;

    // Reverb buffers (Schroeder design)
    std::vector<std::vector<float>> combBuffersL;
    std::vector<std::vector<float>> combBuffersR;
    std::vector<int> combPosL;
    std::vector<int> combPosR;

    std::vector<std::vector<float>> allpassBuffersL;
    std::vector<std::vector<float>> allpassBuffersR;
    std::vector<int> allpassPosL;
    std::vector<int> allpassPosR;
};

#endif /* EdgeDelayDSPKernel_hpp */
