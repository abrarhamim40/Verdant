# Skill: Design Components

## Color System

### **Asset Catalog Setup (Required)**

Create these in `Assets.xcassets`:

```
ForestGreen
├── Light: #1B4332
└── Dark:  #52796F

Sage
├── Light: #52796F
└── Dark:  #95B5A8

Terracotta
├── Light: #D68C45
└── Dark:  #E8A867

BackgroundPrimary
├── Light: #FAF7F0
└── Dark:  #0F1B14

BackgroundSecondary
├── Light: #F1EDE2
└── Dark:  #1A2620

TextPrimary
├── Light: #2A2620
└── Dark:  #FAF7F0

TextSecondary
├── Light: #6B6660
└── Dark:  #A8A39A

HealthyGreen
├── Light: #228B57
└── Dark:  #4CAF7E

WarningAmber
├── Light: #DAA520
└── Dark:  #F2C94C

CriticalRed
├── Light: #B22234
└── Dark:  #E57373
```

### **Usage:**
```swift
Color("ForestGreen")
Color("BackgroundPrimary")
```

---

## 🔘 PrimaryButton

```swift
struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color("ForestGreen"))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isLoading || isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
        .sensoryFeedback(.impact(weight: .light), trigger: isLoading)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton("Continue") { }
        PrimaryButton("Loading", isLoading: true) { }
        PrimaryButton("Disabled", isDisabled: true) { }
    }
    .padding()
}
```

---

## 🔘 SecondaryButton

```swift
struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .font(.system(size: 17, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .foregroundStyle(Color("ForestGreen"))
            .background(Color("ForestGreen").opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
```

---

## 🌿 PlantCard

```swift
struct PlantCard: View {
    let plant: Plant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero image
            heroImage
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(plant.displayName)
                    .font(.titleSmall)
                    .foregroundStyle(Color("TextPrimary"))
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 12))
                    Text(wateringText)
                        .font(.captionLarge)
                }
                .foregroundStyle(Color("TextSecondary"))
            }
            .padding(16)
        }
        .background(Color("BackgroundPrimary"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
    
    @ViewBuilder
    private var heroImage: some View {
        if let data = plant.imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(16/10, contentMode: .fill)
                .frame(height: 180)
                .clipped()
        } else {
            placeholderImage
        }
    }
    
    private var placeholderImage: some View {
        Color("Sage").opacity(0.2)
            .frame(height: 180)
            .overlay {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color("Sage"))
            }
    }
    
    private var wateringText: String {
        if let next = plant.nextWateringDate {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: next).day ?? 0
            if days <= 0 { return "Water now!" }
            if days == 1 { return "Water tomorrow" }
            return "Water in \(days) days"
        }
        return "Tap to set reminder"
    }
}
```

---

## 🏷️ HealthBadge

```swift
struct HealthBadge: View {
    enum Status: String {
        case healthy, stressed, diseased, critical
        
        var label: String {
            switch self {
            case .healthy: return "Healthy"
            case .stressed: return "Needs attention"
            case .diseased: return "Diseased"
            case .critical: return "Critical"
            }
        }
        
        var color: Color {
            switch self {
            case .healthy: return Color("HealthyGreen")
            case .stressed: return Color("WarningAmber")
            case .diseased, .critical: return Color("CriticalRed")
            }
        }
        
        var icon: String {
            switch self {
            case .healthy: return "checkmark.circle.fill"
            case .stressed: return "exclamationmark.triangle.fill"
            case .diseased: return "cross.case.fill"
            case .critical: return "exclamationmark.octagon.fill"
            }
        }
    }
    
    let status: Status
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.icon)
                .font(.system(size: 12, weight: .semibold))
            Text(status.label)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(status.color.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Health status: \(status.label)")
    }
}
```

---

## 📊 ConfidenceScoreView (KEY DIFFERENTIATOR)

