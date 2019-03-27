//
//  AKChannelSelectorDSP.cpp
//  AudioKit
//
//  Created by Dean Woodward on 26/03/19.
//  Copyright © 2019 AudioKit. All rights reserved.
//

#import "AKChannelSelectorDSP.hpp"

// "Constructor" function for interop with Swift
// In this case a destructor is not needed, since the DSP object doesn't do any of
// its own heap based allocation.

extern "C" AKDSPRef createChannelSelectorDSP(int channelCount, double sampleRate) {
    AKChannelSelectorDSP *dsp = new AKChannelSelectorDSP();
    dsp->init(channelCount, sampleRate);
    return dsp;
}
