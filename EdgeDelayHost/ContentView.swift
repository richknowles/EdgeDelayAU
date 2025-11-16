// ContentView.swift
// Main view for testing The Edge Delay AU3 plugin

import SwiftUI
import AVFoundation
import CoreAudioKit

struct ContentView: View {
    @StateObject private var audioEngine = AudioEngineManager()
    @State private var showingAudioUnit = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title
                Text("The Edge Delay")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)

                Text("AU3 Plugin Host")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Spacer()

                // Status
                VStack(spacing: 12) {
                    StatusRow(title: "Audio Engine", status: audioEngine.isRunning ? "Running" : "Stopped")
                    StatusRow(title: "Plugin", status: audioEngine.audioUnitLoaded ? "Loaded" : "Not Loaded")
                    StatusRow(title: "Audio Input", status: audioEngine.inputAvailable ? "Available" : "Not Available")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                Spacer()

                // Controls
                VStack(spacing: 16) {
                    Button(action: {
                        audioEngine.toggleEngine()
                    }) {
                        HStack {
                            Image(systemName: audioEngine.isRunning ? "stop.circle.fill" : "play.circle.fill")
                                .font(.title2)
                            Text(audioEngine.isRunning ? "Stop Audio" : "Start Audio")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(audioEngine.isRunning ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    Button(action: {
                        showingAudioUnit = true
                    }) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .font(.title2)
                            Text("Open Plugin Controls")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!audioEngine.audioUnitLoaded)
                }
                .padding(.horizontal)

                Spacer()

                // Instructions
                Text("Connect your guitar or audio source and tap 'Start Audio' to begin processing through The Edge Delay effect.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Edge Delay Host")
        }
        .sheet(isPresented: $showingAudioUnit) {
            if let viewController = audioEngine.audioUnitViewController {
                AudioUnitViewControllerRepresentable(viewController: viewController)
            } else {
                Text("Failed to load plugin UI")
            }
        }
    }
}

struct StatusRow: View {
    let title: String
    let status: String

    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            Spacer()
            Text(status)
                .foregroundColor(status.contains("Running") || status.contains("Loaded") || status.contains("Available") ? .green : .gray)
        }
    }
}

// Wrapper for UIViewController in SwiftUI
struct AudioUnitViewControllerRepresentable: UIViewControllerRepresentable {
    let viewController: UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
}

class AudioEngineManager: ObservableObject {
    @Published var isRunning = false
    @Published var audioUnitLoaded = false
    @Published var inputAvailable = false

    private var audioEngine = AVAudioEngine()
    private var audioUnit: AVAudioUnit?
    var audioUnitViewController: UIViewController?

    private let audioComponentDescription = AudioComponentDescription(
        componentType: kAudioUnitType_Effect,
        componentSubType: 0x6564676c, // 'edgl' - Edge Delay
        componentManufacturer: 0x4564676c, // 'Edgl'
        componentFlags: 0,
        componentFlagsMask: 0
    )

    init() {
        setupAudio()
    }

    private func setupAudio() {
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.inputAvailable = granted
            }
        }

        // Configure audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }

        // Load the audio unit
        AVAudioUnit.instantiate(with: audioComponentDescription, options: []) { [weak self] audioUnit, error in
            guard let self = self else { return }

            if let error = error {
                print("Failed to instantiate audio unit: \(error)")
                return
            }

            guard let audioUnit = audioUnit else {
                print("Audio unit is nil")
                return
            }

            DispatchQueue.main.async {
                self.audioUnit = audioUnit
                self.audioUnitLoaded = true
                self.setupAudioGraph()

                // Request view controller
                audioUnit.auAudioUnit.requestViewController { viewController in
                    DispatchQueue.main.async {
                        self.audioUnitViewController = viewController
                    }
                }
            }
        }
    }

    private func setupAudioGraph() {
        guard let audioUnit = audioUnit else { return }

        let inputNode = audioEngine.inputNode
        let mainMixer = audioEngine.mainMixerNode

        // Connect: input -> audioUnit -> mixer -> output
        audioEngine.attach(audioUnit)

        let format = inputNode.outputFormat(forBus: 0)

        audioEngine.connect(inputNode, to: audioUnit, format: format)
        audioEngine.connect(audioUnit, to: mainMixer, format: format)
    }

    func toggleEngine() {
        if isRunning {
            stopEngine()
        } else {
            startEngine()
        }
    }

    func startEngine() {
        guard !isRunning else { return }

        do {
            try audioEngine.start()
            isRunning = true
        } catch {
            print("Failed to start engine: \(error)")
        }
    }

    func stopEngine() {
        guard isRunning else { return }

        audioEngine.stop()
        isRunning = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
