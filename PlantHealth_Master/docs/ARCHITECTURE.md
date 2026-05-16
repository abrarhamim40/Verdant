# Architecture

## 📐 Pattern: MV (Model-View)

NOT MVVM. Just Model + View + Services.

```
User taps button
    ↓
View calls Service method
    ↓
Service does async work
    ↓
Service updates SwiftData
    ↓
@Query in View auto-refreshes
    ↓
UI updates
```

**Why MV not MVVM?**
- iOS 17 `@Observable` makes ViewModels obsolete
- SwiftData `@Query` handles state automatically
- Less boilerplate, more directness
- Better SwiftUI alignment

---

## 📂 Complete Folder Structure

```
PlantHealth/
├── App/
│   ├── PlantHealthApp.swift          # @main entry point
│   ├── AppDelegate.swift              # Notifications setup
│   └── RootView.swift                 # Auth gate + tab switcher
│
├── Core/
│   ├── Services/                      # ALL business logic
│   │   ├── AIService.swift            # Main coordinator
│   │   ├── PlantIdService.swift       # Plant.id API
│   │   ├── GeminiService.swift        # Treatment AI
│   │   ├── AppleVisionService.swift   # Pre-filter
│   │   ├── AuthService.swift          # Apple Sign-In
│   │   ├── SubscriptionService.swift  # RevenueCat
│   │   ├── UsageTracker.swift         # Free tier limits
│   │   ├── NotificationService.swift  # Local notifs
│   │   ├── WeatherService.swift       # Climate awareness
│   │   └── ResponseCache.swift        # 24h cache
│   │
│   ├── Models/                        # Data structures
│   │   ├── AppUser.swift              # @Model
│   │   ├── Plant.swift                # @Model
│   │   ├── PlantScan.swift            # @Model
│   │   ├── CareReminder.swift         # @Model
│   │   ├── UserPreferences.swift      # @Model
│   │   ├── APIUsageLog.swift          # @Model
│   │   ├── PlantIdModels.swift        # Codable API types
│   │   ├── GeminiModels.swift         # Codable API types
│   │   └── PlantAnalysisResult.swift  # Combined result
│   │
│   └── Utilities/
│       ├── APIKeys.swift              # Config.plist loader
│       ├── Logger+Extensions.swift    # os.Logger setup
│       ├── UIImage+Optimization.swift # Resize + compress
│       ├── Data+Hashing.swift         # SHA256 for cache
│       ├── Date+Helpers.swift         # Calendar helpers
│       └── Components/                # Reusable UI
│           ├── PrimaryButton.swift
│           ├── SecondaryButton.swift
│           ├── PlantCard.swift
│           ├── HealthBadge.swift
│           ├── ConfidenceScoreView.swift
│           ├── EmptyStateView.swift
│           ├── LoadingView.swift
│           ├── GlassCard.swift
│           ├── SectionHeader.swift
│           ├── ErrorRecoveryView.swift
│           └── PhotoGuideOverlay.swift
│
├── Features/                          # All user-facing screens
│   ├── Onboarding/
│   │   ├── OnboardingView.swift       # Container
│   │   ├── OnboardingPage1.swift      # Welcome
│   │   ├── OnboardingPage2.swift      # AI demo
│   │   ├── OnboardingPage3.swift      # Permissions
│   │   └── OnboardingPage4.swift      # Sign in
│   │
│   ├── Home/
│   │   ├── HomeView.swift             # Dashboard
│   │   └── HomeStatsView.swift        # Quick stats
│   │
│   ├── Scan/
│   │   ├── ScanView.swift             # Camera entry
│   │   ├── CameraView.swift           # AVFoundation wrapper
│   │   ├── MultiPhotoView.swift       # 1-3 photo capture
│   │   ├── ScanningView.swift         # Loading state
│   │   └── ScanErrorView.swift        # Retry handling
│   │
│   ├── Diagnosis/
│   │   ├── DiagnosisResultView.swift  # Main result
│   │   ├── PlantInfoSection.swift     # Plant identity
│   │   ├── HealthSection.swift        # Disease info
│   │   ├── TreatmentStepsView.swift   # Care plan
│   │   ├── AlternativeMatchesView.swift # Low confidence options
│   │   └── SaveToPlantsSheet.swift    # Add to library
│   │
│   ├── MyPlants/
│   │   ├── PlantListView.swift        # Grid view
│   │   ├── PlantDetailView.swift      # Full details
│   │   ├── PlantEditView.swift        # Edit info
│   │   ├── AddPlantSheet.swift        # Manual add
│   │   └── PlantHistoryView.swift     # Scan timeline
│   │
│   ├── CareSchedule/
│   │   ├── ScheduleView.swift         # Today's tasks
│   │   ├── ReminderCard.swift         # Single task
│   │   ├── EditFrequencyView.swift    # ⭐ MANUAL OVERRIDE
│   │   ├── TaskHistoryView.swift      # ⭐ UNDO + EDIT
│   │   └── StreakView.swift           # Gamification
│   │
│   ├── Settings/
│   │   ├── SettingsView.swift         # Main settings
│   │   ├── AccountView.swift          # Apple Sign-In
│   │   ├── SubscriptionView.swift     # Manage Pro
│   │   ├── NotificationSettingsView.swift
│   │   ├── PreferencesView.swift      # Language, units
│   │   └── AboutView.swift            # Credits, legal
│   │
│   └── Paywall/
│       ├── PaywallView.swift          # Main paywall
│       ├── PricingCard.swift          # Tier card
│       └── FeatureRow.swift           # Feature list item
│
└── Resources/
    ├── Assets.xcassets/               # Images + colors
    │   ├── AppIcon.appiconset/
    │   ├── Colors/                    # All custom colors
    │   └── Illustrations/             # Empty states, etc.
    ├── Localizable.xcstrings          # All strings
    ├── Config.plist                   # 🔒 API keys (gitignored!)
    └── Info.plist                     # App config
```

