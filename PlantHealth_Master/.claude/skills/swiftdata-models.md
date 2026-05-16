# Skill: SwiftData Models

## When to Use
Creating data models for persistence (Plant, PlantScan, CareReminder, etc.)

---

## 🔧 ModelContainer Setup (PlantHealthApp.swift)

```swift
import SwiftUI
import SwiftData

@main
struct PlantHealthApp: App {
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AppUser.self,
            Plant.self,
            PlantScan.self,
            CareReminder.self,
            UserPreferences.self,
            APIUsageLog.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private(.default)  // 🌟 iCloud sync!
        )
        
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        configureRevenueCat()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(SubscriptionService.shared)
                .environment(AuthService.shared)
                .environment(UsageTracker.shared)
        }
        .modelContainer(sharedModelContainer)
    }
}
```

---

## 👤 AppUser Model

```swift
import SwiftData
import Foundation

@Model
final class AppUser {
    @Attribute(.unique) var id: UUID
    var appleUserID: String?
    var email: String?
    var displayName: String?
    var createdAt: Date
    var isAnonymous: Bool
    var hasCompletedOnboarding: Bool
    
    // App preferences
    var preferredLanguage: String
    var temperatureUnit: String       // "C" or "F"
    var location: String?
    var locationLatitude: Double?
    var locationLongitude: Double?
    
    // Engagement
    var totalScansCount: Int
    var lastActiveDate: Date
    
    init() {
        self.id = UUID()
        self.createdAt = Date()
        self.lastActiveDate = Date()
        self.isAnonymous = true
        self.hasCompletedOnboarding = false
        self.totalScansCount = 0
        
        let langCode = Locale.current.language.languageCode?.identifier ?? "en"
        self.preferredLanguage = langCode
        self.temperatureUnit = Locale.current.measurementSystem == .us ? "F" : "C"
    }
}

extension AppUser {
    static var preview: AppUser {
        let user = AppUser()
        user.displayName = "Test User"
        user.totalScansCount = 12
        return user
    }
}
```

---

## 🌱 Plant Model

```swift
@Model
final class Plant {
    @Attribute(.unique) var id: UUID
    var name: String                  // Scientific name
    var nickname: String?             // User's name
    var commonNames: [String]
    var scientificName: String?
    var dateAdded: Date
    
    @Attribute(.externalStorage) var imageData: Data?
    
    // Location & care
    var location: String?             // "Living room"
    var sunlightLevel: String         // "low", "medium", "bright"
    var hasGrowLight: Bool            // KEY DIFFERENTIATOR
    var indoorOrOutdoor: String       // "indoor" or "outdoor"
    
    // Health
    var currentHealthStatus: String   // "healthy", "stressed", "diseased"
    var lastHealthCheck: Date?
    
    // Custom care (MANUAL OVERRIDE - KEY DIFFERENTIATOR)
    var customWateringDays: Int?      // nil = use AI recommendation
    var customFertilizingDays: Int?
    var customMistingDays: Int?
    var careNotes: String?
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \PlantScan.plant)
    var scans: [PlantScan] = []
    
    @Relationship(deleteRule: .cascade, inverse: \CareReminder.plant)
    var reminders: [CareReminder] = []
    
    init(name: String, nickname: String? = nil, location: String? = nil) {
        self.id = UUID()
        self.name = name
        self.nickname = nickname
        self.location = location
        self.dateAdded = Date()
        self.commonNames = []
        self.sunlightLevel = "medium"
        self.hasGrowLight = false
        self.indoorOrOutdoor = "indoor"
        self.currentHealthStatus = "healthy"
    }
    
    // Computed properties
    var displayName: String {
        nickname ?? commonNames.first ?? name
    }
    
    var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: dateAdded, to: Date()).day ?? 0
    }
    
    var nextWateringDate: Date? {
        reminders
            .filter { $0.type == "watering" && $0.isEnabled }
            .first?.nextDue
    }
}

extension Plant {
    static var preview: Plant {
        let plant = Plant(
            name: "Monstera deliciosa",
            nickname: "Big Mo",
            location: "Living Room"
        )
        plant.commonNames = ["Swiss cheese plant", "Split-leaf philodendron"]
        plant.scientificName = "Monstera deliciosa"
        return plant
    }
}
```

---

## 📸 PlantScan Model

