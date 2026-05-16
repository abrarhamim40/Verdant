# 🌱 PlantHealth - MASTER PLAN

> **The ONE file you need to ship in 10 weeks. Print this. Pin it. Live by it.**

---

## 🎯 What We're Building (30 Second Pitch)

> "PlantHealth is the honest plant app. 94-98% AI accuracy via Plant.id API. Fair pricing ($4.99/mo or $79.99 lifetime). Features users actually want: custom watering, task undo, iCloud sync, climate-aware care. Built from 1,000 angry competitor reviews."

**Target:** Global iOS users (USA, UK, EU, Japan primary)
**Timeline:** 10 weeks from start to App Store
**Revenue goal:** $5K MRR by Month 6, $50K+ MRR by Year 2

---

## 🛠️ FINAL Tech Stack (LOCKED - No Changes)

```
LANGUAGE:       Swift 5.9+, SwiftUI only
iOS MINIMUM:    17.0+
ARCHITECTURE:   MV pattern (NOT MVVM)
ASYNC:          async/await only (NO Combine)
STATE:          @Observable macro

DATA:           SwiftData + CloudKit sync
AUTH:           Apple Sign-In ONLY (Phase 1)
NOTIFS:         Apple Local Notifications (Phase 1)
SUBSCRIPTIONS:  RevenueCat (free under $10K MRR)

AI PRIMARY:     Plant.id API (94-98% accuracy)
AI SECONDARY:   Gemini 2.5 Pro (treatment generation)
AI PRE-FILTER:  Apple Vision Framework (free)

ANALYTICS:      PostHog (free 1M events/mo)
CRASH REPORT:   Sentry (free 5K events/mo)
PUSH (Phase 2): Firebase FCM (free unlimited)

NO Auth0, NO Firebase Auth, NO Supabase (yet)
NO third-party libs without permission
```

**Total monthly cost at launch:** ~$30-100 (Plant.id only)

---

## 🏆 The 15 Differentiators (From Real User Pain)

Each solves a real complaint from 1,000+ competitor reviews:

### **CRITICAL (Must Have at Launch):**

1. **94-98% AI accuracy** - via Plant.id (vs competitors 76-87%)
2. **MANUAL CARE OVERRIDE** ⭐ - Solves #1 churn reason (Planta complaint)
3. **TASK UNDO + DATE EDIT** ⭐ - "Killed my plants because I can't revise"
4. **iCLOUD SYNC** - "Can't use on iPhone and iPad" complaint
5. **VARIETY-LEVEL ID** - "Every snake plant = just 'snake plant'"
6. **AI CONFIDENCE SCORES VISIBLE** - Industry first transparency
7. **MULTI-ANGLE SCAN** - 3 photos = 30% accuracy boost
8. **HONEST PRICING** - $4.99 vs $7.99, lifetime $79.99 option
9. **ONE-TAP CANCELLATION** - "Can't cancel" complaints
10. **30-DAY REFUND GUARANTEE** - Trust builder

### **HIGH VALUE (Add Week 4-7):**

11. **CLIMATE-AWARE CARE** - Adjusts to user's humidity/temperature
12. **OUTDOOR GARDEN SUPPORT** - "Would rate 5 stars if outdoor"
13. **TOXICITY FILTER** - Pet-safe, kid-safe search
14. **ZERO ADS POLICY** - Even free version

### **PHASE 2 (Month 3-6):**

15. **PLANT WHISPERER AI CHAT** - Free-form questions with full context

---

## 📅 10-WEEK SPRINT PLAN

### **WEEK 0: Setup (Before Day 1)**

```
Day -3 to -1:
□ Install Xcode 15+
□ Install Claude Code (npm install -g @anthropic-ai/claude-code)
□ Sign up Plant.id (web.plant.id) - get API key
□ Sign up Gemini API (aistudio.google.com) - get key
□ Sign up RevenueCat (revenuecat.com)
□ Test Plant.id with 10 real plant photos (validate accuracy)
□ Create ~/Projects/PlantHealth folder
□ Extract this master plan + skills into folder
□ Initialize git: git init && git commit -m "Initial setup"
```

**Time required:** 3-4 hours total

---

### **WEEK 1: Foundation (28 hours)**

**Day 1 (4h):** Xcode project setup
- New SwiftUI project, iOS 17+ minimum
- Bundle ID: com.[yourname].planthealth
- Folder structure per ARCHITECTURE.md
- Asset Catalog with all colors (light + dark)
- String Catalog (Localizable.xcstrings)
- Config.plist for API keys (gitignored)
- APIKeys.swift wrapper

