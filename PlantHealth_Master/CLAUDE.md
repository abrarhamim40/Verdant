# PlantHealth - Claude Code Configuration

> **CRITICAL:** Read MASTER_PLAN.md and PROGRESS.md at the start of EVERY session.

---

## 🎯 Quick Context

**Building:** PlantHealth - iOS plant identification + disease detection app
**Stack:** SwiftUI + SwiftData + Plant.id API + Gemini + RevenueCat
**Timeline:** 10 weeks to App Store launch
**Tagline:** "The honest plant app. Built from 1,000 angry reviews."

**For complete plan, decisions, weekly tasks → READ `MASTER_PLAN.md`**

---

## 📋 Rules I Must Follow

### **Code Quality:**
- SwiftUI declarative only (NO UIKit)
- iOS 17+ APIs (@Observable, SwiftData, .task)
- async/await (NO Combine, NO completion handlers)
- Structs > Classes when possible
- NO force unwraps (!) in production
- NO print() (use os.Logger)
- Files under 300 lines (split if more)
- All errors handled with custom Error types
- All async work has loading + error states

### **Architecture:**
- Services are `actor` types
- Three layers: Views → Services → Data
- API keys ONLY in Config.plist (gitignored)
- Use Asset Catalog for colors (no hex in code)
- Use String Catalog for text (no hardcoded strings)
- Dark mode mandatory
- Accessibility labels required

### **What I'll NEVER Do:**
- ❌ Add features not in current week's plan
- ❌ Refactor working code unless asked
- ❌ Add third-party libraries without permission
- ❌ Generate boilerplate explanations
- ❌ Use deprecated APIs
- ❌ Skip error handling
- ❌ Promise features I can't build

---

## 📂 Project Files

```
Root files Claude reads:
├── MASTER_PLAN.md           ⭐ Single source of truth
├── CLAUDE.md                You're reading this
└── README.md                Project overview

.claude/ directory:
├── PROMPTS.md               Ready-to-paste prompts
├── tracking/PROGRESS.md     Where we are right now
├── skills/                  How-to patterns
│   ├── swiftui-views.md
│   ├── ai-integration.md
│   ├── swiftdata-models.md
│   ├── auth-system.md
│   ├── revenuecat-setup.md
│   ├── notifications.md
│   └── design-components.md
└── commands/                Slash commands

docs/ directory:
├── ARCHITECTURE.md          Folder structure + patterns
├── USER_PAIN_POINTS.md      Real user complaints we solve
└── DESIGN_SYSTEM.md         Colors, fonts, components
```

---

## 🎨 Design System (Quick Reference)

**Colors (use Asset Catalog):**
- ForestGreen `#1B4332` / `#52796F` (dark)
- Sage `#52796F` / `#95B5A8` (dark)
- Terracotta `#D68C45` / `#E8A867` (dark)
- BackgroundPrimary `#FAF7F0` / `#0F1B14` (dark)

**Typography:**
- Display: SF Pro Serif (New York) - hero text
- UI: SF Pro - body, buttons

**Spacing:** 4, 8, 12, 16, 20, 24, 32, 48 (only these values)
**Corner radius:** 8 (badges), 12-16 (cards), 20-24 (hero)

---

## 🤖 AI Pipeline (Memorize)

```
User photo
    ↓
Apple Vision (FREE) → Is this a plant?
    ↓
Plant.id API ($0.10) → ID + Disease + Confidence
    ↓
Gemini 2.5 Pro ($0.001) → Personalized treatment
    ↓
Cache result (24h)
    ↓
Show user with confidence %
```

---

## 💰 Pricing (Final)

- Free: 3 scans/month, NO ads
- Pro Monthly: $4.99 (7-day trial)
- Pro Annual: $29.99
- **Lifetime: $79.99** ⭐ (unique)
- Family: $49.99/year (5 users)

---

## ✅ Session Start Protocol

Every session, I'll:

1. Read MASTER_PLAN.md
2. Read .claude/tracking/PROGRESS.md
3. Tell you:
   - Last completed task
   - Today's planned task
   - Any blockers from last session
4. Wait for your "go" before coding

---

## 🆘 If Confused

Decision tree:
1. Check current week in MASTER_PLAN.md
2. Check today's task in PROGRESS.md
3. Find relevant skill in .claude/skills/
4. Reference USER_PAIN_POINTS.md for "why"
5. If still unclear → ASK, don't assume

---

## 🎯 Current Phase

**Check PROGRESS.md for current week and task.**

The Master Plan dictates what gets built when.
PROGRESS.md tracks where we are.
Skills tell me HOW to build it.
User pain points tell me WHY.

**Always work within this week's scope. Never get ahead.**
