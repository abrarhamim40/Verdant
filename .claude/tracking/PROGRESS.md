# PlantHealth Progress Tracker

**Current Status:** 🟢 Week 4 Day 26-27 complete on `feat/plant-detail-refine` — build green, all 27 tests pass. Day 28 deferred (no paid Apple Developer account yet).
**Days until launch:** 66 days
**Last session:** 2026-05-18 — Committed Day 24-25 + Vision hotfix + app icon + Day 26 (ScanHistoryTimeline). Refactor: extracted LatestScanSection + PlantHeroHeader so PlantDetailView fits under 300. Day 27: EditPlantSheet, AddPlantSheet, wired toolbar Edit/Delete (confirmation dialog), "+" toolbar in PlantListView, spring transitions on grid add/remove. Build fix: added `import os` to PlantDetailView. Smoke test passed on iPhone 17 sim. Day 28 (CloudKit sync) needs paid Apple Developer account ($99/yr) for the iCloud capability — code is already `.automatic`, sync will start working as soon as the entitlement is added; no code refactor needed at that point.
**Next task:** Merge `feat/plant-detail-refine` → main → start Day 29-30 on `feat/care-reminders` branch (CareReminder logic + local notifications + permission flow).

---

## 🎯 TODAY's Task

```
□ Sign up at web.plant.id
□ Get free API key (100 calls/month)
□ Test 10 different plant photos
□ Verify accuracy is 90%+ on real plants
□ Note any disease detection accuracy
□ Save API key to password manager
```

**Once done, next task:** Install Claude Code + open Xcode

---

## 📊 Week-by-Week Progress

### **WEEK 0: Setup** 🟡 IN PROGRESS

- [ ] Mac M2 ready ✅
- [ ] Xcode 15+ installed
- [ ] Node.js 18+ installed
- [ ] Claude Code installed (`npm install -g @anthropic-ai/claude-code`)
- [ ] Plant.id API key obtained
- [ ] Plant.id tested with 10 real plants
- [ ] Gemini API key obtained
- [ ] RevenueCat account created
- [ ] Project folder created at `~/Projects/PlantHealth`
- [ ] Master plan files extracted
- [ ] Git initialized
- [ ] First Claude Code session run

### **WEEK 1: Foundation** 🟡 IN PROGRESS

- [x] Day 1: Xcode project + folder structure + Asset Catalog (+ Config.plist, APIKeys, Logger, RootView shell)
- [x] Day 2: SwiftData models (AppUser, Plant, PlantScan, CareReminder, UserPreferences) + ModelContainer with CloudKit (.automatic)
- [x] Day 3: AIError enum + UIImage+Optimization + Data+Hashing (SHA256) + ResponseCache actor (24h TTL)
- [x] Day 4: PlantIdModels (Codable) + PlantIdService actor (cache-wired, AIError-mapped) + 8 unit tests
- [x] Day 5: GeminiModels + GeminiService actor (Gemini 2.5 Pro, JSON output mode, markdown stripping) + 10 unit tests
- [x] Day 6: AppleVisionService (on-device pre-filter) + PlantAnalysisResult (combined model) + AIService coordinator (Vision → Plant.id → Gemini, 24h cache) + 9 tests
- [x] Day 7: TabView shell polish — Color+Verdant typed extension, @SceneStorage tab persistence, in-memory ModelContainer preview

**Deliverable:** App opens, scans 1 plant successfully ✅

### **WEEK 2-3: Core Scan Flow** 🟡 IN PROGRESS

Week 2:
- [x] Day 8: ScanView with PhotosPicker (1-3 photos), photo grid + remove × per card, image optimization wired (UIImage → 1024px JPEG Data), placeholder Identify button
- [x] Day 9: Live camera (CameraPicker UIVC bridge, simulator falls back to library), PhotoGuidanceTips component (4 composition tips card), toolbar lightbulb opens medium-detent sheet
- [x] Day 10-11: ScanningView state machine (running / success / failure / cancelled) + cycling status messages + cancel button + retry on error + AIService end-to-end wired + ScanRequest navigation type
- [x] Day 12-13: DiagnosisResultView (photo header + identification + disease + treatment + warnings + prevention + collapsible alternatives) + ConfidenceScoreView (ring/pill) + HealthBadge (healthy/watch/treat/critical) components
- [x] Day 14: SavePlantSheet (nickname + location + sunlight + indoor/outdoor + grow light) writes Plant + PlantScan to SwiftData with success haptic, heart toolbar toggles `heart` ↔ `heart.fill`, minimal MyPlants list + tap → PlantDetailView (photo + care setup + latest scan analysis decoded from analysisJSON + relative date) — Day 22-25 will replace both with full grid + history timeline + edit