**Day 2 (4h):** Core models
- AppUser SwiftData model
- Plant SwiftData model
- PlantScan SwiftData model
- CareReminder SwiftData model
- UserPreferences SwiftData model
- ModelContainer setup with CloudKit

**Day 3 (4h):** Networking foundation
- AIError enum (all error cases)
- ImageProcessor extension (compression)
- ResponseCache actor
- Logger setup (os.Logger, no print)

**Day 4 (4h):** First API integration
- PlantIdService actor (basic)
- Test with curl first, then Swift
- Verify JSON parsing works
- Single test plant identification

**Day 5 (4h):** Gemini integration
- GeminiService actor
- Treatment prompt template
- JSON response parsing
- Combine with Plant.id result

**Day 6 (4h):** AIService coordinator
- Combines Plant.id + Gemini + Vision
- Cache integration
- Error handling all paths

**Day 7 (4h):** Basic UI shell
- TabView container (4 tabs)
- Placeholder views for each
- Navigation working
- Asset Catalog colors applied

**Week 1 Deliverable:** App opens, can scan 1 plant via API, shows result

---

### **WEEK 2-3: Core Scan Flow (56 hours)**

**Week 2 (28h):**

Day 8-9 (8h): Camera & photo capture
- CameraView with PhotosPicker
- Multi-photo capture UI (1-3 photos)
- Photo preview before submit
- Photo guidance overlay (composition tips)

Day 10-11 (8h): Scanning flow
- ScanningView with Lottie loading
- Progress states (uploading → analyzing → done)
- Cancel button
- Error handling with retry

Day 12-13 (8h): Results display
- DiagnosisResultView (full screen)
- PlantInfoSection with photo
- ConfidenceScoreView (visible %)
- HealthBadge component
- Alternative matches UI (low confidence)

Day 14 (4h): Save to plants flow
- "Save this plant" button
- Add nickname + location sheet
- Confirm save with haptic feedback

**Week 3 (28h):**

Day 15-16 (8h): Treatment view
- TreatmentStepsView component
- Immediate actions section
- Weekly care section
- Warning signs
- Recovery timeline display
- Source citations (build trust)

Day 17-18 (8h): Apple Vision pre-filter
- AppleVisionService actor
- "Is this a plant?" check
- Saves API calls for non-plants
- Friendly error messages

Day 19 (4h): Multi-angle improvement
- Logic to use 3 photos
- Improved Plant.id call
- Test accuracy difference

Day 20-21 (8h): Polish scan flow
- Animations between states
- Haptic feedback throughout
- Empty states (no photos)
- All error paths handled
- Test 20+ different plants

**Week 2-3 Deliverable:** Complete scan flow working end-to-end

---

### **WEEK 4: My Plants & History (28 hours)**

Day 22-23 (8h): Plant list
- PlantListView (grid layout)
- PlantCard component (with photo)
- Search bar (filter by name)
- Sort options (recent, name, health)
- Pull to refresh

Day 24-25 (8h): Plant detail
- PlantDetailView (hero photo)
- Stats: last watered, light, health
- Quick action buttons (water, photo, note)
- Edit nickname/location

Day 26 (4h): Scan history
- Timeline view of all scans
- Compare scans over time
- Photo journal section

Day 27 (4h): Add/edit/delete
- AddPlantSheet (manual add without scan)
- Edit plant info
- Delete confirmation
- Animation on add/remove

Day 28 (4h): CloudKit sync verification
- Test sync between iPhone simulator + iPad simulator
- Handle merge conflicts
- Offline mode behavior

**Week 4 Deliverable:** Users can manage their plant collection across devices

---

### **WEEK 5: Care Schedule & Reminders (28 hours)**

Day 29-30 (8h): Reminder system
- CareReminder logic (watering, fertilizing, pruning)
- Calculate next due dates
- Notification permission request flow
- UNUserNotificationCenter setup