```swift
@Model
final class PlantScan {
    @Attribute(.unique) var id: UUID
    var date: Date
    @Attribute(.externalStorage) var imageData: Data
    
    // Analysis result (stored as JSON for flexibility)
    var analysisJSON: String
    
    // Quick-access fields
    var plantNameDetected: String
    var healthStatus: String          // "healthy", "stressed", "diseased", "critical"
    var confidence: Double            // 0.0 to 1.0
    var diseaseDetected: String?
    var diseaseProbability: Double?
    
    // Source tracking
    var multiAngleScan: Bool          // KEY DIFFERENTIATOR
    var photoCount: Int
    
    // Relationship
    var plant: Plant?
    
    init(
        imageData: Data,
        analysisJSON: String,
        plantNameDetected: String,
        healthStatus: String,
        confidence: Double,
        multiAngleScan: Bool = false,
        photoCount: Int = 1
    ) {
        self.id = UUID()
        self.date = Date()
        self.imageData = imageData
        self.analysisJSON = analysisJSON
        self.plantNameDetected = plantNameDetected
        self.healthStatus = healthStatus
        self.confidence = confidence
        self.multiAngleScan = multiAngleScan
        self.photoCount = photoCount
    }
    
    // Parse JSON for full analysis
    var analysis: PlantAnalysisResult? {
        guard let data = analysisJSON.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(PlantAnalysisResult.self, from: data)
    }
    
    var confidencePercent: Int { Int(confidence * 100) }
}
```

---

## ⏰ CareReminder Model

```swift
@Model
final class CareReminder {
    @Attribute(.unique) var id: UUID
    var type: String                  // "watering", "fertilizing", "pruning", "misting", "rotating"
    var frequencyDays: Int            // Days between care
    var customFrequency: Bool         // KEY DIFFERENTIATOR
    var isEnabled: Bool
    var nextDue: Date
    var lastCompleted: Date?
    
    // Customization (KEY DIFFERENTIATOR)
    var notes: String?
    var amount: String?               // "1 cup", "until soil moist"
    var preferredTime: Date?          // Morning, evening preference
    
    // History tracking (KEY DIFFERENTIATOR - users can edit history)
    var completionHistory: [Date]
    var streak: Int                   // Consecutive completions
    
    // Relationship
    var plant: Plant?
    
    init(type: String, frequencyDays: Int, plantName: String = "") {
        self.id = UUID()
        self.type = type
        self.frequencyDays = frequencyDays
        self.customFrequency = false
        self.isEnabled = true
        self.completionHistory = []
        self.streak = 0
        
        // Calculate first due date
        self.nextDue = Calendar.current.date(
            byAdding: .day,
            value: frequencyDays,
            to: Date()
        ) ?? Date()
    }
    
    // Mark complete
    func markCompleted(at date: Date = Date()) {
        lastCompleted = date
        completionHistory.append(date)
        
        // Update streak
        if let last = completionHistory.dropLast().last {
            let daysSince = Calendar.current.dateComponents([.day], from: last, to: date).day ?? 0
            if daysSince <= frequencyDays + 2 {
                streak += 1
            } else {
                streak = 1
            }
        } else {
            streak = 1
        }
        
        // Schedule next
        nextDue = Calendar.current.date(
            byAdding: .day,
            value: frequencyDays,
            to: date
        ) ?? Date()
    }
    
    // Undo last completion (KEY DIFFERENTIATOR)
    func undoLastCompletion() {
        guard !completionHistory.isEmpty else { return }
        completionHistory.removeLast()
        lastCompleted = completionHistory.last
        streak = max(0, streak - 1)
        
        // Recalculate next due
        if let last = lastCompleted {
            nextDue = Calendar.current.date(
                byAdding: .day,
                value: frequencyDays,
                to: last
            ) ?? Date()
        }
    }
    
    // Backdate (KEY DIFFERENTIATOR)
    func backdate(to date: Date) {
        completionHistory.append(date)
        completionHistory.sort()
        lastCompleted = completionHistory.last
        
        nextDue = Calendar.current.date(
            byAdding: .day,
            value: frequencyDays,
            to: date
        ) ?? Date()
    }
    
    // Custom frequency override
    func setCustomFrequency(_ days: Int) {
        customFrequency = true
        frequencyDays = days
        
        if let last = lastCompleted {
            nextDue = Calendar.current.date(byAdding: .day, value: days, to: last) ?? Date()
        }
    }
    
    var isOverdue: Bool {
        nextDue < Date() && isEnabled
    }
    
    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextDue).day ?? 0
    }
}
```

---

## ⚙️ UserPreferences Model

