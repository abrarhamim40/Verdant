# Setup Checklist (Day -3 to Day 0)

> Complete this BEFORE writing any code. Estimated time: 3-4 hours total.

---

## 🛠️ Day -3: Tools Install (1 hour)

### **Mac Setup:**
- [ ] macOS Sonoma 14.0+ (or Sequoia)
- [ ] At least 50GB free disk space
- [ ] Stable internet connection

### **Xcode:**
- [ ] Install Xcode 15+ from Mac App Store
- [ ] Open Xcode once (accepts license)
- [ ] Install iOS 17 Simulator
- [ ] Test: Create dummy project, run on simulator
- [ ] Sign in with Apple ID (Xcode → Settings → Accounts)

### **Node.js (for Claude Code):**
```bash
# Check if installed
node --version  # Should be 18+

# If not installed:
brew install node
# OR download from nodejs.org
```

### **Claude Code:**
```bash
# Install globally
npm install -g @anthropic-ai/claude-code

# Verify
claude --version

# Login (first time)
claude
# Follow prompts to authenticate
```

### **Git:**
```bash
# Should be pre-installed on macOS
git --version

# Configure (if first time)
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

### **Optional but Recommended:**
- [ ] Cursor or VS Code (for non-Xcode editing)
- [ ] Raycast (productivity)
- [ ] Rectangle (window management)
- [ ] 1Password or Bitwarden (API key storage)

---

## 🔑 Day -2: API Accounts (1.5 hours)

### **1. Plant.id API** ⭐ CRITICAL
- [ ] Sign up: https://web.plant.id
- [ ] Verify email
- [ ] Go to Dashboard → API Keys
- [ ] Copy API key
- [ ] Save in 1Password as "Plant.id API Key"
- [ ] Note: Free tier = 100 calls/month

**Test the API immediately:**
```bash
curl -X POST "https://plant.id/api/v3/identification" \
  -H "Api-Key: YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "images": ["base64_image_here"],
    "health_assessment": true
  }'
```

### **2. Gemini API** ⭐ CRITICAL
- [ ] Sign up: https://aistudio.google.com
- [ ] Click "Get API Key"
- [ ] Create new project
- [ ] Copy API key
- [ ] Save in 1Password as "Gemini API Key"
- [ ] Note: Free tier = 50 requests/day

### **3. RevenueCat** (for subscriptions)
- [ ] Sign up: https://app.revenuecat.com
- [ ] Verify email
- [ ] DON'T create app yet (need App Store Connect first)
- [ ] Note: Free under $10K MRR

### **4. Apple Developer Account** (optional for dev, required for launch)
- [ ] Sign up: https://developer.apple.com ($99/year)
- [ ] Can defer until Week 8 (TestFlight prep)
- [ ] OR start now if budget allows

### **5. Optional Analytics:**
- [ ] PostHog: https://posthog.com (free 1M events/mo)
- [ ] Sentry: https://sentry.io (free 5K events/mo)
- [ ] These can wait until Week 7

---

## 🧪 Day -1: Validation Testing (1 hour)

### **Critical: Test Plant.id Accuracy**

Pick 10 different plants you can photograph:
- 3 houseplants (Monstera, Snake plant, Pothos)
- 2 succulents
- 2 outdoor plants
- 2 herbs
- 1 unhealthy plant (yellowing/spots)

**For each plant:**
1. Take clear photo (good lighting)
2. Upload to Plant.id Playground: https://web.plant.id/playground
3. Note:
   - Identified correctly? ✅/❌
   - Confidence %
   - Variety/species detected?
   - Disease detected (if unhealthy)?

**Expected results:**
- 90%+ accuracy on healthy plants
- 80%+ accuracy on unhealthy plants
- Variety detection on most plants

### **Test Gemini Treatment Generation:**

Send this prompt to Gemini API or aistudio:
```
You are an expert botanist. Generate a care plan in English.

Plant: Monstera deliciosa
Common names: Swiss cheese plant
Detected issue: Yellow leaves
Confidence: 87%

Respond with ONLY valid JSON:
{
  "summary": "...",
  "immediate_actions": [...],
  "weekly_care": [...]
}
```

**Verify:**
- Valid JSON returned
- Reasonable advice
- Specific measurements (e.g., "1 cup water")
- No hallucinations

---

## 📂 Day 0: Project Setup (30 minutes)

### **Create Project Folder:**
```bash
mkdir -p ~/Projects/PlantHealth
cd ~/Projects/PlantHealth
```

### **Extract Master Plan:**
- [ ] Unzip the PlantHealth_Master.zip you received
- [ ] Move ALL contents to ~/Projects/PlantHealth/
- [ ] Verify structure:
```
~/Projects/PlantHealth/
├── MASTER_PLAN.md
├── CLAUDE.md
├── README.md
├── SETUP_CHECKLIST.md (this file)
├── .claude/
│   ├── PROMPTS.md
│   ├── tracking/PROGRESS.md
│   └── skills/...
└── docs/
    ├── USER_PAIN_POINTS.md
    └── ARCHITECTURE.md