---

## 🔄 Data Flow Patterns

### **Pattern 1: User triggers scan**
```
ScanView (button tap)
    ↓ Task { await scan() }
AIService.shared.analyzePlant(images:)
    ↓ Apple Vision check
    ↓ Plant.id API call
    ↓ Gemini API call
    ↓ Combine results
DiagnosisResultView (displays result)
```

### **Pattern 2: User saves plant**
```
DiagnosisResultView (save button)
    ↓
SaveToPlantsSheet (collect nickname, location)
    ↓
modelContext.insert(plant)
    ↓
modelContext.save()
    ↓
@Query in PlantListView auto-refreshes
    ↓
CloudKit syncs to other devices
```

### **Pattern 3: User completes care task**
```
ReminderCard (tap "Done")
    ↓
reminder.markCompleted()
    ↓ Updates lastCompleted + nextDue
NotificationService.cancelReminder(old)
NotificationService.scheduleReminder(new)
    ↓
@Query refreshes ScheduleView
    ↓
Streak updates, haptic feedback
```

### **Pattern 4: Free tier hits limit**
```
ScanView (tap scan)
    ↓
UsageTracker.canScan? 
    ↓ NO (limit reached)
    ↓
Show PaywallView
    ↓ User purchases
SubscriptionService.purchase()
    ↓
isPremium = true
    ↓
Scan proceeds normally
```

---

## 🏗️ Service Layer Rules

### **All services are `actor`:**
```swift
actor PlantIdService { ... }
actor GeminiService { ... }
actor AppleVisionService { ... }
```

**Why:** Thread-safety for network calls, no data races.

### **State-holding services use `@Observable`:**
```swift
@Observable
final class AuthService { ... }

@Observable
final class SubscriptionService { ... }

@Observable
final class UsageTracker { ... }
```

**Why:** Auto-syncs to SwiftUI views via Environment.

### **Singleton pattern:**
```swift
static let shared = ServiceName()
private init() { }
```

Inject via Environment in PlantHealthApp:
```swift
.environment(AuthService.shared)
.environment(SubscriptionService.shared)
```

---

## 🔌 Dependencies (Imports)

### **System Frameworks Only (Phase 1):**
```swift
import SwiftUI          // UI
import SwiftData        // Persistence
import AuthenticationServices  // Apple Sign-In
import UserNotifications  // Local notifs
import Vision           // Plant detection
import AVFoundation     // Camera
import PhotosUI         // PhotosPicker
import CryptoKit        // SHA256
import CoreLocation     // Climate context
import WeatherKit       // Weather data
import os.log           // Logger
```

### **Third-Party (Allowed):**
```swift
import RevenueCat       // Subscriptions
```

### **Third-Party (Banned in Phase 1):**
- ❌ Firebase (any module)
- ❌ Auth0
- ❌ Alamofire (use URLSession)
- ❌ Kingfisher/SDWebImage (use AsyncImage)
- ❌ Lottie (use SwiftUI animations)
- ❌ SwiftyJSON (use Codable)

**Rule:** Every dependency must justify its weight. Native first.

---

## 🚦 Phase 2 Additions (Month 3+)

When ready to scale:
- **Firebase FCM** - push notifications
- **OneSignal** (alternative) - marketing campaigns
- **Mixpanel/Amplitude** - advanced analytics (or stay with PostHog)

When going cross-platform (Year 2):
- **Firebase Auth** - replace Apple-only
- **Firestore** or **Supabase** - shared backend
- **Cloud Functions** - server logic

---

## 📏 File Size Limits

- **Views:** Max 300 lines (split if larger)
- **Services:** Max 400 lines (split into extensions)
- **Models:** Max 200 lines
- **Components:** Max 200 lines

**If hitting limits:** Time to refactor or split.

---

## ✅ Quality Standards

Every file must:
- [ ] Have file-level documentation
- [ ] Use proper access modifiers (`private`, `fileprivate`)
- [ ] Have `// MARK: -` section markers
- [ ] Include `#Preview` (if a View)
- [ ] Handle all error cases
- [ ] Use Asset Catalog (no hardcoded colors)
- [ ] Use String Catalog (no hardcoded strings)
- [ ] Pass SwiftLint (if added later)

---

## 🎯 Mental Model

```
┌─────────────────────────────────────┐
│           SwiftUI Views             │  ← User sees this
└──────────────┬──────────────────────┘
               │ calls
┌──────────────▼──────────────────────┐
│         Service Layer (actors)       │  ← Business logic
└──────────────┬──────────────────────┘
               │ reads/writes
┌──────────────▼──────────────────────┐
│      SwiftData Models (@Model)      │  ← Truth source
└──────────────┬──────────────────────┘
               │ syncs
┌──────────────▼──────────────────────┐
│           CloudKit (private)         │  ← Cross-device
└─────────────────────────────────────┘
```

**Keep it this simple. Don't add layers.**
