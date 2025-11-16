# The Edge Delay - AUv3 Audio Plugin

A professional-quality Audio Unit v3 plugin inspired by The Edge's (U2) iconic guitar sound. This plugin combines delay, reverb, and shimmer effects to recreate those atmospheric, ambient guitar tones.

## Features

- **Delay Effect**: Adjustable delay time (perfect for dotted eighth note rhythms)
- **Feedback Control**: Create subtle repeats or infinite soundscapes
- **Reverb**: Schroeder-style reverb with adjustable size
- **Shimmer Effect**: Pitch-shifted harmonics for ethereal tones
- **Professional UI**: Custom-designed interface with real-time parameter visualization
- **Low Latency**: Optimized C++ DSP kernel for real-time performance

## Project Structure

```
EdgeDelayAU/
├── EdgeDelayHost/              # Host app for testing the plugin
│   ├── EdgeDelayHostApp.swift  # App entry point
│   ├── ContentView.swift       # Main UI
│   └── Info.plist             # Host app configuration
├── EdgeDelayAU/                # Audio Unit extension
│   ├── EdgeDelayAudioUnit.swift       # AUAudioUnit subclass
│   ├── EdgeDelayViewController.swift  # Plugin UI
│   ├── EdgeDelayDSPKernel.hpp        # C++ DSP implementation
│   ├── EdgeDelayDSPKernel.mm         # C++ bridge
│   └── Info.plist                    # Extension configuration
└── Shared/
    └── EdgeDelayParameters.swift     # Parameter definitions
```

## Setup Instructions

### Prerequisites

- Xcode 13 or later
- iOS 14+ or macOS 11+ deployment target
- AudioKit (optional, for enhanced features)

### Creating the Xcode Project

Since the .xcodeproj file cannot be easily generated programmatically, follow these steps to create it in Xcode:

#### Step 1: Create New Project

1. Open Xcode
2. File → New → Project
3. Choose "iOS" → "App"
4. Product Name: `EdgeDelayHost`
5. Interface: SwiftUI
6. Language: Swift
7. Bundle Identifier: `com.yourcompany.EdgeDelayHost`
8. Click "Create"

#### Step 2: Add App Extension Target

1. In Xcode, File → New → Target
2. Choose "iOS" → "App Extension" → "Audio Unit Extension"
3. Product Name: `EdgeDelayAU`
4. Bundle Identifier: `com.yourcompany.EdgeDelayHost.EdgeDelayAU`
5. Click "Finish"

#### Step 3: Add Source Files

**For EdgeDelayHost target:**
1. Delete the default `ContentView.swift` and `EdgeDelayHostApp.swift` if they exist
2. Add the files from `EdgeDelayHost/` folder:
   - `EdgeDelayHostApp.swift`
   - `ContentView.swift`
3. Replace the default `Info.plist` with the one from `EdgeDelayHost/Info.plist`

**For EdgeDelayAU target:**
1. Delete any default files created by Xcode
2. Add the files from `EdgeDelayAU/` folder:
   - `EdgeDelayAudioUnit.swift`
   - `EdgeDelayViewController.swift`
   - `EdgeDelayDSPKernel.hpp`
   - `EdgeDelayDSPKernel.mm`
3. Add the file from `Shared/` folder:
   - `EdgeDelayParameters.swift`
4. Replace the default `Info.plist` with the one from `EdgeDelayAU/Info.plist`

#### Step 4: Configure Build Settings

**For EdgeDelayAU target:**

1. Select the EdgeDelayAU target → Build Settings
2. Search for "Bridging Header" and ensure Objective-C Bridging Header is set up
3. Search for "C++ Language Dialect" and set to `GNU++17` or `C++17`
4. In Build Phases → Compile Sources:
   - Ensure `EdgeDelayDSPKernel.mm` has the flag `-fno-objc-arc` if needed

**For both targets:**

1. Set deployment target to iOS 14.0+ or macOS 11.0+
2. Ensure code signing is configured

#### Step 5: Update Bundle Identifiers

