# Skill: Auth + Local Notifications

## Strategy
- **Auth:** Apple Sign-In only (Phase 1)
- **Notifications:** Apple Local Notifications (Phase 1)
- **Future:** Firebase FCM for push (Phase 2, Month 3+)

---

## 🍎 Apple Sign-In Implementation

### **Step 1: Enable in Xcode**
1. Project → Signing & Capabilities
2. Add "Sign in with Apple" capability
3. Enable in App ID on developer.apple.com (when ready)

### **Step 2: AuthService**

```swift
import AuthenticationServices
import Observation
import SwiftData

@Observable
final class AuthService: NSObject {
    static let shared = AuthService()
    
    private(set) var currentUser: AppUser?
    private(set) var isSignedIn: Bool = false
    private(set) var isLoading: Bool = false
    
    private override init() {
        super.init()
        Task {
            await checkExistingSignIn()
        }
    }
    
    // Check for existing Apple ID sign-in
    func checkExistingSignIn() async {
        guard let userID = UserDefaults.standard.string(forKey: "apple_user_id") else {
            return
        }
        
        let provider = ASAuthorizationAppleIDProvider()
        do {
            let state = try await provider.credentialState(forUserID: userID)
            
            await MainActor.run {
                switch state {
                case .authorized:
                    self.isSignedIn = true
                case .revoked, .notFound, .transferred:
                    self.signOut()
                @unknown default:
                    self.signOut()
                }
            }
        } catch {
            Logger.auth.error("Sign-in check failed: \(error)")
        }
    }
    
    // Sign in with Apple
    @MainActor
    func signInWithApple() async throws -> AppUser {
        isLoading = true
        defer { isLoading = false }
        
        return try await withCheckedThrowingContinuation { continuation in
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            
            let delegate = AppleSignInDelegate(
                onSuccess: { credential in
                    Task { @MainActor in
                        do {
                            let user = try await self.handleAppleSignIn(credential)
                            continuation.resume(returning: user)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                },
                onError: { error in
                    continuation.resume(throwing: error)
                }
            )
            
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            
            // Keep delegate alive
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            
            controller.performRequests()
        }
    }
    
    private func handleAppleSignIn(_ credential: ASAuthorizationAppleIDCredential) async throws -> AppUser {
        let userID = credential.user
        let email = credential.email
        let fullName = credential.fullName
        
        // Save user ID for state checks
        UserDefaults.standard.set(userID, forKey: "apple_user_id")
        
        // Create or update user in SwiftData
        // (This requires ModelContext - inject via dependency or environment)
        
        let displayName = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        // For now, return basic user
        let user = AppUser()
        user.appleUserID = userID
        user.email = email
        user.displayName = displayName.isEmpty ? nil : displayName
        user.isAnonymous = false
        
        self.currentUser = user
        self.isSignedIn = true
        
        return user
    }
    
    // Sign out
    @MainActor
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "apple_user_id")
        currentUser = nil
        isSignedIn = false
    }
    
    // Delete account (App Store requirement)
    @MainActor
    func deleteAccount() async throws {
        // 1. Delete from SwiftData
        // 2. Revoke Apple Sign-In token
        // 3. Sign out
        
        signOut()
        
        // Note: Apple Sign-In tokens can't be programmatically revoked
        // User must do it in Settings → Apple ID → Password & Security
        // → Apps Using Your Apple ID
    }
}

// MARK: - Apple Sign-In Delegate

private final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    let onSuccess: (ASAuthorizationAppleIDCredential) -> Void
    let onError: (Error) -> Void
    
    init(
        onSuccess: @escaping (ASAuthorizationAppleIDCredential) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.onSuccess = onSuccess
        self.onError = onError
    }
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            onError(AuthError.invalidCredential)
            return
        }
        onSuccess(credential)
    }
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        onError(error)
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first ?? ASPresentationAnchor()
    }
}

enum AuthError: LocalizedError {
    case invalidCredential
    case userCancelled
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Sign-in failed. Please try again."
        case .userCancelled: return "Sign-in cancelled"
        case .unknown: return "Something went wrong"
        }
    }
}
```

### **Step 3: Sign In Button**

```swift
import AuthenticationServices

struct SignInView: View {
    @Environment(AuthService.self) private var auth
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            // Hero
            Image(systemName: "leaf.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color("ForestGreen"))
            
            VStack(spacing: 8) {
                Text("Save your garden forever")
                    .font(.displaySmall)
                    .multilineTextAlignment(.center)
                
                Text("Sync between iPhone and iPad. Restore if you change devices.")
                    .font(.bodyDefault)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleSignIn(result)
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 32)
            
            Button("Continue without account") {
                // Continue anonymous
            }
            .foregroundStyle(.secondary)
            .padding(.bottom, 32)
        }
        .padding(.top, 64)
    }
    
    private func handleSignIn(_ result: Result<ASAuthorization, Error>) {
        Task {
            do {
                _ = try await auth.signInWithApple()
            } catch {
                Logger.auth.error("Sign-in failed: \(error)")
            }
        }
    }
}
```

---

## 🔔 Local Notifications

### **NotificationService**

