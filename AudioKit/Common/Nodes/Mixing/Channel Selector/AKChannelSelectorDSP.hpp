//
//  AKChannelSelectorDSP.hpp
//  AudioKit
//
//  Created by Dean Woodward on 26/03/19.
//  Copyright © 2019 AudioKit. All rights reserved.
//

#pragma once

#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(AUParameterAddress, AKChannelSelectorParameter) {
    AKChannelSelectorParameterChannelSource,
    AKChannelSelectorParameterRampDuration
};

#import "AKLinearParameterRamp.hpp"  // have to put this here to get it included in umbrella header

#ifndef __cplusplus

AKDSPRef createChannelSelectorDSP(int channelCount, double sampleRate);

#else

#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>

struct AKChannelSelectorDSP : AKDSPBase {

    private:
        AKLinearParameterRamp channelSourceRamp;

    public:

    AKChannelSelectorDSP() {
        channelSourceRamp.setTarget(0.0, true);
        channelSourceRamp.setDurationInSamples(10000);
    }

    /** Uses the ParameterAddress as a key */
    void setParameter(AUParameterAddress address, float value, bool immediate) override {
        switch (address) {
            case AKChannelSelectorParameterChannelSource:
                channelSourceRamp.setTarget(value, immediate);
                break;
            case AKChannelSelectorParameterRampDuration:
                channelSourceRamp.setRampDuration(value, sampleRate);
                break;
        }
    }

    /** Uses the ParameterAddress as a key */
    float getParameter(AUParameterAddress address) override {
        switch (address) {
            case AKChannelSelectorParameterChannelSource:
                return channelSourceRamp.getTarget();
                break;
            case AKChannelSelectorParameterRampDuration:
                return channelSourceRamp.getRampDuration(sampleRate);
                break;
        }
        return 0;
    }

    void process(AUAudioFrameCount frameCount, AUAudioFrameCount bufferOffset) override {

        // For each sample.
        for (int frameIndex = 0; frameIndex < frameCount; ++frameIndex) {
            int frameOffset = int(frameIndex + bufferOffset);
            // do ramping every 8 samples
            if ((frameOffset & 0x7) == 0) {
                channelSourceRamp.advanceTo(now + frameOffset);
            }
            float source = channelSourceRamp.getValue();
            source = (source + 1.0) / 2.0; // Scale our channel source from -1...1 to 0...1

            if (!isStarted) {
                outBufferListPtr->mBuffers[0] = inBufferListPtr->mBuffers[0];
                outBufferListPtr->mBuffers[1] = inBufferListPtr->mBuffers[1];
                return;
            }

            float *tmpin[2];
            float *tmpout[2];
            for (int channel = 0; channel < channelCount; ++channel) {
                float *in  = (float *)inBufferListPtr->mBuffers[channel].mData  + frameOffset;
                float *out = (float *)outBufferListPtr->mBuffers[channel].mData + frameOffset;
                if (channel < 2) {
                    tmpin[channel] = in;
                    tmpout[channel] = out;
                }
            }
            *tmpout[0] = *tmpin[0] * (1.0f - source) + *tmpin[1] * source;
            *tmpout[1] = *tmpin[0] * (1.0f - source) + *tmpin[1] * source;
        }
    }
};

#endif

