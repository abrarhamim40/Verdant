# PlantHealth Progress Tracker

**Current Status:** 🟢 Week 3 Day 19 — Multi-angle improvement on `feat/multi-angle` (Xcode registration pending)
**Days until launch:** 67 days
**Last session:** 2026-05-17 — Day 17-18 merged; Day 19 threaded real `photoCount` through DiagnosisResultView → SavePlantSheet → PlantScan model (was hardcoded 1), added "X angles" badge on diagnosis + plant detail when ≥2 photos used
**Next task:** Build → 2-photo scan → see multi-angle badge → save → My Plants → tap → detail also shows badge → Day 20-21 (Polish scan flow: animations, haptics, empty states, test 20+ plants).

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
- [ ] Day 5: GeminiService + treatment parsing
- [ ] Day 6: AIService coordinator + caching
- [ ] Day 7: TabView shell + navigation

**Deliverable:** App opens, scans 1 plant successfully

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
- [ ] Day 14: Save to plants flow

Week 3:
- [ ] Day 15-16: Treatment view + sources
- [ ] Day 17-18: Apple Vision pre-filter
- [ ] Day 19: Multi-angle improvement
- [ ] Day 20-21: Polish + 20 plant tests

**Deliverable:** Complete scan flow end-to-end

### **WEEK 4: My Plants** ⏳ PENDING

- [ ] Day 22-23: PlantListView grid
- [ ] Day 24-25: PlantDetailView
- [ ] Day 26: Scan history timeline
- [ ] Day 27: Add/edit/delete plants
- [ ] Day 28: CloudKit sync verification

**Deliverable:** Plant management across devices

### **WEEK 5: Care Schedule** ⏳ PENDING

- [ ] Day 29-30: Reminder system + notifications
- [ ] Day 31-32: ScheduleView + ReminderCard
- [ ] Day 33: Manual care override ⭐
- [ ] Day 34: Task undo + history ⭐
- [ ] Day 35: Climate awareness

**Deliverable:** Smart care with customization

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
