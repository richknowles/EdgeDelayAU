// EdgeDelayDSPKernel.mm
// C bridge to C++ DSP kernel

#import "EdgeDelayDSPKernel.hpp"
#import <AudioToolbox/AudioToolbox.h>

extern "C" {

void* EdgeDelayDSPKernel_new() {
    return new EdgeDelayDSPKernel();
}

void EdgeDelayDSPKernel_delete(void* kernel) {
    delete static_cast<EdgeDelayDSPKernel*>(kernel);
}

void EdgeDelayDSPKernel_initialize(void* kernel, int channels, double sampleRate) {
    static_cast<EdgeDelayDSPKernel*>(kernel)->initialize(channels, sampleRate);
}

void EdgeDelayDSPKernel_reset(void* kernel) {
    static_cast<EdgeDelayDSPKernel*>(kernel)->reset();
}

void EdgeDelayDSPKernel_setParameter(void* kernel, AUParameterAddress address, AUValue value) {
    static_cast<EdgeDelayDSPKernel*>(kernel)->setParameter(address, value);
}

AUValue EdgeDelayDSPKernel_getParameter(void* kernel, AUParameterAddress address) {
    return static_cast<EdgeDelayDSPKernel*>(kernel)->getParameter(address);
}

void EdgeDelayDSPKernel_process(void* kernel,
                                const float* inL,
                                const float* inR,
                                float* outL,
                                float* outR,
                                int frames) {
    static_cast<EdgeDelayDSPKernel*>(kernel)->process(inL, inR, outL, outR, frames);
}

} // extern "C"