Day 31-32 (8h): Schedule view
- ScheduleView (today's tasks)
- ReminderCard component
- Complete/snooze/skip actions
- Streak tracking

Day 33 (4h): Manual care override ⭐ (KEY DIFFERENTIATOR)
- EditFrequencyView
- Sliders for watering interval
- Fertilizer schedule customization
- "Why?" tooltips explaining defaults
- Save custom schedule

Day 34 (4h): Task undo + history ⭐ (KEY DIFFERENTIATOR)
- Long-press to undo
- "I watered yesterday" backdate
- Task history view
- Restore deleted tasks

Day 35 (4h): Climate awareness
- Get user location (with permission)
- WeatherKit integration
- Adjust schedule based on humidity
- Show "Your climate" in care info

**Week 5 Deliverable:** Smart care schedule with full customization

---

### **WEEK 6: RevenueCat + Paywall (28 hours)**

Day 36 (4h): RevenueCat setup
- SDK integration
- Configuration in PlantHealthApp
- App Store Connect products created
- Sandbox tester account

Day 37-38 (8h): Subscription service
- SubscriptionService actor
- Status checking
- Purchase flow
- Restore purchases
- Error handling

Day 39 (4h): Apple Sign-In
- AuthService implementation
- Sign in with Apple button
- Anonymous → account migration
- Account deletion flow (App Store required)

Day 40-41 (8h): Paywall UI
- PaywallView (honest design)
- 4 tier cards (monthly, yearly, lifetime, family)
- Clear pricing display
- Restore purchases button visible
- Easy close button (App Store will reject if hidden)

Day 42 (4h): Free tier enforcement
- UsageTracker for scan limits
- 3 scans/month for free users
- Smart paywall triggers
- "Upgrade" CTAs in right places

**Week 6 Deliverable:** Working monetization, tested with sandbox

---

### **WEEK 7: Polish (28 hours)**

Day 43-44 (8h): Onboarding
- 4-screen onboarding flow
- Camera permission request
- Notification permission request
- Initial plant suggestion

Day 45 (4h): Animations & micro-interactions
- Smooth transitions everywhere
- Haptic feedback comprehensive
- Loading states refined
- Empty states with illustrations

Day 46 (4h): Dark mode perfection
- Test every screen
- Fix any contrast issues
- Verify Asset Catalog dark variants

Day 47 (4h): Accessibility
- VoiceOver labels everywhere
- Dynamic Type support
- Reduce Motion respect
- Color contrast WCAG AA

Day 48 (4h): Error states & recovery
- Friendly error messages
- Recovery actions
- Network error handling
- API rate limit handling

Day 49 (4h): App icon + branding
- Hire icon designer (Fiverr $30-50)
- All required sizes
- Adaptive icon
- Splash screen

**Week 7 Deliverable:** Production-quality polish

---

### **WEEK 8: ASO + Launch Prep (28 hours)**

Day 50-51 (8h): Screenshots design
- 8 App Store screenshots
- iPhone 15 Pro frames
- Caption text overlays
- Cream → Sage gradient backgrounds
- Consistent style

Day 52 (4h): App Store listing
- Title (keyword optimized)
- Subtitle (USP)
- Description (compelling copy)
- Keywords (research with App Annie)
- Promotional text

Day 53 (4h): Legal docs
- Privacy policy (use generator)
- Terms of service
- Subscription terms
- Apple-compliant language

Day 54-55 (8h): Final QA
- Test all flows on real device
- Edge case testing
- Memory profiling
- Network conditions (slow, offline)
- Multiple device sizes

Day 56 (4h): Build prep
- Bump version to 1.0.0
- Update build numbers
- Archive build
- App Store Connect upload

**Week 8 Deliverable:** Submission-ready build

---

### **WEEK 9: TestFlight Beta (28 hours)**

Day 57 (4h): Submit for TestFlight review
- Wait for Apple review (24-48 hours)

Day 58-60 (12h): Recruit beta testers
- Reddit: r/houseplants, r/plantclinic
- Twitter: plant influencer outreach
- Personal network: friends, family
- Target: 30-50 testers

Day 61-63 (12h): Feedback loop
- Collect feedback daily
- Fix critical bugs ASAP
- Update onboarding based on confusion
- Adjust paywall placement based on conversion

**Week 9 Deliverable:** 30+ beta testers, critical bugs fixed

---

### **WEEK 10: LAUNCH 🚀 (28 hours)**

Day 64 (4h): Final build
- Apply all beta feedback
- Final QA pass
- Build version 1.0.0
- Submit to App Store

Day 65-66 (8h): Wait for review
- Use time for marketing prep
- Twitter announcement draft
- ProductHunt launch prep
- Reddit posts drafted

Day 67 (4h): LAUNCH DAY
- App goes live!
- Tweet announcement
- ProductHunt submission
- Reddit posts (with permission from mods)
- Email personal network

Day 68-70 (12h): Post-launch
- Monitor reviews
- Respond to user feedback
- Track key metrics
- Plan v1.1 based on feedback

**Week 10 Deliverable:** LIVE on App Store with first 50-100 users

---

## 📂 Folder Structure (Memorize)

```
PlantHealth/
├── App/
│   ├── PlantHealthApp.swift
│   └── RootView.swift
│
├── Core/
│   ├── Services/
│   │   ├── AIService.swift              [Coordinator]
│   │   ├── PlantIdService.swift         [Plant.id API]
│   │   ├── GeminiService.swift          [Treatment AI]
│   │   ├── AppleVisionService.swift     [Pre-filter]
│   │   ├── AuthService.swift            [Apple Sign-In]
│   │   ├── SubscriptionService.swift    [RevenueCat]
│   │   ├── UsageTracker.swift           [Free tier]
│   │   ├── NotificationService.swift    [Local notifs]
│   │   ├── WeatherService.swift         [Climate]
│   │   └── ResponseCache.swift          [24h cache]
│   │
│   ├── Models/
│   │   ├── AppUser.swift               [@Model]
│   │   ├── Plant.swift                 [@Model]
│   │   ├── PlantScan.swift             [@Model]
│   │   ├── CareReminder.swift          [@Model]
│   │   ├── UserPreferences.swift       [@Model]
│   │   ├── PlantIdModels.swift         [Codable]
│   │   ├── GeminiModels.swift          [Codable]
│   │   └── PlantAnalysisResult.swift   [Codable]
│   │
│   └── Utilities/
│       ├── APIKeys.swift
│       ├── Logger+Extensions.swift
│       ├── UIImage+Optimization.swift
│       ├── Data+Hashing.swift
│       └── Components/
│           ├── PrimaryButton.swift
│           ├── SecondaryButton.swift
│           ├── HealthBadge.swift
│           ├── ConfidenceScoreView.swift
│           ├── PlantCard.swift
│           ├── EmptyStateView.swift
│           └── LoadingView.swift
│
├── Features/
│   ├── Onboarding/
│   ├── Home/
│   ├── Scan/
│   ├── Diagnosis/
│   ├── MyPlants/
│   ├── CareSchedule/
│   ├── Settings/
│   └── Paywall/
│
└── Resources/
    ├── Assets.xcassets
    ├── Localizable.xcstrings
    └── Config.plist (gitignored!)
```

---

## 💰 Pricing Strategy

```
FREE TIER (real value, not crippled):
├── 3 scans/month
├── 1 plant tracking
├── Basic care reminders
├── NO ads
└── All features visible (locked icon)

PRO MONTHLY: $4.99/month
├── Unlimited scans
├── Unlimited plants
├── Climate-aware care
├── Multi-angle scan
├── 7-day free trial (real, easy cancel)
└── 30-day refund guarantee

PRO ANNUAL: $29.99/year (50% off)
├── Same as monthly
└── Best value

LIFETIME: $79.99 one-time ⭐ (INDUSTRY FIRST)
├── Pay once, use forever
├── All current + future features
├── No subscription anxiety
└── Marketing gold

FAMILY: $49.99/year (5 users)
├── For households
├── Each member has own plants
└── Shared care responsibilities
```

---

## 🎯 Critical Success Metrics

Track these from Day 1:

### **Acquisition:**
- Daily downloads
- Source attribution
- Conversion: download → first scan
- Conversion: download → account creation

### **Engagement:**
- Day 1 retention (target: 60%+)
- Day 7 retention (target: 40%+)
- Day 30 retention (target: 20%+)
- Scans per user per week
- Plants added per user

### **Monetization:**
- Free → trial conversion (target: 10%+)
- Trial → paid conversion (target: 50%+)
- MRR
- LTV
- Churn rate (target: <5%/month)

### **Quality:**
- App Store rating (target: 4.7+)
- Crash-free rate (target: 99.5%+)
- API success rate (target: 95%+)
- Average AI confidence (target: 85%+)

---

## 🚀 Daily Workflow

### **Every Morning (10 min):**
1. Open `~/Projects/PlantHealth`
2. Pull latest git: `git pull`
3. Run `claude` in terminal
4. Paste session starter prompt
5. Confirm today's task with Claude

### **During Work:**
1. ONE feature at a time
2. Test in Simulator after each
3. Commit when working: `git commit -m "feat: X"`
4. Update PROGRESS.md
5. Take breaks every 90 min

### **End of Day:**
1. Final commit
2. Update PROGRESS.md (tomorrow's first task)
3. Push to GitHub
4. Note any blockers
5. Close laptop, rest

---

## 🆘 If Stuck

### **Decision Framework:**
1. Re-read this MASTER_PLAN.md
2. Check relevant skill file in `.claude/skills/`
3. Check `docs/USER_PAIN_POINTS.md` for "why" of features
4. Ask Claude with specific context
5. If still stuck after 30 min → skip, mark blocked, move on

### **Emergency Prompts:**

**Claude going off-track:**
```
STOP. Re-read MASTER_PLAN.md.
Only do what's in current week's tasks.
Revert any extras.
```

**Token usage too high:**
```
Be concise. No explanations unless asked.
Show only changed code.
One file at a time.
```

**Quality issues:**
```
This violates the rules.
Fix using the correct skill pattern.
```

---

## ⚠️ NEVER DO (Anti-Patterns)

Based on competitor failures:

### **Code:**
- ❌ Use UIKit (SwiftUI only)
- ❌ Use ObservableObject (use @Observable)
- ❌ Use Combine (async/await only)
- ❌ print() statements (use Logger)
- ❌ Force unwraps `!` in production
- ❌ Hardcode colors/strings
- ❌ Add features not in this week's plan
- ❌ Third-party libs without permission

### **UX:**
- ❌ Paywall on app open
- ❌ Hidden close button
- ❌ Watch ads for credits
- ❌ Auto-charge without clear warning
- ❌ Hide cancellation
- ❌ Generic care advice
- ❌ Hide AI confidence

### **Business:**
- ❌ Promise features not built
- ❌ Inflate accuracy numbers
- ❌ Copy competitor screenshots
- ❌ Use customer data for ads
- ❌ Sell user data ever

---

## 🎯 The Mental Model

### **Every day, ask:**
1. Did I solve a real user pain today?
2. Did I ship something working?
3. Did I update PROGRESS.md?
4. Am I on track for week's deliverable?
5. Did I commit my code?

### **Every week, ask:**
1. Did I hit weekly deliverable?
2. What slowed me down?
3. What can I cut for next week?
4. Am I still building from user pain?
5. Is the timeline still realistic?

### **Every Friday night:**
- Week review
- Update PROGRESS.md
- Plan next week's first task
- Rest weekend (no work guilt)

---

## 🏆 Success Vision (10 Weeks From Now)

**Week 10 + 1 day:**
- ✅ Live on App Store
- ✅ 50-100 first users
- ✅ First paying customer
- ✅ 4.5+ star rating
- ✅ Clear path to $1K MRR

**Month 3:**
- ✅ 1,000-3,000 users
- ✅ $500-3K MRR
- ✅ Active feedback loop
- ✅ v1.1, v1.2 shipped
- ✅ Plant.id partnership talks

**Month 6:**
- ✅ 5,000-10,000 users
- ✅ $5K-10K MRR
- ✅ ProductHunt featured
- ✅ Press mentions
- ✅ Considering full-time

**Month 12:**
- ✅ 15,000-30,000 users
- ✅ $20K-50K MRR
- ✅ Replace day job income
- ✅ Hire first contractor
- ✅ Android version planned

---

## 🔥 Your Edge

### **Why you'll win:**
1. **You read 1,000 negative reviews** - users want the opposite
2. **You have better AI** - Plant.id beats competitors
3. **You're a solo founder** - faster than committees
4. **You have Claude Code** - 10x productivity
5. **You target global market** - bigger opportunity
6. **You have honest pricing** - users desperately want this
7. **You're shipping in 10 weeks** - momentum compounds

### **Why most fail:**
- ❌ Build too many features
- ❌ Delay launch perfectionism
- ❌ Copy competitors blindly
- ❌ Don't read user complaints
- ❌ Run out of motivation
- ❌ Get stuck in tooling

**You won't, because you have this plan.**

---

## 🚀 START NOW (Next 5 Minutes)

1. **Save this file** somewhere visible (desktop, pinned tab)
2. **Read it once completely** (you're doing it now)
3. **Tomorrow morning:**
   - Sign up Plant.id
   - Test 10 plant photos
   - Install Claude Code
   - Open Terminal, navigate to project
   - Run `claude`
   - Paste session starter

### **First Session Prompt (Copy This):**

```
Read MASTER_PLAN.md completely.
Read .claude/tracking/PROGRESS.md.

Today is Week 0 / Day -3 (or wherever I am).

Confirm:
1. You understand the tech stack
2. You understand the 15 differentiators
3. You understand the 10-week sprint plan
4. You'll only build what's in current week

Then tell me my next task per PROGRESS.md.
Wait for me to say "go" before coding.
```

---

## 📞 Remember

**Speed > Perfection**
**Shipping > Polishing**
**Real users > Imaginary features**
**Daily progress > Weekly bursts**

**bhai, ekhon shudhu execute koro. plan ready. tools ready. timeline ready. just BUILD.** 🚀

---

*This is your single source of truth. Everything else (PROGRESS.md, skills, docs) supports this plan.*

*Last updated: May 16, 2026*
*Version: 1.0 - Production Ready*
