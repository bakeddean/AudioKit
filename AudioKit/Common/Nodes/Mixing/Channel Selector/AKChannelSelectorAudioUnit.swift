//
//  AKChannelSelectorAudioUnit.swift
//  AudioKit
//
//  Created by Dean Woodward on 26/03/19.
//  Copyright © 2019 AudioKit. All rights reserved.
//

import AVFoundation

public class AKChannelSelectorAudioUnit: AKAudioUnitBase {

    func setParameter(_ address: AKChannelSelectorParameter, value: Double) {
        setParameterWithAddress(address.rawValue, value: Float(value))
    }

    func setParameterImmediately(_ address: AKChannelSelectorParameter, value: Double) {
        setParameterImmediatelyWithAddress(address.rawValue, value: Float(value))
    }

    var channelSource: Double = 0.0 {
        didSet { setParameter(.channelSource, value: channelSource) }
    }

    var rampDuration: Double = 0.0 {
        didSet { setParameter(.rampDuration, value: rampDuration) }
    }

    public override func initDSP(withSampleRate sampleRate: Double,
                                 channelCount count: AVAudioChannelCount) -> AKDSPRef {
        return createChannelSelectorDSP(Int32(count), sampleRate)
    }

    public override init(componentDescription: AudioComponentDescription,
                         options: AudioComponentInstantiationOptions = []) throws {
        try super.init(componentDescription: componentDescription, options: options)
        let channel = AUParameter(
            identifier: "channelSource",
            name: "Channel Source. A value of -1 selects left only," +
            " a value of 1 right only, and a value of 0 both left & right.",
            address: 0,
            range: -1.0...1.0,
            unit: .generic,
            flags: .default)
        setParameterTree(AUParameterTree(children: [channel]))
        channel.value = 0.0
    }

    public override var canProcessInPlace: Bool { return true }

}
