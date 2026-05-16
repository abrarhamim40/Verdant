# Skill: RevenueCat Subscriptions

## Pricing Strategy (Final)

| Tier | Price | Trial | Features |
|------|-------|-------|----------|
| Free | $0 | N/A | 3 scans/month, 1 plant tracking, NO ads |
| Pro Monthly | $4.99 | 7 days | Unlimited everything |
| Pro Annual | $29.99 | 7 days | Same + 50% off |
| Lifetime ⭐ | $79.99 | None | Forever, all future features |
| Family | $49.99/yr | 7 days | 5 users |

---

## 🔧 One-Time Setup

### **1. RevenueCat Account**
- Sign up: revenuecat.com (FREE under $10K MRR)
- Create iOS app
- Get public API key

### **2. App Store Connect Products**

Create these in App Store Connect → In-App Purchases:

```
Product ID                  | Type                    | Price      | Family Share
planthealth_monthly         | Auto-Renewing Sub       | $4.99/mo   | No
planthealth_annual          | Auto-Renewing Sub       | $29.99/yr  | No
planthealth_lifetime        | Non-Consumable          | $79.99     | No
planthealth_family          | Auto-Renewing Sub       | $49.99/yr  | Yes
```

### **3. RevenueCat Configuration**

In RevenueCat dashboard:
- Create entitlement: `premium`
- Attach all 4 products to `premium`
- Create offering: `default`
- Add packages:
  - `$rc_monthly` → planthealth_monthly
  - `$rc_annual` → planthealth_annual (mark "Most Popular")
  - `lifetime` → planthealth_lifetime
  - `family` → planthealth_family

### **4. Install SDK**

Xcode → File → Add Package Dependencies
```
URL: https://github.com/RevenueCat/purchases-ios
Version: 5.0.0+ (latest)
```

---

## ⚙️ App Configuration

### **PlantHealthApp.swift:**
```swift
import SwiftUI
import RevenueCat

@main
struct PlantHealthApp: App {
    init() {
        configureRevenueCat()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(SubscriptionService.shared)
                .environment(UsageTracker.shared)
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func configureRevenueCat() {
        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .info
        #endif
        
        Purchases.configure(
            withAPIKey: APIKeys.revenueCat,
            appUserID: nil  // RevenueCat manages anonymously
        )
    }
}
```

---

## 💎 SubscriptionService

```swift
import RevenueCat
import Observation

@Observable
@MainActor
final class SubscriptionService {
    static let shared = SubscriptionService()
    
    private(set) var isPremium: Bool = false
    private(set) var currentOffering: Offering?
    private(set) var subscriptionType: SubscriptionType = .none
    private(set) var expirationDate: Date?
    private(set) var isLoading: Bool = false
    
    enum SubscriptionType: String {
        case none, monthly, annual, lifetime, family
        
        var displayName: String {
            switch self {
            case .none: return "Free"
            case .monthly: return "Pro Monthly"
            case .annual: return "Pro Annual"
            case .lifetime: return "Lifetime"
            case .family: return "Family"
            }
        }
    }
    
    private init() {
        Purchases.shared.delegate = PurchaseListener.shared
        
        Task {
            await refreshSubscriptionStatus()
            await loadOfferings()
        }
    }
    
    // Refresh from RevenueCat
    func refreshSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateStatus(from: customerInfo)
        } catch {
            Logger.subscription.error("Refresh failed: \(error)")
        }
    }
    
    // Load offerings
    func loadOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            self.currentOffering = offerings.current
        } catch {
            Logger.subscription.error("Offerings load failed: \(error)")
        }
    }
    
    // Purchase
    func purchase(package: Package) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        let result = try await Purchases.shared.purchase(package: package)
        
        if result.userCancelled {
            return false
        }
        
        updateStatus(from: result.customerInfo)
        return isPremium
    }
    
    // Restore purchases (required by App Store)
    func restore() async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        let customerInfo = try await Purchases.shared.restorePurchases()
        updateStatus(from: customerInfo)
        return isPremium
    }
    
    private func updateStatus(from info: CustomerInfo) {
        let entitlement = info.entitlements["premium"]
        let isActive = entitlement?.isActive == true
        
        self.isPremium = isActive
        self.subscriptionType = determineType(from: info)
        self.expirationDate = entitlement?.expirationDate
        
        Logger.subscription.info("Status updated: \(self.subscriptionType.rawValue)")
    }
    
    private func determineType(from info: CustomerInfo) -> SubscriptionType {
        guard let active = info.entitlements["premium"], active.isActive else {
            return .none
        }
        
        let productId = active.productIdentifier
        if productId.contains("lifetime") { return .lifetime }
        if productId.contains("annual") { return .annual }
        if productId.contains("monthly") { return .monthly }
        if productId.contains("family") { return .family }
        return .none
    }
}

// Listener for purchase updates
final class PurchaseListener: NSObject, PurchasesDelegate {
    static let shared = PurchaseListener()
    
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            await SubscriptionService.shared.refreshSubscriptionStatus()
        }
    }
}
```