```swift
struct ConfidenceScoreView: View {
    let confidence: Double  // 0.0 to 1.0
    
    private var percentage: Int { Int(confidence * 100) }
    
    private var color: Color {
        switch confidence {
        case 0.85...: return Color("HealthyGreen")
        case 0.70..<0.85: return Color("WarningAmber")
        default: return Color("CriticalRed")
        }
    }
    
    private var label: String {
        switch confidence {
        case 0.85...: return "High confidence"
        case 0.70..<0.85: return "Moderate confidence"
        default: return "Low confidence - try multiple angles"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: confidence)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                Text("\(percentage)%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)
            }
            
            // Label
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("TextPrimary"))
                Text("AI analysis confidence")
                    .font(.system(size: 11))
                    .foregroundStyle(Color("TextSecondary"))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(percentage) percent confidence")
    }
}
```

---

## 💫 EmptyStateView

```swift
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Color("Sage").opacity(0.5))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.titleMedium)
                    .foregroundStyle(Color("TextPrimary"))
                
                Text(message)
                    .font(.bodyDefault)
                    .foregroundStyle(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            if let actionTitle, let action {
                PrimaryButton(actionTitle, action: action)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
```

---

## ⏳ LoadingView

```swift
struct LoadingView: View {
    let message: String
    
    init(_ message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(Color("ForestGreen"))
            
            Text(message)
                .font(.bodyDefault)
                .foregroundStyle(Color("TextSecondary"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

---

## 🪟 GlassCard (iOS 17+)

```swift
struct GlassCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        content
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.15), lineWidth: 0.5)
            )
    }
}
```

---

## 📑 SectionHeader

```swift
struct SectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.titleSmall)
                .foregroundStyle(Color("TextPrimary"))
            
            Spacer()
            
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("ForestGreen"))
            }
        }
    }
}
```

---

## 🎯 ErrorRecoveryView

```swift
struct ErrorRecoveryView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color("WarningAmber"))
            
            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.titleMedium)
                
                Text(message)
                    .font(.bodyDefault)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            PrimaryButton("Try Again", action: retryAction)
                .padding(.horizontal, 32)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

---

## 📷 PhotoGuideOverlay

```swift
struct PhotoGuideOverlay: View {
    let stepNumber: Int  // 1, 2, or 3
    
    private var instructions: (title: String, hint: String) {
        switch stepNumber {
        case 1: return ("Photo 1 of 3", "Capture the full plant")
        case 2: return ("Photo 2 of 3", "Close-up of a leaf")
        case 3: return ("Photo 3 of 3", "Flower or distinctive part")
        default: return ("", "")
        }
    }
    
    var body: some View {
        VStack {
            // Step indicator at top
            HStack(spacing: 12) {
                ForEach(1...3, id: \.self) { i in
                    Circle()
                        .fill(i <= stepNumber ? Color("ForestGreen") : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 16)
            
            Spacer()
            
            // Instructions at bottom
            VStack(spacing: 4) {
                Text(instructions.title)
                    .font(.titleSmall)
                    .foregroundStyle(.white)
                Text(instructions.hint)
                    .font(.bodyDefault)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding()
            .background(.black.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.bottom, 100)
        }
    }
}
```

---

## ✅ Component Rules

### **DO:**
- ✅ Use Asset Catalog colors
- ✅ Include `#Preview`
- ✅ Add accessibility labels
- ✅ Use sensoryFeedback for haptics
- ✅ Support light + dark mode
- ✅ Make components reusable
- ✅ Keep under 200 lines

### **DON'T:**
- ❌ Hardcode hex colors
- ❌ Use system colors (`.blue`, `.red`) - use custom
- ❌ Skip accessibility
- ❌ Use heavy shadows (max 0.08 opacity)
- ❌ Mix corner radius styles
- ❌ Create one-off components for single use

---

## 📂 File Organization

Place components in `Core/Utilities/Components/`:

```
Components/
├── PrimaryButton.swift
├── SecondaryButton.swift
├── PlantCard.swift
├── HealthBadge.swift
├── ConfidenceScoreView.swift
├── EmptyStateView.swift
├── LoadingView.swift
├── GlassCard.swift
├── SectionHeader.swift
├── ErrorRecoveryView.swift
└── PhotoGuideOverlay.swift
```

Feature-specific components stay in their feature folder.
