# App Store Screenshot Guide

## Required Screenshots (iPhone 15 Pro Max - 6.7")

### 1. Welcome Screen
**File**: screenshot_1_welcome.png
**Setup**:
```
1. Launch app in iPhone 15 Pro Max simulator
2. Ensure clean state (no login)
3. Show the welcome animation
4. Capture when "Welcome Back" text is visible
```

### 2. Subject Selection
**File**: screenshot_2_subjects.png
**Setup**:
```
1. Tap "Scan Document" or any scan option
2. Show subject chips at top
3. Select "Math" to highlight it
4. Ensure all subjects are visible
```

### 3. Camera Scanning
**File**: screenshot_3_scanning.png
**Setup**:
```
1. Tap "Scan Document"
2. Point at a math equation (use a book or paper)
3. Capture with viewfinder visible
4. Show the scanning UI elements
```

### 4. AI Solution
**File**: screenshot_4_solution.png
**Setup**:
```
1. After scan, wait for solution
2. Show step-by-step explanation
3. Ensure solution is for a real math problem
4. Highlight the step indicators
```

### 5. Premium Features
**File**: screenshot_5_premium.png
**Setup**:
```
1. Use up free solves or tap upgrade
2. Show paywall with pricing
3. Ensure "Best Value" badge visible
4. Show all three tiers
```

### 6. Progress Dashboard
**File**: screenshot_6_progress.png
**Setup**:
```
1. Go to Profile tab
2. Show streak, points, badges
3. Ensure some achievements visible
4. Show weekly progress chart
```

## Screenshot Tips

### Simulator Setup
```bash
# Open Xcode
# Run on iPhone 15 Pro Max
# Device → Rotate if needed
# Use Cmd+S to save screenshots
```

### Professional Touch
1. **Status Bar**: Show 9:41 AM, full battery, WiFi
2. **Content**: Use real problems, not lorem ipsum
3. **State**: Show app with some history/progress
4. **Quality**: Save as PNG, no compression

### Sample Data Setup
```swift
// In UserManager.swift init(), add test data:
#if DEBUG
if ProcessInfo.processInfo.environment["SCREENSHOT_MODE"] != nil {
    currentStreak = 7
    userPoints = 2450
    totalSolves = 23
    unlockedBadges = ["first_solve", "streak_7", "perfect_week"]
}
#endif
```

### Frame Your Screenshots
Use one of these tools:
- https://mockuphone.com (Free)
- https://screenshots.pro
- Figma with device frames

### App Store Connect Upload
- Use Media Manager in App Store Connect
- Upload all 6 screenshots
- Arrange in order shown above
- Add captions from screenshot_descriptions.txt

## Quick Screenshot Script

```bash
#!/bin/bash
# Run this after taking screenshots

# Create frames directory
mkdir -p AppStore/screenshots/framed

# Rename simulator screenshots
mv ~/Desktop/Simulator*.png AppStore/screenshots/

# Number them
cd AppStore/screenshots/
mv Simulator*1*.png screenshot_1_welcome.png
mv Simulator*2*.png screenshot_2_subjects.png
# ... etc

echo "Screenshots ready for framing!"
```