Make sure the bundle identifiers match:
- Host app: `com.yourcompany.EdgeDelayHost`
- Extension: `com.yourcompany.EdgeDelayHost.EdgeDelayAU`

The extension MUST be a child of the host app identifier.

#### Step 6: Build and Run

1. Select the EdgeDelayHost scheme
2. Choose an iOS device or simulator
3. Build and Run (Cmd+R)
4. Grant microphone permissions when prompted
5. Tap "Start Audio" to begin processing
6. Tap "Open Plugin Controls" to adjust parameters

## Audio Unit Parameters

| Parameter | Range | Default | Description |
|-----------|-------|---------|-------------|
| Delay Time | 10-2000 ms | 375 ms | Delay time (dotted eighth at 120 BPM) |
| Feedback | 0.0-0.95 | 0.4 | Amount of delay feedback |
| Delay Mix | 0.0-1.0 | 0.5 | Dry/wet mix for delay |
| Reverb Size | 0.0-1.0 | 0.7 | Size of the reverb space |
| Reverb Mix | 0.0-1.0 | 0.3 | Dry/wet mix for reverb |
| Shimmer | 0.0-1.0 | 0.2 | Amount of shimmer effect |
| Shimmer Pitch | -12 to +12 st | +12 st | Pitch shift for shimmer |
| Dry/Wet | 0.0-1.0 | 0.5 | Master dry/wet mix |

## The Edge Sound Tips

To recreate classic U2 guitar tones:

1. **"Where The Streets Have No Name"**
   - Delay Time: 375ms (dotted eighth at 120 BPM)
   - Feedback: 0.3-0.4
   - Delay Mix: 0.6
   - Reverb Mix: 0.2

2. **"With or Without You"**
   - Delay Time: 400ms
   - Feedback: 0.5
   - Shimmer: 0.3
   - Reverb Size: 0.8

3. **Ambient/Experimental**
   - Delay Time: 500ms
   - Feedback: 0.7
   - Shimmer: 0.5
   - Shimmer Pitch: +12st
   - Reverb Mix: 0.4

## DSP Architecture

The plugin uses a sophisticated audio processing chain:

1. **Delay Line**: Circular buffer with adjustable length and feedback
2. **Reverb**: Schroeder reverb using parallel comb filters and series allpass filters
3. **Shimmer**: Pitch-shifted harmonics layered with the delay signal
4. **Mixing**: Separate dry/wet controls for delay, reverb, and master output

All processing is done in an optimized C++ kernel for minimal latency and CPU usage.

## Using in DAWs

Once built, the Audio Unit will be available in:
- GarageBand (iOS/macOS)
- Logic Pro
- AUM (Audio Unit Manager)
- Cubasis
- Any AUv3-compatible host

To use:
1. Build the project once on your device
2. The Audio Unit will be registered with the system
3. Open your DAW and look for "The Edge Delay" in the Effects section

## Troubleshooting

**Plugin doesn't appear in DAW:**
- Ensure you've run the host app at least once
- Check that bundle identifiers are correct
- Restart your DAW
- On iOS, ensure the host app is still installed

**No audio:**
- Grant microphone permissions
- Check audio session configuration
- Ensure audio engine is running
- Verify connections in your DAW

**Crackling/distortion:**
- Reduce feedback amount
- Check buffer sizes in your audio interface settings
- Ensure your device isn't under heavy CPU load

## Development

### Modifying the DSP

The core audio processing is in `EdgeDelayDSPKernel.hpp`. Key areas:

- Delay processing: `process()` method
- Reverb: `processReverb()` method
- Parameters: `setParameter()` and `getParameter()`

### Customizing the UI

The UI is in `EdgeDelayViewController.swift`. Built with UIKit for maximum compatibility.

- Modify `setupUI()` to change layout
- Edit `createSlider()` to customize controls
- Update colors and fonts in the view creation methods

## License

Copyright (c) 2024. All rights reserved.

## Credits

Inspired by the legendary guitar sounds of The Edge (U2).

Reverb algorithm based on the Freeverb design by Jezar at Dreampoint.

---

**Note**: This plugin is for educational and creative purposes. It is not affiliated with or endorsed by U2 or The Edge.
