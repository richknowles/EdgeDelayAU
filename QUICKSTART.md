# Quick Start Guide - The Edge Delay AUv3 Plugin

Get your Edge Delay plugin running in 5 minutes!

## Prerequisites

- Mac with Xcode 13+ installed
- iOS device (iOS 14+) or iOS Simulator
- Basic familiarity with Xcode

## Quick Setup (5 Steps)

### 1. Create the Xcode Project

```bash
# From the EdgeDelayAU directory
open -a Xcode
```

1. In Xcode: **File → New → Project**
2. Choose **iOS → App**
3. Settings:
   - Product Name: `EdgeDelayHost`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Bundle ID: `com.yourname.EdgeDelayHost`
4. Save in the `EdgeDelayAU/` directory

### 2. Add the Audio Unit Extension

1. **File → New → Target**
2. Choose **iOS → Audio Unit Extension**
3. Settings:
   - Product Name: `EdgeDelayAU`
   - Bundle ID: `com.yourname.EdgeDelayHost.EdgeDelayAU` (must match host!)
4. Click **Finish**
5. When prompted "Activate scheme?", click **Cancel**

### 3. Add Source Files

**Delete default files:**
- In EdgeDelayHost group: delete default `ContentView.swift` and app file
- In EdgeDelayAU group: delete all default files except `Info.plist`

**Add our files:**

Drag and drop from Finder into Xcode:

**To EdgeDelayHost target:**
- `EdgeDelayHost/EdgeDelayHostApp.swift`
- `EdgeDelayHost/ContentView.swift`

**To EdgeDelayAU target:**
- `EdgeDelayAU/EdgeDelayAudioUnit.swift`
- `EdgeDelayAU/EdgeDelayViewController.swift`
- `EdgeDelayAU/EdgeDelayDSPKernel.hpp`
- `EdgeDelayAU/EdgeDelayDSPKernel.mm`
- `EdgeDelayAU/EdgeDelayAU-Bridging-Header.h`
- `Shared/EdgeDelayParameters.swift` (add to BOTH targets!)

**Replace Info.plist files:**
- Replace EdgeDelayHost's Info.plist with `EdgeDelayHost/Info.plist`
- Replace EdgeDelayAU's Info.plist with `EdgeDelayAU/Info.plist`

### 4. Configure Build Settings

**For EdgeDelayAU target only:**

1. Select EdgeDelayAU target → **Build Settings**
2. Search for "bridging"
3. Set **Objective-C Bridging Header** to:
   ```
   EdgeDelayAU/EdgeDelayAU-Bridging-Header.h
   ```
4. Search for "c++ language"
5. Set **C++ Language Dialect** to **GNU++17**

### 5. Build and Run!

1. Select the **EdgeDelayHost** scheme (top toolbar)
2. Choose your device or simulator
3. Click **Run** (▶️ button) or press **Cmd+R**
4. When app launches:
   - Tap **"Start Audio"**
   - Tap **"Open Plugin Controls"**
   - Adjust parameters and rock out! 🎸

## Testing the Plugin

1. Connect headphones or external speakers
2. Connect a guitar or use your device's microphone
3. Adjust the Delay Time around 375ms for that classic Edge sound
4. Increase Shimmer for ambient textures
5. Tweak Reverb Size for spacious atmospheres

## Using in Other Apps

After building once:
1. The Audio Unit is registered on your device
2. Open GarageBand, AUM, or any AUv3 host
3. Look for **"The Edge Delay"** in Effects
4. Add it to a track and start playing!

## Common Issues

**"Audio Unit doesn't appear in the host app"**
- Make sure bundle IDs match (extension must be child of host)
- Run the host app at least once
- Try restarting the device

**"Build failed with bridging header error"**
- Check the bridging header path in Build Settings
- Ensure path is: `EdgeDelayAU/EdgeDelayAU-Bridging-Header.h`

**"Linker error with C++ symbols"**
- Verify `EdgeDelayDSPKernel.mm` has `.mm` extension (not `.m`)
- Check that it's added to EdgeDelayAU target

**"No audio output"**
- Grant microphone permissions in iOS Settings
- Check that audio engine is running (green status)
- Ensure dry/wet is not at 0

## Next Steps

- Read the full [README.md](README.md) for detailed documentation
- Experiment with parameter values
- Try recording in GarageBand with the plugin
- Customize the UI in `EdgeDelayViewController.swift`
- Modify the DSP in `EdgeDelayDSPKernel.hpp`

## Dotted Eighth Note Delay Times

Classic U2 tempos and their dotted eighth note delay times:

| BPM | Delay Time | Song Reference |
|-----|------------|----------------|
| 100 | 450 ms | Slow ballads |
| 110 | 409 ms | "With or Without You" |
| 120 | 375 ms | "Where The Streets Have No Name" |
| 130 | 346 ms | Faster rock songs |
| 140 | 321 ms | Upbeat tracks |

**Formula**: Delay Time (ms) = (60000 / BPM) × 1.5

Enjoy creating those legendary Edge tones! 🎸✨