```swift
@Model
final class UserPreferences {
    @Attribute(.unique) var id: UUID
    
    // Display
    var language: String              // "en", "es", "fr", "de", "ja"
    var temperatureUnit: String       // "C" or "F"
    var preferDarkMode: Bool          // nil = system
    
    // Notifications
    var notificationsEnabled: Bool
    var dailyReminderTime: Date
    var weeklyDigestEnabled: Bool
    
    // Behavior
    var hasCompletedOnboarding: Bool
    var hasSeenPaywall: Bool
    var lastPaywallShown: Date?
    var lastReviewPromptDate: Date?
    
    // Stats
    var totalScansCount: Int
    var totalPlantsCount: Int
    
    init() {
        self.id = UUID()
        self.language = Locale.current.language.languageCode?.identifier ?? "en"
        self.temperatureUnit = Locale.current.measurementSystem == .us ? "F" : "C"
        self.preferDarkMode = false
        self.notificationsEnabled = true
        
        // Default to 9am reminder
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        self.dailyReminderTime = Calendar.current.date(from: components) ?? Date()
        
        self.weeklyDigestEnabled = true
        self.hasCompletedOnboarding = false
        self.hasSeenPaywall = false
        self.totalScansCount = 0
        self.totalPlantsCount = 0
    }
}
```

---

## 📊 APIUsageLog Model

```swift
@Model
final class APIUsageLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var service: String               // "plant_id" or "gemini"
    var cost: Double                  // in USD
    var success: Bool
    var responseTimeMs: Int?
    var errorMessage: String?
    
    init(
        service: String,
        cost: Double,
        success: Bool,
        responseTimeMs: Int? = nil,
        errorMessage: String? = nil
    ) {
        self.id = UUID()
        self.date = Date()
        self.service = service
        self.cost = cost
        self.success = success
        self.responseTimeMs = responseTimeMs
        self.errorMessage = errorMessage
    }
}
```

---

## 🔍 Query Patterns

### **In SwiftUI View:**
```swift
struct PlantListView: View {
    @Query(sort: \Plant.dateAdded, order: .reverse)
    private var plants: [Plant]
    
    @Environment(\.modelContext) private var context
    
    var body: some View {
        List(plants) { plant in
            PlantRowView(plant: plant)
        }
    }
}
```

### **Filtered:**
```swift
@Query(
    filter: #Predicate<Plant> { plant in
        plant.indoorOrOutdoor == "indoor"
    },
    sort: \Plant.dateAdded,
    order: .reverse
)
private var indoorPlants: [Plant]
```

### **Date-Based:**
```swift
@Query(
    filter: #Predicate<CareReminder> { reminder in
        reminder.isEnabled && reminder.nextDue <= Date()
    },
    sort: \CareReminder.nextDue
)
private var dueReminders: [CareReminder]
```

### **Insert:**
```swift
let plant = Plant(name: "Monstera Deliciosa", location: "Living Room")
context.insert(plant)

do {
    try context.save()
} catch {
    Logger.data.error("Save failed: \(error)")
}
```

### **Delete:**
```swift
context.delete(plant)
try context.save()
```

### **Batch Delete (cleanup):**
```swift
let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
try context.delete(
    model: APIUsageLog.self,
    where: #Predicate<APIUsageLog> { log in
        log.date < oneYearAgo
    }
)
```

---

## ✅ Best Practices

### **1. Always use UUID:**
```swift
@Attribute(.unique) var id: UUID
```

### **2. External storage for large data:**
```swift
@Attribute(.externalStorage) var imageData: Data?
```
Critical for performance. Stores as file, not inline.

### **3. Cascade delete for children:**
```swift
@Relationship(deleteRule: .cascade, inverse: \PlantScan.plant)
var scans: [PlantScan] = []
```

### **4. Inverse relationships:**
Always specify inverse for two-way relationships.

### **5. Computed properties for derived data:**
```swift
var isHealthy: Bool {
    currentHealthStatus == "healthy"
}
```

### **6. Preview data:**
```swift
extension Plant {
    static var preview: Plant {
        let plant = Plant(name: "Monstera", nickname: "Big Mo")
        return plant
    }
}
```

---

## ☁️ CloudKit Sync Notes

### **Requirements:**
- Apple Developer account (free for development)
- CloudKit capability enabled in Xcode
- User signed into iCloud

### **Limitations:**
- All properties must be optional OR have defaults
- No `@Attribute(.unique)` on properties that sync (use UUID id only)
- Free tier: 1GB private + 10GB asset storage per user

### **Setup steps:**
1. Xcode → Project → Signing & Capabilities
2. Add "iCloud" capability
3. Check "CloudKit"
4. Add container: `iCloud.com.yourname.planthealth`
5. Add "Background Modes" → "Remote notifications"

---

## 🚫 Never Do

❌ `class` without `final`
❌ `Int` or `String` for primary keys (use UUID)
❌ Store images inline (use `.externalStorage`)
❌ Forget cascade delete rules
❌ Force unwraps on relationships (use `?`)
❌ Save context after every property change (batch)
❌ Use `@Published` (this is SwiftData, not ObservableObject)
❌ Hardcoded magic strings in queries
