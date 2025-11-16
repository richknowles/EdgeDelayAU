// EdgeDelayParameters.swift
// Shared parameter definitions for The Edge-style delay/reverb effect

import Foundation
import AudioToolbox

public enum EdgeDelayParam: AUParameterAddress {
    case delayTime = 0
    case delayFeedback = 1
    case delayMix = 2
    case reverbSize = 3
    case reverbMix = 4
    case shimmerAmount = 5
    case shimmerPitch = 6
    case dryWet = 7
}

public struct EdgeDelayParameterSpecs {
    public static let delayTime = ParameterSpec(
        address: EdgeDelayParam.delayTime.rawValue,
        identifier: "delayTime",
        name: "Delay Time",
        minValue: 10.0,
        maxValue: 2000.0,
        defaultValue: 375.0,  // Dotted eighth at 120 BPM
        unit: .milliseconds
    )

    public static let delayFeedback = ParameterSpec(
        address: EdgeDelayParam.delayFeedback.rawValue,
        identifier: "delayFeedback",
        name: "Feedback",
        minValue: 0.0,
        maxValue: 0.95,
        defaultValue: 0.4,
        unit: .generic
    )

    public static let delayMix = ParameterSpec(
        address: EdgeDelayParam.delayMix.rawValue,
        identifier: "delayMix",
        name: "Delay Mix",
        minValue: 0.0,
        maxValue: 1.0,
        defaultValue: 0.5,
        unit: .generic
    )

    public static let reverbSize = ParameterSpec(
        address: EdgeDelayParam.reverbSize.rawValue,
        identifier: "reverbSize",
        name: "Reverb Size",
        minValue: 0.0,
        maxValue: 1.0,
        defaultValue: 0.7,
        unit: .generic
    )

    public static let reverbMix = ParameterSpec(
        address: EdgeDelayParam.reverbMix.rawValue,
        identifier: "reverbMix",
        name: "Reverb Mix",
        minValue: 0.0,
        maxValue: 1.0,
        defaultValue: 0.3,
        unit: .generic
    )

    public static let shimmerAmount = ParameterSpec(
        address: EdgeDelayParam.shimmerAmount.rawValue,
        identifier: "shimmerAmount",
        name: "Shimmer",
        minValue: 0.0,
        maxValue: 1.0,
        defaultValue: 0.2,
        unit: .generic
    )

    public static let shimmerPitch = ParameterSpec(
        address: EdgeDelayParam.shimmerPitch.rawValue,
        identifier: "shimmerPitch",
        name: "Shimmer Pitch",
        minValue: -12.0,
        maxValue: 12.0,
        defaultValue: 12.0,  // One octave up
        unit: .relativeSemiTones
    )

    public static let dryWet = ParameterSpec(
        address: EdgeDelayParam.dryWet.rawValue,
        identifier: "dryWet",
        name: "Dry/Wet",
        minValue: 0.0,
        maxValue: 1.0,
        defaultValue: 0.5,
        unit: .generic
    )

    public static let all: [ParameterSpec] = [
        delayTime, delayFeedback, delayMix,
        reverbSize, reverbMix,
        shimmerAmount, shimmerPitch,
        dryWet
    ]
}

public struct ParameterSpec {
    let address: AUParameterAddress
    let identifier: String
    let name: String
    let minValue: Float
    let maxValue: Float
    let defaultValue: Float
    let unit: AudioUnitParameterUnit

    public func createParameter() -> AUParameter {
        return AUParameterTree.createParameter(
            withIdentifier: identifier,
            name: name,
            address: address,
            min: minValue,
            max: maxValue,
            unit: unit,
            unitName: nil,
            flags: [.flag_IsReadable, .flag_IsWritable],
            valueStrings: nil,
            dependentParameters: nil
        )
    }
}