---

## 📊 UsageTracker (Free Tier Enforcement)

```swift
import Observation

@Observable
final class UsageTracker {
    static let shared = UsageTracker()
    
    private let userDefaults = UserDefaults.standard
    private let monthlyScanLimit = 3
    
    private init() {}
    
    var scansThisMonth: Int {
        userDefaults.integer(forKey: monthKey())
    }
    
    var canScan: Bool {
        SubscriptionService.shared.isPremium || scansThisMonth < monthlyScanLimit
    }
    
    var remainingFreeScans: Int {
        max(0, monthlyScanLimit - scansThisMonth)
    }
    
    var shouldShowPaywall: Bool {
        !SubscriptionService.shared.isPremium && scansThisMonth >= monthlyScanLimit - 1
    }
    
    func recordScan() {
        let key = monthKey()
        let current = userDefaults.integer(forKey: key)
        userDefaults.set(current + 1, forKey: key)
        
        Logger.subscription.info("Scan recorded: \(current + 1)/\(self.monthlyScanLimit)")
    }
    
    private func monthKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return "scans_\(formatter.string(from: Date()))"
    }
}
```

---

## 🎨 PaywallView (Honest Design)

```swift
import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(SubscriptionService.self) private var subscriptions
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var showRestoreSuccess = false
    
    let context: PaywallContext
    
    enum PaywallContext {
        case scanLimitReached
        case onboarding
        case manualUpgrade
        case premiumFeature(String)
        
        var headline: String {
            switch self {
            case .scanLimitReached: return "Keep scanning unlimited plants"
            case .onboarding: return "Get the most out of PlantHealth"
            case .manualUpgrade: return "Upgrade to Pro"
            case .premiumFeature(let feature): return "\(feature) is a Pro feature"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    featuresSection
                    pricingSection
                    purchaseButton
                    restoreSection
                    legalSection
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .accessibilityLabel("Close")
                }
            }
            .task {
                if subscriptions.currentOffering == nil {
                    await subscriptions.loadOfferings()
                }
                // Default to annual (best value)
                selectedPackage = subscriptions.currentOffering?.annual
            }
            .alert("Error", isPresented: errorBinding) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("Restored!", isPresented: $showRestoreSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your purchases have been restored.")
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color("ForestGreen"))
            
            Text(context.headline)
                .font(.displaySmall)
                .multilineTextAlignment(.center)
            
            Text("Unlock everything for a fair, honest price.")
                .font(.bodyDefault)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 32)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureRow(icon: "infinity", title: "Unlimited scans", subtitle: "No monthly limits")
            FeatureRow(icon: "leaf.fill", title: "Unlimited plants", subtitle: "Track everything you grow")
            FeatureRow(icon: "cloud.fill", title: "Climate-aware care", subtitle: "Adjusts to your weather")
            FeatureRow(icon: "camera.viewfinder", title: "Multi-angle scan", subtitle: "30% better accuracy")
            FeatureRow(icon: "sparkles", title: "Plant Whisperer AI", subtitle: "Free-form questions")
            FeatureRow(icon: "heart.fill", title: "Priority support", subtitle: "We're here to help")
        }
    }
    
    private var pricingSection: some View {
        VStack(spacing: 12) {
            if let offering = subscriptions.currentOffering {
                if let lifetime = offering.lifetime {
                    PricingCard(
                        package: lifetime,
                        title: "Lifetime",
                        subtitle: "Pay once, use forever",
                        badge: "BEST VALUE",
                        isSelected: selectedPackage?.identifier == lifetime.identifier,
                        onTap: { selectedPackage = lifetime }
                    )
                }
                
                if let annual = offering.annual {
                    PricingCard(
                        package: annual,
                        title: "Annual",
                        subtitle: "Save 50% vs monthly",
                        badge: "MOST POPULAR",
                        isSelected: selectedPackage?.identifier == annual.identifier,
                        onTap: { selectedPackage = annual }
                    )
                }
                
                if let monthly = offering.monthly {
                    PricingCard(
                        package: monthly,
                        title: "Monthly",
                        subtitle: "Try with 7-day trial",
                        isSelected: selectedPackage?.identifier == monthly.identifier,
                        onTap: { selectedPackage = monthly }
                    )
                }
            } else {
                ProgressView()
                    .padding(.vertical, 32)
            }
        }
    }
    
    private var purchaseButton: some View {
        VStack(spacing: 12) {
            PrimaryButton(
                purchaseButtonTitle,
                isLoading: isPurchasing,
                isDisabled: selectedPackage == nil
            ) {
                Task { await handlePurchase() }
            }
            
            Text(purchaseSubtext)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var restoreSection: some View {
        Button("Restore Purchases") {
            Task { await handleRestore() }
        }
        .font(.bodyDefault)
        .foregroundStyle(Color("ForestGreen"))
    }
    
    private var legalSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Link("Privacy Policy", destination: URL(string: "https://planthealth.app/privacy")!)
                Text("•")
                    .foregroundStyle(.secondary)
                Link("Terms of Use", destination: URL(string: "https://planthealth.app/terms")!)
            }
            .font(.caption)
            
            Text("Subscriptions auto-renew. Cancel anytime in Settings.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Computed
    
    private var purchaseButtonTitle: String {
        guard let package = selectedPackage else { return "Select a plan" }
        
        if package.packageType == .lifetime {
            return "Purchase Lifetime"
        }
        
        if let trial = package.storeProduct.introductoryDiscount,
           trial.paymentMode == .freeTrial {
            return "Start 7-Day Free Trial"
        }
        
        return "Continue"
    }
    
    private var purchaseSubtext: String {
        guard let package = selectedPackage else { return "" }
        
        if package.packageType == .lifetime {
            return "One-time payment. No subscription."
        }
        
        if package.storeProduct.introductoryDiscount?.paymentMode == .freeTrial {
            return "Free for 7 days, then \(package.localizedPriceString). Cancel anytime."
        }
        
        return "Cancel anytime in Settings"
    }
    
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }
    
    // MARK: - Actions
    
    private func handlePurchase() async {
        guard let package = selectedPackage else { return }
        
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let success = try await subscriptions.purchase(package: package)
            if success {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            Logger.subscription.error("Purchase failed: \(error)")
        }
    }
    
    private func handleRestore() async {
        do {
            let restored = try await subscriptions.restore()
            if restored {
                showRestoreSuccess = true
            } else {
                errorMessage = "No active subscription found"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### **Supporting Components:**

```swift
struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color("ForestGreen"))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.bodyMedium)
                Text(subtitle)
                    .font(.captionLarge)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