Week 3:
- [x] Day 15-16: TreatmentStepsView (reusable, compact mode for detail screen) + SourceCitationsView (Plant.id v3 attribution + Wikipedia tap link + CC BY-SA license + AI-generated flag), PlantAnalysisResult now carries top match's PlantDetails so citations link the right article
- [x] Day 17-18: Vision pre-filter polish — nonisolated static keyword set/threshold/`detectsPlant` helper (testable), DEBUG top-5 classification logging, AIService checks all images instead of just first one, 8 unit tests
- [x] Day 19: Multi-angle improvement — Plant.id was already getting all photos; threaded real `photoCount` through ScanningView → DiagnosisResultView → SavePlantSheet → PlantScan (was hardcoded 1/false), "X angles" badge surfaces on diagnosis + plant detail when ≥2 photos used
- [x] Day 20-21: Polish — `Haptics` enum (selection/impact/success/error/warning), wired into scan flow + save + retry + cancel + alternatives toggle, state transition animations in ScanningView (opacity+scale success / opacity+slide-up failure), spring animations on photo grid add/remove/load

**Deliverable:** Complete scan flow end-to-end ✅

### **WEEK 4: My Plants** 🟡 IN PROGRESS

- [x] Day 22-23: PlantCard (square card with photo + name + location/scientific + health dot) + PlantListView (2-col LazyVGrid, searchable, filter chips Indoor/Outdoor/Grow light, sort menu) — replaces minimal list from Day 14. ALSO bug-fix: Plant.id v3 health detection moved to separate /health_assessment endpoint with parallel async let calls + graceful degradation.
- [x] Day 24-25: PlantDetailView refinement — hero photo with overlaid serif title + scientific name, 2x2 care setup tile grid, full TreatmentStepsView, inline disease description, no-scan fallback, toolbar ellipsis menu (Edit + Delete stubs for Day 27). Also: Vision pre-filter hotfix (threshold 0.3→0.15 + simulator skip — was rejecting valid scans in dev) and placeholder 1024 app icon to silence Xcode warning.
- [x] Day 26: ScanHistoryTimeline — vertical timeline of every previous PlantScan with health-colored dots, photo journal style. Latest scan stays as hero card above. Hidden when only one scan exists.
- [x] Day 27: EditPlantSheet (mutates nickname/location/sunlight/indoor/outdoor/growLight), AddPlantSheet (manual entry — no scan needed), toolbar Edit + Delete wired in PlantDetailView with confirmationDialog, "+" toolbar button in PlantListView, spring scale+opacity transition on grid add/remove. Refactor: split PlantDetailView into PlantHeroHeader + LatestScanSection so each file fits the 300-line guideline.
- [⏸️] Day 28: CloudKit sync verification — DEFERRED, needs paid Apple Developer account. Models verified CloudKit-compatible (all properties default/optional, to-many relationships optional, inverses set, no .unique). ModelContainer already `.automatic`, so adding the entitlement later = zero code change. Bundle with Day 35 + Week 6 monetization when account is purchased.

**Deliverable:** Plant management across devices

### **WEEK 5: Care Schedule** 🟡 STARTING NEXT

