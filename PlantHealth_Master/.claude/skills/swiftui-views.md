# Skill: SwiftUI Views

## When to Use
Any SwiftUI view in PlantHealth.

---

## 🎯 Master Template (Use This Every Time)

```swift
import SwiftUI
import SwiftData

struct FeatureNameView: View {
    // MARK: - State
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionService.self) private var subscriptions
    
    // MARK: - Query
    @Query private var plants: [Plant]
    
    // MARK: - Properties
    let plantId: UUID
    
    // MARK: - Body
    var body: some View {
        contentView
            .navigationTitle("Title")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .task { await loadData() }
            .alert("Error", isPresented: errorBinding) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            LoadingView("Loading...")
        } else if plants.isEmpty {
            EmptyStateView(
                icon: "leaf",
                title: "No plants yet",
                message: "Add your first plant to get started",
                actionTitle: "Add Plant",
                action: { /* action */ }
            )
        } else {
            mainContent
        }
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Actual content here
            }
            .padding(20)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                // action
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("More options")
        }
    }
    
    // MARK: - Bindings
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }
    
    // MARK: - Methods
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Async work
        } catch {
            errorMessage = error.localizedDescription
            Logger.ui.error("Load failed: \(error)")
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        FeatureNameView(plantId: UUID())
    }
    .modelContainer(for: [Plant.self], inMemory: true)
}
```

---

## 🎨 Required Patterns

### **1. Loading State Pattern**
```swift
.task {
    await loadData()
}
```
**Always use `.task` not `.onAppear`** for async work. `.task` auto-cancels on view dismiss.

### **2. Error Handling**
```swift
.alert("Error", isPresented: errorBinding) {
    Button("OK") { errorMessage = nil }
    Button("Retry") { Task { await loadData() } }
} message: {
    Text(errorMessage ?? "")
}
```

### **3. Conditional Views**
```swift
@ViewBuilder
private var content: some View {
    if isLoading {
        ProgressView()
    } else if items.isEmpty {
        EmptyStateView(...)
    } else {
        ItemList(items: items)
    }
}
```

### **4. Sheet Presentation**
```swift
.sheet(isPresented: $showPaywall) {
    PaywallView()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
}
```

### **5. Navigation (Type-Safe)**
```swift
NavigationStack(path: $path) {
    HomeView()
        .navigationDestination(for: Plant.self) { plant in
            PlantDetailView(plant: plant)
        }
}
```

### **6. Haptic Feedback**
```swift
.sensoryFeedback(.success, trigger: successCount)
.sensoryFeedback(.selection, trigger: selectedItem)
.sensoryFeedback(.impact(weight: .light), trigger: tap)
```

---

## 📐 Layout Rules

### **Spacing Scale (ONLY use these):**
```swift
4, 8, 12, 16, 20, 24, 32, 48
```

### **Standard Paddings:**
- Screen edges: 20
- Card internal: 16-20
- Between sections: 24-32
- Between related elements: 8-12

### **Corner Radius:**
- Small (badges): 8
- Cards: 12-16
- Hero cards: 20-24
- Sheet corners: handled by system

### **Stroke Width:**
- Borders: 0.5px (subtle)
- Never 1px or 2px (looks heavy)

---

## 🎨 Color Usage

### **NEVER hardcode hex colors:**
```swift
// ❌ Bad
.foregroundStyle(Color(red: 0.1, green: 0.4, blue: 0.2))

// ✅ Good
.foregroundStyle(Color("ForestGreen"))
```

### **Standard Colors (from Asset Catalog):**
- `Color("ForestGreen")` - primary
- `Color("Sage")` - secondary
- `Color("Terracotta")` - accent
- `Color("BackgroundPrimary")` - bg
- `Color("BackgroundSecondary")` - elevated bg
- `Color("TextPrimary")` - headlines
- `Color("TextSecondary")` - subtitles
- `Color("HealthyGreen")` - success
- `Color("WarningAmber")` - warning
- `Color("CriticalRed")` - error

---

## 🔤 Typography

### **Use Font extensions:**
```swift
extension Font {
    static let displayLarge = Font.system(size: 48, weight: .bold, design: .serif)
    static let displayMedium = Font.system(size: 34, weight: .bold, design: .serif)
    static let displaySmall = Font.system(size: 28, weight: .semibold, design: .serif)
    
    static let titleLarge = Font.system(size: 28, weight: .semibold)
    static let titleMedium = Font.system(size: 22, weight: .semibold)
    static let titleSmall = Font.system(size: 20, weight: .semibold)
    
    static let bodyLarge = Font.system(size: 17, weight: .regular)
    static let bodyDefault = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 16, weight: .medium)
    
    static let captionLarge = Font.system(size: 13, weight: .regular)
    static let captionMedium = Font.system(size: 13, weight: .medium)
    static let footnote = Font.system(size: 12, weight: .regular)
}
```

**Usage:**
```swift
Text("Monstera Deliciosa")
    .font(.displayMedium)
    .foregroundStyle(Color("TextPrimary"))
```

---

## ✅ Accessibility (REQUIRED)

### **Every icon-only button:**
```swift
Button { /* action */ } label: {
    Image(systemName: "trash")
}
.accessibilityLabel("Delete plant")
```

### **Group complex views:**
```swift
HStack {
    Image(systemName: "leaf.fill")
    Text("Healthy")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Plant status: Healthy")
```