struct PricingCard: View {
    let package: Package
    let title: String
    let subtitle: String
    var badge: String?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                if let badge = badge {
                    Text(badge)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("Terracotta"))
                        .clipShape(Capsule())
                }
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.titleSmall)
                        Text(subtitle)
                            .font(.captionLarge)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(package.localizedPriceString)
                            .font(.titleSmall)
                            .fontWeight(.bold)
                    }
                }
            }
            .padding(16)
            .background(isSelected ? Color("ForestGreen").opacity(0.1) : Color("BackgroundSecondary"))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color("ForestGreen") : Color.clear,
                        lineWidth: 2
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
```

---

## 🎯 Paywall Triggers (Strategic)

```swift
// Trigger 1: Scan limit reached (HIGH conversion ~15%)
if !usageTracker.canScan {
    showPaywall = true
    paywallContext = .scanLimitReached
}

// Trigger 2: Onboarding end (low conversion ~3%, but sets expectations)
// Show ONCE during onboarding

// Trigger 3: Premium feature attempted (MEDIUM ~8%)
if !subscriptions.isPremium && wantsClimateAware {
    showPaywall = true
    paywallContext = .premiumFeature("Climate-aware care")
}

// Trigger 4: Manual upgrade from settings (HIGH intent ~25%)
```

### **Rules:**
1. **NEVER show paywall** more than ONCE per session
2. Always allow close
3. Show value BEFORE paywall
4. Track which triggers convert best

---

## 🧪 Testing (Sandbox)

### **Setup:**
1. App Store Connect → Users and Access → Sandbox Testers
2. Create test account (real email, fake other info)
3. iPhone Settings → Sign out App Store
4. Run app from Xcode
5. Try purchase → sign in with sandbox account

### **Test Cases:**
- [ ] Purchase monthly subscription
- [ ] Purchase annual subscription
- [ ] Purchase lifetime
- [ ] Purchase family plan
- [ ] Restore purchases
- [ ] Cancel subscription (Settings → Subscriptions)
- [ ] Subscription renewal (sandbox = 5 mins)
- [ ] Free tier limit enforcement
- [ ] Paywall doesn't show twice
- [ ] Close button works
- [ ] All errors handled

---

## ⚠️ Critical UX Rules

### **MUST DO:**
- ✅ Easy close button (visible, top-right)
- ✅ Restore purchases always visible
- ✅ Privacy Policy + Terms links
- ✅ Clear pricing display
- ✅ Mention "Cancel anytime"
- ✅ Allow access to all content before paywall
- ✅ Show value first

### **NEVER DO:**
- ❌ Hide close button (App Store will reject)
- ❌ Force paywall on app open
- ❌ Fake countdown timers
- ❌ Hidden cancellation
- ❌ Misleading pricing
- ❌ Double-negative buttons
- ❌ Multiple paywalls per session
- ❌ Show paywall before showing value

---

## ✅ Pre-Commit Checklist

- [ ] All 4 products in App Store Connect
- [ ] Sandbox testing complete
- [ ] Close button visible and works
- [ ] Restore purchases works
- [ ] Privacy/Terms links work
- [ ] Free tier limit enforced
- [ ] Premium features locked properly
- [ ] All errors handled gracefully
- [ ] Subscription status syncs across devices
- [ ] No dark patterns