- [ ] Day 29-30: Reminder system + local notifications (permission flow, UNUserNotificationCenter)
- [ ] Day 31-32: ScheduleView + ReminderCard (today's tasks, complete/snooze/skip)
- [ ] Day 33: Manual care override ⭐ (KEY DIFFERENTIATOR — sliders, custom intervals)
- [ ] Day 34: Task undo + history ⭐ (KEY DIFFERENTIATOR — long-press undo, backdate)
- [⏸️] Day 35: Climate awareness — DEFERRED, WeatherKit needs paid Apple Developer account. Bundle with Day 28.

**Deliverable:** Smart care with customization (climate layer added later)

### **WEEK 6: Monetization** ⏳ PENDING

- [ ] Day 36: RevenueCat setup
- [ ] Day 37-38: SubscriptionService
- [ ] Day 39: Apple Sign-In
- [ ] Day 40-41: PaywallView (honest)
- [ ] Day 42: Free tier enforcement

**Deliverable:** Working monetization

### **WEEK 7: Polish** ⏳ PENDING

- [ ] Day 43-44: Onboarding (4 screens)
- [ ] Day 45: Animations + haptics
- [ ] Day 46: Dark mode perfection
- [ ] Day 47: Accessibility
- [ ] Day 48: Error states
- [ ] Day 49: App icon + branding

**Deliverable:** Production-quality polish

### **WEEK 8: ASO + Launch Prep** ⏳ PENDING

- [ ] Day 50-51: Screenshots design (8)
- [ ] Day 52: App Store listing
- [ ] Day 53: Legal docs
- [ ] Day 54-55: Final QA
- [ ] Day 56: Build prep + upload

**Deliverable:** Submission-ready build

### **WEEK 9: TestFlight** ⏳ PENDING

- [ ] Day 57: Submit TestFlight
- [ ] Day 58-60: Recruit 30+ beta testers
- [ ] Day 61-63: Feedback + bug fixes

**Deliverable:** Beta tested, bugs fixed

### **WEEK 10: LAUNCH** 🚀 PENDING

- [ ] Day 64: Final build + submit
- [ ] Day 65-66: Wait for review (marketing prep)
- [ ] Day 67: LAUNCH DAY
- [ ] Day 68-70: Post-launch monitoring

**Deliverable:** LIVE on App Store with first 50-100 users

---

## 📝 Session Log

### Session 0 - Setup Planning
**Date:** [Today]
**Tasks completed:**
- Project plan finalized
- Tech stack decided
- All documentation prepared
- Master plan created

**Blockers:** None

**Next session start with:**
- Sign up Plant.id
- Test 10 plant photos
- Validate accuracy

---

## 🐛 Issues Tracking

### Active Issues:
- None yet

### Resolved Issues:
- None yet

---

## 💡 Ideas Parking Lot

Don't build now, but worth remembering:

- AR plant placement (Phase 2)
- Plant marketplace (affiliate revenue)
- Community/social features (Phase 2)
- Expert botanist verification ($2/consult)
- Bird/insect identification expansion
- Plant trading feature
- Garden planning tool
- Greenhouse mode
- Indoor air quality estimation
- Plant compatibility checker (companion planting)

---

## 🎯 Key Decisions Made

**2026-05-16:**
- ✅ Plant.id over GPT/Gemini-only for accuracy
- ✅ Global target market (not South Asia only)
- ✅ SwiftUI only, iOS first
- ✅ Pricing: $4.99/mo, $29.99/yr, $79.99 lifetime
- ✅ MV pattern over MVVM
- ✅ Apple Sign-In only initially (not Auth0)
- ✅ Local notifications only initially (not Firebase yet)
- ✅ Skip Supabase until Year 2

---

## 📊 Metrics to Track

Once launched, track daily:

| Metric | Target | Current |
|--------|--------|---------|
| Daily downloads | 50+ | - |
| Day 1 retention | 60%+ | - |
| Day 7 retention | 40%+ | - |
| App Store rating | 4.7+ | - |
| Free → Pro conv | 5%+ | - |
| Trial → Paid conv | 50%+ | - |
| MRR | $1K Month 1 | - |
| Crash-free rate | 99.5%+ | - |

---

## 🚀 Daily Workflow Reminder

```
Morning (10 min):
1. cd ~/Projects/PlantHealth
2. git pull
3. claude
4. Paste session starter from PROMPTS.md
5. Confirm task with Claude

During work:
- ONE feature at a time
- Test in Simulator after each
- Commit working code
- Update this file

End of day:
- Final commit + push
- Update this file
- Note tomorrow's first task
- Rest
```

---

## ⚡ Quick Commands

```bash
# Start Claude Code
cd ~/Projects/PlantHealth && claude

# Commit work
git add . && git commit -m "feat: [description]"

# Push to GitHub
git push origin main

# Run tests
xcodebuild test -scheme PlantHealth

# Clean build
xcodebuild clean -scheme PlantHealth
```

---

**Update this file at the end of EVERY session. No exceptions.**

**This file = your accountability partner.**
