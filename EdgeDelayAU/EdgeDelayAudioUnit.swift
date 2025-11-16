// EdgeDelayAudioUnit.swift
// The main AUAudioUnit subclass for The Edge-style delay/reverb effect

import AudioToolbox
import AVFoundation
import CoreAudioKit

public class EdgeDelayAudioUnit: AUAudioUnit {
    private var kernel: EdgeDelayDSPKernelAdapter!
    private var parameterTree: AUParameterTree!

    private var inputBus: AUAudioUnitBus!
    private var outputBus: AUAudioUnitBus!
    private var _inputBusses: AUAudioUnitBusArray!
    private var _outputBusses: AUAudioUnitBusArray!

    public override var inputBusses: AUAudioUnitBusArray {
        return _inputBusses
    }

    public override var outputBusses: AUAudioUnitBusArray {
        return _outputBusses
    }

    public override init(componentDescription: AudioComponentDescription,
                         options: AudioComponentInstantiationOptions = []) throws {
        try super.init(componentDescription: componentDescription, options: options)

        // Create the DSP kernel
        kernel = EdgeDelayDSPKernelAdapter()

        // Create parameter tree
        let params = EdgeDelayParameterSpecs.all.map { $0.createParameter() }
        parameterTree = AUParameterTree.createTree(withChildren: params)

        // Set up parameter callbacks
        parameterTree.implementorValueObserver = { [weak self] param, value in
            self?.kernel.setParameter(param.address, value: value)
        }

        parameterTree.implementorValueProvider = { [weak self] param in
            return self?.kernel.getParameter(param.address) ?? 0.0
        }

        // Set default values
        for spec in EdgeDelayParameterSpecs.all {
            if let param = parameterTree.parameter(withAddress: spec.address) {
                param.value = spec.defaultValue
            }
        }

        // Create busses
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        inputBus = try AUAudioUnitBus(format: format)
        outputBus = try AUAudioUnitBus(format: format)

        _inputBusses = AUAudioUnitBusArray(audioUnit: self, busType: .input, busses: [inputBus])
        _outputBusses = AUAudioUnitBusArray(audioUnit: self, busType: .output, busses: [outputBus])

        self.maximumFramesToRender = 512
    }

    public override var parameterTree: AUParameterTree? {
        get { return self.parameterTree }
        set { /* Read-only */ }
    }

    public override func allocateRenderResources() throws {
        try super.allocateRenderResources()

        let format = outputBus.format
        kernel.initialize(Int32(format.channelCount), sampleRate: format.sampleRate)
    }

    public override func deallocateRenderResources() {
        super.deallocateRenderResources()
        kernel.reset()
    }

    public override var internalRenderBlock: AUInternalRenderBlock {
        return { [weak self] (
            actionFlags,
            timestamp,
            frameCount,
            outputBusNumber,
            outputData,
            realtimeEventListHead,
            pullInputBlock
        ) in
            guard let self = self else { return kAudioUnitErr_NoConnection }

            // Pull input
            var pullFlags: AudioUnitRenderActionFlags = []
            var inputData = AudioBufferList()
            let status = pullInputBlock?(&pullFlags, timestamp, frameCount, 0, &inputData)

            if status != noErr {
                return status ?? kAudioUnitErr_NoConnection
            }

            // Get buffer pointers
            let inL = UnsafeBufferPointer<Float>(
                start: inputData.mBuffers.mData?.assumingMemoryBound(to: Float.self),
                count: Int(frameCount)
            )

            let inR = UnsafeBufferPointer<Float>(
                start: inputData.mBuffers.mData?.advanced(by: MemoryLayout<Float>.stride * Int(frameCount)).assumingMemoryBound(to: Float.self),
                count: Int(frameCount)
            )

            let outL = UnsafeMutableBufferPointer<Float>(
                start: outputData.pointee.mBuffers.mData?.assumingMemoryBound(to: Float.self),
                count: Int(frameCount)
            )

            let outR = UnsafeMutableBufferPointer<Float>(
                start: outputData.pointee.mBuffers.mData?.advanced(by: MemoryLayout<Float>.stride * Int(frameCount)).assumingMemoryBound(to: Float.self),
                count: Int(frameCount)
            )

            // Process audio
            self.kernel.process(
                inL.baseAddress,
                inR: inR.baseAddress,
                outL: outL.baseAddress,
                outR: outR.baseAddress,
                frames: Int32(frameCount)
            )

            return noErr
        }
    }

    public override var canProcessInPlace: Bool {
        return false
    }
}

// C++ Bridge adapter
private class EdgeDelayDSPKernelAdapter {
    private var kernelPtr: UnsafeMutableRawPointer

    init() {
        kernelPtr = EdgeDelayDSPKernel_new()
    }

    deinit {
        EdgeDelayDSPKernel_delete(kernelPtr)
    }

    func initialize(_ channels: Int32, sampleRate: Double) {
        EdgeDelayDSPKernel_initialize(kernelPtr, channels, sampleRate)
    }

    func reset() {
        EdgeDelayDSPKernel_reset(kernelPtr)
    }

    func setParameter(_ address: AUParameterAddress, value: AUValue) {
        EdgeDelayDSPKernel_setParameter(kernelPtr, address, value)
    }

    func getParameter(_ address: AUParameterAddress) -> AUValue {
        return EdgeDelayDSPKernel_getParameter(kernelPtr, address)
    }

    func process(_ inL: UnsafePointer<Float>?,
                 inR: UnsafePointer<Float>?,
                 outL: UnsafeMutablePointer<Float>?,
                 outR: UnsafeMutablePointer<Float>?,
                 frames: Int32) {
        EdgeDelayDSPKernel_process(kernelPtr, inL, inR, outL, outR, frames)
    }
}

// C bridge functions (implementation in bridging file)
@_silgen_name("EdgeDelayDSPKernel_new")
private func EdgeDelayDSPKernel_new() -> UnsafeMutableRawPointer

@_silgen_name("EdgeDelayDSPKernel_delete")
private func EdgeDelayDSPKernel_delete(_ kernel: UnsafeMutableRawPointer)

@_silgen_name("EdgeDelayDSPKernel_initialize")
private func EdgeDelayDSPKernel_initialize(_ kernel: UnsafeMutableRawPointer, _ channels: Int32, _ sampleRate: Double)

@_silgen_name("EdgeDelayDSPKernel_reset")
private func EdgeDelayDSPKernel_reset(_ kernel: UnsafeMutableRawPointer)

@_silgen_name("EdgeDelayDSPKernel_setParameter")
private func EdgeDelayDSPKernel_setParameter(_ kernel: UnsafeMutableRawPointer, _ address: AUParameterAddress, _ value: AUValue)

@_silgen_name("EdgeDelayDSPKernel_getParameter")
private func EdgeDelayDSPKernel_getParameter(_ kernel: UnsafeMutableRawPointer, _ address: AUParameterAddress) -> AUValue

@_silgen_name("EdgeDelayDSPKernel_process")
private func EdgeDelayDSPKernel_process(_ kernel: UnsafeMutableRawPointer,
                                        _ inL: UnsafePointer<Float>?,
                                        _ inR: UnsafePointer<Float>?,
                                        _ outL: UnsafeMutablePointer<Float>?,
                                        _ outR: UnsafeMutablePointer<Float>?,
                                        _ frames: Int32)
