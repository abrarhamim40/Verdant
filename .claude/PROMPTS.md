# Claude Code Prompts - Copy & Paste Ready

> Use these prompts to save time and tokens.

---

## 🟢 SESSION STARTER (Every Session)

```
Read MASTER_PLAN.md and .claude/tracking/PROGRESS.md.

Then tell me briefly:
1. What week/day am I on per the plan?
2. What was the last completed task?
3. What's today's task?
4. Any blockers from last session?

Wait for my "go" before coding.
```

---

## 🚀 FIRST EVER SESSION (Run Once)

```
This is the first session for PlantHealth iOS app.

Tasks:
1. Verify all required files exist:
   - MASTER_PLAN.md (root)
   - CLAUDE.md
   - .claude/tracking/PROGRESS.md
   - .claude/skills/*.md (5 files)
   - docs/*.md (3 files)

2. Read MASTER_PLAN.md completely
3. Confirm you understand:
   - The 10-week sprint plan
   - Tech stack (SwiftUI, Plant.id, Gemini)
   - 15 differentiators based on user pain
   - Daily workflow

4. Tell me Week 1 Day 1 task in detail

Don't code yet. Just understand and plan.
```

---

## 🛠️ WEEKLY KICKOFF

```
Starting Week [X] today.

Read this week's section in MASTER_PLAN.md.
List all daily tasks for this week.
Identify any dependencies from previous weeks.

Then start with Day [X] task per plan.
Show me the plan before coding.
```

---

## 📦 BUILD SWIFTUI VIEW

```
Build [VIEW_NAME] following .claude/skills/swiftui-views.md

Location: Features/[FOLDER]/[VIEW_NAME].swift

Requirements:
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

Constraints:
- iOS 17+ APIs only
- Include #Preview macro
- Max 200 lines
- Use Asset Catalog colors
- Accessibility labels required
- Include loading + error states

Show plan first (3-5 bullets), then build.
```

---

## 🤖 AI SERVICE TASK

```
Implement [FEATURE] following .claude/skills/ai-integration.md

Use existing AIService - don't duplicate.
Handle errors: [list specific errors]
Cache strategy: [specify if different from default]

Test with these scenarios:
- [scenario 1]
- [scenario 2]
- [scenario 3]
```

---

## 💾 SWIFTDATA MODEL

```
Create SwiftData model for [ENTITY].

Follow .claude/skills/swiftdata-models.md patterns.

Properties:
- [property 1]: [type]
- [property 2]: [type]

Relationships:
- [relationship 1]

Include:
- Preview data
- Convenience initializers
- Computed properties needed

Add to Schema in PlantHealthApp.swift.
```

---

## 💰 REVENUECAT FEATURE

```
Add [FEATURE] following .claude/skills/revenuecat-setup.md

Premium check: SubscriptionService.shared.isPremium
Paywall trigger: [specific trigger condition]
Free tier limit: [number] per [period]

Required UX:
- Clear pricing display
- Easy close button
- Restore purchases visible
- One-tap cancellation
```

---

## 🎨 DESIGN COMPONENT

```
Build [COMPONENT_NAME] following .claude/skills/design-components.md

Used in: [list views that will use it]
Variants needed: [primary/secondary/etc]
States: default, pressed, disabled

Theme:
- Use Asset Catalog colors
- Support dark mode
- Accessibility compliant

Place in: Core/Utilities/Components/
```

---

## 🐛 BUG FIX

```
Bug report:
- File: [filename]
- Expected: [what should happen]
- Actual: [what happens instead]
- Steps: [how to reproduce]
- Error: [error message if any]

Fix this bug ONLY. Don't refactor.
Show changed lines with file path + line numbers.
```

---

## 🔍 CODE REVIEW

```
Review [FILE_NAME] for:
1. SwiftUI best practices per swiftui-views.md
2. MASTER_PLAN.md rule compliance
3. Memory leaks or retain cycles
4. Deprecated API usage
5. Missing error handling

List issues with severity (critical/medium/low).
Don't fix yet - I'll decide which to address.
```

