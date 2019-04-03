//
//  AKDevice.swift
//  AudioKit
//
//  Created by Stéphane Peter, revision history on Github.
//  Copyright © 2018 AudioKit. All rights reserved.
//

#if os(macOS)
public typealias DeviceID = AudioDeviceID
#else
public typealias DeviceID = String
#endif

/// Wrapper for audio device selection
open class AKDevice: NSObject {
    /// The human-readable name for the device.
    open var name: String

    // Make these public let?
    open var nInputChannels: Int?
    open var nOutputChannels: Int?

    /// The device identifier.
    open fileprivate(set) var deviceID: DeviceID

    #if !os(macOS)
    var portDescription: AVAudioSessionPortDescription
    var dataSource: AVAudioSessionDataSourceDescription?
    open var dataSourceName: String?
    // port type
    #endif

    // MARK: - macOS

    #if os(macOS)
    /// Initialize the device (macOS)
    ///
    /// - Parameters:
    ///   - name: The human-readable name for the device.
    ///   - deviceID: The device identifier.
    public init(name: String, deviceID: DeviceID) {
        self.name = name
        self.deviceID = deviceID
        super.init()
    }
    #endif

    // MARK: - iOS, tvOS, watchOS

    #if !os(macOS)

    /// Initialize the device (iOS, tvOS, watchOS)
    ///
    /// - Parameters:
    ///   - portDescription: A port description object that describes a single
    /// input or output port associated with an audio route.
    ///   - dataSource:
    public init(port: AVAudioSessionPortDescription, dataSource: AVAudioSessionDataSourceDescription? = nil) {
        name = port.portName

        deviceID = port.uid

        // Get input/output
        if let channels = port.channels {
            nInputChannels = channels.count
            nOutputChannels = channels.count
        }
        portDescription = port
        // portType AVAudioSession.Port
        print(port.portType)

        // Check if given a dataSource - if not and portDescrition has one, default to the selected
        if dataSource != nil {
            self.dataSource = dataSource
            dataSourceName = dataSource?.dataSourceName
        } else {
            self.dataSource = port.selectedDataSource
            dataSourceName = port.selectedDataSource?.dataSourceName
        }
    }

    /// Initialize the device (iOS, tvOS, watchOS)
    ///
    /// - Parameters:
    ///   - portName: The name of a AVAudioSessionPortDescription.
    ///   - dataSourceName: The name of a AVAudioSessionDataSourceDescription.
    convenience init?(portName: String, dataSourceName: String? = nil) {
        let availableInputs = AVAudioSession.sharedInstance().availableInputs

        // Make sure the portName parameter is valid.
        guard let portDescription = (availableInputs?.filter { $0.portName == portName} )?.first else {
            return nil
        }

        // If no dataSourceName, initialize an AKDevice with just the portDescription.
        guard let dataSource = dataSourceName, !dataSource.isEmpty else {
            self.init(port: portDescription)
            return
        }

        // Else, make sure the dataSourceName parameter is valid.
        guard let dataSourceDescription = (portDescription.dataSources?.filter { $0.dataSourceName == dataSource })?.first else {
            return nil
        }
        self.init(port: portDescription, dataSource: dataSourceDescription)
    }

    // Factory method to return an array of AKDevices from a AVAudioSessionPortDescription's.
    static func devicesFrom(port: AVAudioSessionPortDescription) -> [AKDevice] {
        guard let dataSources = port.dataSources, !dataSources.isEmpty else {
            return [AKDevice(port: port)]
        }
        return dataSources.map { AKDevice(port: port, dataSource: $0) }
    }

    #endif

    // MARK: - Shared

    /// Initialize the device (macOS, iOS, tvOS, watchOS)
    ///
    /// - Parameters:
    ///   - ezAudioDevice: A EZAudioDevice object.
    public convenience init(ezAudioDevice: EZAudioDevice) {
        #if os(macOS)
        self.init(name: ezAudioDevice.name, deviceID: ezAudioDevice.deviceID)
        nInputChannels = ezAudioDevice.inputChannelCount
        nOutputChannels = ezAudioDevice.outputChannelCount
        #else
        self.init(port: ezAudioDevice.port, dataSource: ezAudioDevice.dataSource)
        #endif
    }

    /// Printable device description
    override open var description: String {
        #if os(macOS)
            return "<Device: \(name) (\(deviceID))>"
        #else
            return "\(name) \(dataSourceName ?? "")"
        #endif
    }

    // Fix this? just use deviceID?
    override open func isEqual(_ object: Any?) -> Bool {
        if let object = object as? AKDevice {
            #if os(macOS)
            return self.name == object.name && self.deviceID == object.deviceID
            #else
            return self.deviceID == object.deviceID && self.dataSourceName == object.dataSourceName
            #endif
        }
        return false
    }

}
