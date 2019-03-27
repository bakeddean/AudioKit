//
//  AKChannelSelector.swift
//  AudioKit
//
//  Created by Dean Woodward on 26/03/19.
//  Copyright © 2019 AudioKit. All rights reserved.
//


/**
AKChannelSelector

The selcted input channel(s), as governed by the channelSource setting, are routed in equal part
to the left and right output channels.

Also useful if you have an input hardware device that only sends audio on a single channel,
and you would like to duplicate that audio on the second channel.

- **ChannelSource**: -1 **Input**: [L, R] **Output**: [L, L]
- **ChannelSource**: 0 **Input**: [L, R] **Output**: [(L+R)/2, (L+R)/2]
- **ChannelSource**: 1 **Input**: [L, R] **Output**: [R, R]
*/
open class AKChannelSelector: AKNode, AKToggleable, AKComponent, AKInput {

    public typealias AKAudioUnitType = AKChannelSelectorAudioUnit
    
    /// Four letter unique description of the node
    public static let ComponentDescription = AudioComponentDescription(effect: "chmx")

    // MARK: - Properties

    private var internalAU: AKAudioUnitType?
    private var token: AUParameterObserverToken?

    fileprivate var channelSourceParameter: AUParameter?

    /// Ramp Duration represents the speed at which parameters are allowed to change
    @objc open dynamic var rampDuration: Double = AKSettings.rampDuration {
        willSet {
            internalAU?.rampDuration = newValue
        }
    }

    /// Channel Source. A value of -1 selects left only, a value of 1 right only, and a value of 0 both left & right.
    @objc open dynamic var channelSource: Double = 0.0 {
        willSet {
            guard channelSource != newValue else { return }
            if internalAU?.isSetUp == true {
                if let existingToken = token {
                    channelSourceParameter?.setValue(Float(newValue), originator: existingToken)
                    return
                }
            }
            internalAU?.setParameterImmediately(.channelSource, value: newValue)
        }
    }

    /// Tells whether the node is processing (ie. started, playing, or active)
    @objc open dynamic var isStarted: Bool {
        return self.internalAU?.isPlaying ?? false
    }

    // MARK: - Initialization

    /// Initialize this channel mixer
    ///
    /// - Parameters:
    ///   - input: Input node to process.
    ///   - channelSource: A value of -1 selects left only, a value of 1 right only, and a value of 0 both left & right.
    ///
    @objc public init(_ input: AKNode? = nil, channelSource: Double = 0.0) {
        self.channelSource = channelSource

        _Self.register()

        super.init()
        AVAudioUnit._instantiate(with: _Self.ComponentDescription) { [weak self] avAudioUnit in
            guard let strongSelf = self else {
                AKLog("Error: self is nil")
                return
            }
            strongSelf.avAudioUnit = avAudioUnit
            strongSelf.avAudioNode = avAudioUnit
            strongSelf.internalAU = avAudioUnit.auAudioUnit as? AKAudioUnitType

            input?.connect(to: strongSelf)
        }

        guard let tree = internalAU?.parameterTree else {
            AKLog("Parameter Tree Failed")
            return
        }

        self.channelSourceParameter = tree["channelSource"]

        self.token = tree.token(byAddingParameterObserver: { [weak self] _, _ in

            guard let _ = self else {
                AKLog("Unable to create strong reference to self")
                return
            } // Replace _ with strongSelf if needed
            DispatchQueue.main.async {
                // This node does not change its own values so we won't add any
                // value observing, but if you need to, this is where that goes.
            }
        })
        internalAU?.setParameterImmediately(.channelSource, value: Double(channelSource))
    }

    // MARK: - Control

    /// Function to start, play, or activate the node, all do the same thing
    @objc open func start() {
        internalAU?.start()
    }

    /// Function to stop or bypass the node, both are equivalent
    @objc open func stop() {
        internalAU?.stop()
    }

}