---

## 🎯 FEATURE PLANNING

```
I want to add [FEATURE_NAME].

Before coding:
1. Confirm this is in current week's plan
2. List files needed (new + modified)
3. Skills to reference
4. Estimated time (hours)
5. Edge cases to handle
6. Testing approach

If NOT in this week's plan, push back.
Don't build until I approve.
```

---

## 🎬 END OF SESSION

```
Session complete. Please:

1. Update .claude/tracking/PROGRESS.md:
   - Mark completed tasks ✅
   - Add session log entry with date
   - List files created/modified
   - Set tomorrow's first task

2. Summary (max 10 lines):
   - What we built
   - What's working
   - What's broken (if anything)
   - Tomorrow's first action

Then I'll commit and end session.
```

---

## 🚨 EMERGENCY: Claude Off-Track

```
STOP. You're adding features I didn't request.

Re-read MASTER_PLAN.md current week section.
Revert any extra additions.
Only do what's explicitly in today's task per PROGRESS.md.

Show me what you'll do BEFORE coding.
```

---

## 🚨 EMERGENCY: Too Verbose

```
Be concise:
- No explanations unless I ask
- Show only changed code (not full files)
- Use file paths instead of "here's the code"
- One file at a time
- Bullet points over paragraphs
```

---

## 🚨 EMERGENCY: Quality Issues

```
This violates MASTER_PLAN.md rules.

Specific violation: [identify it]

Use the correct pattern from .claude/skills/[skill].md

Fix it now.
```

---

## 🚨 EMERGENCY: Need Fresh Context

```
/clear

[Then paste session starter prompt again]
```

---

## 💡 EFFICIENT WORKFLOWS

### **Quick Daily Start (30 seconds):**
```
Continue from yesterday.
Today's task per PROGRESS.md.
Go.
```

### **Quick Bug Fix (1 minute):**
```
Bug in [file]: [issue]
Fix only.
Show changes.
```

### **Quick Component:**
```
Build [component] per design-components.md.
Standard styling.
Include #Preview.
```

---

## 📊 SLASH COMMANDS REFERENCE

Use these built-in Claude Code commands:

- `/clear` - Clear context (use between major tasks)
- `/compact` - Summarize old conversation
- `/help` - Show available commands
- `/cost` - Show token usage
- `/exit` - End session

---

## 💡 PROMPT WRITING RULES

### **Good Prompts:**
✅ "Add image compression to UIImage+Compression.swift, max 1024x1024, JPEG 0.75"

### **Bad Prompts:**
❌ "Help me with images please"

### **Rules:**
1. **Specific** - exact file names, exact requirements
2. **Reference skills** - "follow ai-integration.md" not "explain how to..."
3. **One thing** - don't bundle multiple requests
4. **Constraints upfront** - iOS version, max lines, etc.
5. **Decide first** - don't ask "what do you think?"
6. **Bullets > paragraphs** - cleaner, faster
7. **Acceptance criteria** - "when X works, done"

---

## 🎯 Token Optimization Tips

### **Save tokens by:**
1. Using `/clear` between major features
2. Reference files: "per ai-integration.md" instead of explaining
3. Ask for diffs, not full files
4. Use bullets in prompts
5. End sessions when feature complete
6. Don't ask Claude to "think out loud"

### **Waste tokens by:**
1. Pasting same code repeatedly
2. Long conversational prompts
3. Asking for explanations you don't need
4. Multiple unrelated tasks in one prompt
5. Not using session starter (Claude re-discovers context)

---

## 🎯 Mental Model

**Treat Claude Code like a fast junior developer:**
- Give clear specs
- Reference patterns to follow
- Check work before merging
- Don't let it scope-creep
- Stay in charge of architecture

**You're the PM. Claude is the developer.**

---

**Copy these prompts to a notes app for quick access.**
**Customize as needed for your workflow.**
**The faster you can prompt, the faster you ship.** 🚀