### **Dynamic Type:**
- Use system text styles when possible
- Test with largest accessibility size
- Avoid fixed heights for text containers

### **Reduce Motion:**
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

.animation(reduceMotion ? nil : .spring(), value: state)
```

---

## 🎬 Animation Best Practices

### **Standard:**
```swift
.animation(.easeInOut(duration: 0.2), value: state)
```

### **Spring (for delight):**
```swift
.animation(.spring(response: 0.4, dampingFraction: 0.7), value: state)
```

### **Smooth:**
```swift
.animation(.smooth(duration: 0.3), value: state)
```

### **NEVER use heavy animations:**
- ❌ Bouncing > 0.5 dampingFraction
- ❌ Duration > 0.5s
- ❌ Multiple competing animations

---

## 📸 SF Symbols

### **Plant App Specific:**
```swift
// Status
Image(systemName: "leaf.fill")           // healthy
Image(systemName: "exclamationmark.triangle.fill") // warning
Image(systemName: "cross.case.fill")     // diseased

// Actions
Image(systemName: "camera.fill")         // scan
Image(systemName: "drop.fill")           // water
Image(systemName: "sun.max.fill")        // light
Image(systemName: "leaf.arrow.circlepath") // refresh

// Navigation
Image(systemName: "house.fill")          // home
Image(systemName: "list.bullet")         // plants
Image(systemName: "bell.fill")           // reminders
Image(systemName: "gearshape.fill")      // settings

// UI
Image(systemName: "chevron.right")       // disclosure
Image(systemName: "ellipsis.circle")     // more
Image(systemName: "xmark")               // close
Image(systemName: "checkmark.seal.fill") // verified

// Premium
Image(systemName: "crown.fill")          // pro feature
Image(systemName: "lock.fill")           // locked
```

### **Symbol Styling:**
```swift
Image(systemName: "leaf.fill")
    .symbolRenderingMode(.hierarchical)
    .foregroundStyle(.green)
    .font(.system(size: 24))
```

---

## 🌑 Dark Mode (MANDATORY)

### **Setup:**
1. All colors in Asset Catalog have light + dark variants
2. Test EVERY screen in both modes
3. Use semantic colors (`.primary`, `.secondary`) when possible

### **Preview both:**
```swift
#Preview("Light Mode") {
    MyView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    MyView()
        .preferredColorScheme(.dark)
}
```

---

## 🎯 Multiple Preview Variants

```swift
#Preview("Default") {
    PlantDetailView(plant: .preview)
}

#Preview("Empty") {
    PlantDetailView(plant: .empty)
}

#Preview("Loading") {
    PlantDetailView(plant: .loading)
}

#Preview("Error") {
    PlantDetailView(plant: .preview)
        .environment(\.errorMessage, "Something went wrong")
}

#Preview("Dark") {
    PlantDetailView(plant: .preview)
        .preferredColorScheme(.dark)
}
```

---

## 🚫 NEVER DO

```swift
// ❌ UIHostingController - pure SwiftUI only
class MyVC: UIViewController { ... }

// ❌ ObservableObject - use @Observable
class ViewModel: ObservableObject { ... }

// ❌ Combine framework
import Combine
@Published var value: String

// ❌ Force unwrap
let plant = plants.first!

// ❌ Hardcoded strings
Text("Welcome")

// ❌ Hardcoded colors  
Color(red: 0.1, green: 0.4, blue: 0.2)

// ❌ print()
print("debug message")

// ❌ Heavy work in body
var body: some View {
    let processedData = expensiveCalculation() // ❌
    return Text(processedData)
}

// ❌ GeometryReader for simple layouts
GeometryReader { geo in ... } // Try alignment first
```

---

## ✨ Premium UI Touches

### **Glass Card Effect (iOS 17+):**
```swift
.background(.ultraThinMaterial)
.clipShape(RoundedRectangle(cornerRadius: 16))
.overlay(
    RoundedRectangle(cornerRadius: 16)
        .stroke(.white.opacity(0.2), lineWidth: 0.5)
)
```

### **Subtle Shadow:**
```swift
.shadow(color: .black.opacity(0.06), radius: 12, y: 4)
```
**Never** higher than 0.08 opacity. Subtle wins.

### **Hero Image:**
```swift
Image("plant")
    .resizable()
    .aspectRatio(16/9, contentMode: .fill)
    .frame(height: 240)
    .clipped()
    .overlay(alignment: .bottomLeading) {
        LinearGradient(
            colors: [.clear, .black.opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
```

---

## 🎯 Performance Rules

1. **LazyVStack/LazyHStack** in ScrollViews with >5 items
2. **Use `.id()`** sparingly (causes re-renders)
3. **Avoid `GeometryReader`** when possible
4. **Cache computed properties** outside body
5. **Use `@StateObject` once**, share via `@Environment`

---

## ✅ Pre-Commit Checklist

Before committing any view:

- [ ] `#Preview` included
- [ ] All async work uses `.task`
- [ ] Loading state handled
- [ ] Error state handled
- [ ] Empty state handled
- [ ] Asset Catalog colors used (no hex)
- [ ] String Catalog used (no hardcoded strings)
- [ ] Accessibility labels on icons
- [ ] Tested in light + dark mode
- [ ] No force unwraps
- [ ] No print() statements
- [ ] Under 300 lines
- [ ] No deprecated APIs

**If all checked → commit. If not → fix first.**