```

### **Initialize Git:**
```bash
cd ~/Projects/PlantHealth

# Create .gitignore FIRST (before any commits)
cat > .gitignore << 'EOF'
# Xcode
build/
DerivedData/
*.xcuserstate
*.xcuserdata/
.DS_Store
xcuserdata/
*.xcscmblueprint
*.xccheckout

# Sensitive
Config.plist
*.xcconfig
.env

# CocoaPods
Pods/

# Swift Package Manager
.swiftpm/
Package.resolved

# fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output

# IDE
.vscode/
.idea/

# OS
.DS_Store
.AppleDouble
.LSOverride
EOF

# Initialize
git init
git add .
git commit -m "Initial setup: master plan + skills"
```

### **Optional: GitHub Repo**
- [ ] Create new repo at github.com/new
- [ ] Make it PRIVATE
- [ ] Push:
```bash
git remote add origin https://github.com/YOURNAME/planthealth.git
git branch -M main
git push -u origin main
```

---

## ✅ First Claude Code Session

### **Start Claude Code:**
```bash
cd ~/Projects/PlantHealth
claude
```

### **First Prompt (Copy & Paste):**
```
This is the first session for PlantHealth iOS app.

Tasks:
1. Verify all required files exist:
   - MASTER_PLAN.md (root)
   - CLAUDE.md
   - .claude/tracking/PROGRESS.md
   - .claude/skills/*.md (5 files)
   - docs/*.md (2 files)

2. Read MASTER_PLAN.md completely
3. Confirm you understand:
   - The 10-week sprint plan
   - Tech stack (SwiftUI, Plant.id, Gemini)
   - 15 differentiators based on user pain
   - Daily workflow

4. Tell me Week 1 Day 1 task in detail

Don't code yet. Just understand and plan.
```

### **Expected Claude Response:**
Claude should:
- Confirm reading all files
- Summarize the tech stack
- List Week 1 Day 1 task
- Ask for your "go" before coding

If Claude doesn't do this → repeat the prompt with stronger emphasis on reading files first.

---

## 🎯 Final Pre-Flight Check

Before Day 1, verify:

### **Tools:**
- [ ] Xcode opens and runs simulator
- [ ] Claude Code installed and working
- [ ] Git configured
- [ ] All API keys saved in 1Password

### **APIs Tested:**
- [ ] Plant.id returned good results on 10 plants
- [ ] Gemini returned valid JSON
- [ ] Both APIs in working state

### **Files:**
- [ ] All master plan files in project folder
- [ ] .gitignore created BEFORE any sensitive files
- [ ] Git initialized with first commit
- [ ] (Optional) GitHub repo created

### **Mental Prep:**
- [ ] Read MASTER_PLAN.md fully
- [ ] Understand the 10-week timeline
- [ ] Calendar blocked for 4hr/day work
- [ ] Distractions removed (notifications off)

---

## ⚡ Day 1 Quick Start

Once setup complete:

```bash
# Morning routine (every day)
cd ~/Projects/PlantHealth
git pull  # if using GitHub
claude

# Paste:
"Read MASTER_PLAN.md and PROGRESS.md.
Tell me today's task.
Wait for my 'go'."
```

---

## 🆘 Common Issues

### **"Claude Code not found"**
```bash
npm install -g @anthropic-ai/claude-code
```

### **"Plant.id 401 error"**
- Check API key is correct
- Header name is `Api-Key` (capital K)
- No trailing whitespace in key

### **"Gemini quota exceeded"**
- Free tier = 50 requests/day
- Wait 24 hours or upgrade to paid
- Or use less in testing

### **"Xcode won't run on simulator"**
- File → Workspace Settings → Build System: New Build System
- Product → Clean Build Folder
- Restart Xcode

### **"Claude is going off-track"**
Use the emergency prompt from PROMPTS.md:
```
STOP. Re-read MASTER_PLAN.md.
Only build what's in current week's tasks.
```

---

## 💪 You're Ready When...

- ✅ All checkboxes above are checked
- ✅ Plant.id tested with 10 plants
- ✅ Project folder set up
- ✅ First Claude Code session successful
- ✅ You can explain the 10-week plan from memory

**Then start Week 1, Day 1.** 🚀

The plan is ready. Tools are ready. Now execute.