```swift
import UserNotifications
import Observation

@Observable
final class NotificationService {
    static let shared = NotificationService()
    
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // Request permission
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            
            await checkAuthorizationStatus()
            return granted
        } catch {
            Logger.notifications.error("Permission failed: \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            self.authorizationStatus = settings.authorizationStatus
        }
    }
    
    // Schedule reminder
    func scheduleReminder(for reminder: CareReminder) async {
        guard reminder.isEnabled else { return }
        guard let plant = reminder.plant else { return }
        guard authorizationStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "\(plant.displayName) needs care"
        content.body = bodyText(for: reminder)
        content.sound = .default
        content.categoryIdentifier = "PLANT_CARE"
        content.userInfo = [
            "reminder_id": reminder.id.uuidString,
            "plant_id": plant.id.uuidString,
            "type": reminder.type
        ]
        
        // Trigger at next due date
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminder.nextDue
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            Logger.notifications.info("Scheduled: \(reminder.type) for \(plant.displayName)")
        } catch {
            Logger.notifications.error("Schedule failed: \(error)")
        }
    }
    
    // Cancel reminder
    func cancelReminder(_ reminderId: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminderId.uuidString])
    }
    
    // Cancel all
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // Reschedule all (after permission grant or migration)
    func rescheduleAll(reminders: [CareReminder]) async {
        cancelAll()
        for reminder in reminders {
            await scheduleReminder(for: reminder)
        }
    }
    
    private func bodyText(for reminder: CareReminder) -> String {
        switch reminder.type {
        case "watering":
            return reminder.amount.map { "Time to water — \($0)" } 
                ?? "Time to water"
        case "fertilizing":
            return "Time to fertilize your plant"
        case "pruning":
            return "Consider pruning today"
        case "misting":
            return "Time to mist for humidity"
        case "rotating":
            return "Rotate your plant for even growth"
        default:
            return "Plant care reminder"
        }
    }
    
    // Handle interactive actions
    func setupCategories() {
        let completeAction = UNNotificationAction(
            identifier: "MARK_DONE",
            title: "Mark Done",
            options: []
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Tomorrow",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "PLANT_CARE",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
```

### **Notification Delegate (Handle Interactions)**

```swift
import UserNotifications
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        NotificationService.shared.setupCategories()
        return true
    }
    
    // Show notification while app open
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }
    
    // Handle notification tap/actions
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        
        guard let reminderIDString = userInfo["reminder_id"] as? String,
              let reminderID = UUID(uuidString: reminderIDString) else { return }
        
        switch response.actionIdentifier {
        case "MARK_DONE":
            // Mark complete
            await markReminderComplete(reminderID)
        case "SNOOZE":
            // Snooze for 24 hours
            await snoozeReminder(reminderID)
        default:
            // Default tap - navigate to plant
            await navigateToPlant(reminderID)
        }
    }
    
    private func markReminderComplete(_ reminderID: UUID) async {
        // Access ModelContext, find reminder, mark complete
    }
    
    private func snoozeReminder(_ reminderID: UUID) async {
        // Reschedule for tomorrow
    }
    
    private func navigateToPlant(_ reminderID: UUID) async {
        // Deep link to plant detail
    }
}
```

### **In PlantHealthApp.swift:**

```swift
@main
struct PlantHealthApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // ... rest of code
}
```

---

## 🎯 Permission Request UI

```swift
struct NotificationPermissionView: View {
    @Environment(NotificationService.self) private var notifications
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "bell.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color("ForestGreen"))
            
            VStack(spacing: 12) {
                Text("Never forget to water again")
                    .font(.displaySmall)
                    .multilineTextAlignment(.center)
                
                Text("We'll remind you at the perfect time for each plant. You can customize or turn off anytime.")
                    .font(.bodyDefault)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            VStack(spacing: 12) {
                Label("Smart timing", systemImage: "clock.fill")
                Label("Customizable schedules", systemImage: "slider.horizontal.3")
                Label("Mark done in one tap", systemImage: "checkmark.circle.fill")
            }
            .font(.bodyDefault)
            .foregroundStyle(Color("TextSecondary"))
            
            Spacer()
            
            PrimaryButton("Enable Notifications") {
                Task {
                    _ = await notifications.requestAuthorization()
                    dismiss()
                }
            }
            
            Button("Maybe later") {
                dismiss()
            }
            .foregroundStyle(.secondary)
        }
        .padding(32)
    }
}
```

---

## 📱 Future: Firebase FCM (Phase 2)

**When to add (Month 3+):**
- Marketing campaigns
- New feature announcements
- Re-engagement notifications
- Server-triggered alerts

**Why NOT for Phase 1:**
- Local notifications cover 95% of use cases
- Save 1 week of dev time
- No backend complexity yet
- Free, native, reliable

**Migration plan when needed:**
1. Add Firebase iOS SDK
2. Configure FCM
3. Get APNs certificate
4. Add to existing notification handling
5. Server backend for sending (or use Firebase Console)

---

## ✅ Pre-Commit Checklist

### **Auth:**
- [ ] Sign in with Apple capability enabled
- [ ] Account deletion flow implemented
- [ ] Anonymous → authenticated migration works
- [ ] Sign out clears all user data
- [ ] No password storage anywhere

### **Notifications:**
- [ ] Permission request has clear value prop
- [ ] User can decline gracefully
- [ ] Notifications work in background
- [ ] Interactive actions (Mark Done, Snooze) work
- [ ] Deep linking from notification works
- [ ] User can disable in Settings
- [ ] Quiet hours respected (no 3am notifications)

---

## 🚫 Never Do

❌ Store passwords or sensitive data
❌ Skip account deletion flow (App Store will reject)
❌ Force users to create account before value shown
❌ Send notifications at unreasonable hours
❌ Excessive notifications (max 1-2/day per plant)
❌ Use Firebase Auth (adds complexity, not needed yet)
❌ Use Auth0 (way too expensive for B2C)
