# 🔒 Security & API Keys Guide

> **Read this BEFORE committing any code. Leaked API keys = bills + abuse.**

---

## ⚠️ The Golden Rules

### **NEVER Do:**
- ❌ Hardcode API keys in `.swift` files
- ❌ Commit `Config.plist` to git
- ❌ Share API keys in screenshots
- ❌ Paste keys in Slack/Discord/email
- ❌ Use same key across multiple projects
- ❌ Push to public GitHub without checking history

### **ALWAYS Do:**
- ✅ Use `Config.plist` (in .gitignore)
- ✅ Verify `.gitignore` before first commit
- ✅ Use 1Password / Bitwarden to store keys
- ✅ Rotate keys if accidentally leaked
- ✅ Use different keys for dev/staging/prod
- ✅ Monitor API usage for unusual activity

---

## 🎯 Setup Workflow

### **Step 1: Verify .gitignore Works**

```bash
cd ~/Projects/Bloomly

# Check .gitignore is tracking these patterns
cat .gitignore | grep -i "Config.plist"
# Should show: Config.plist

# Test by creating dummy Config.plist
touch Config.plist
git status
# Config.plist should NOT appear in untracked files!
# If it does → .gitignore is broken
```

### **Step 2: Create Real Config.plist**

```bash
# Copy template
cp Config.example.plist Bloomly/Bloomly/Resources/Config.plist

# Or via Xcode:
# Right-click "Resources" folder
# → Add Files to "Bloomly"
# → Select Config.plist
```

### **Step 3: Add API Keys**

Open `Config.plist` in Xcode and replace:
- `YOUR_PLANT_ID_KEY_HERE` → your real Plant.id key
- `YOUR_GEMINI_KEY_HERE` → your real Gemini key

### **Step 4: Verify NOT Committed**

```bash
git status
# Config.plist should NOT appear
# If it appears → STOP! Fix .gitignore first

# If you accidentally committed already:
git rm --cached Config.plist
git commit -m "Remove leaked Config.plist"

# Then ROTATE all keys immediately (they're compromised!)
```

---

## 🔑 API Key Storage (Multiple Layers)

### **Layer 1: 1Password / Bitwarden** (Master Copy)

Store all keys with descriptive names:
```
🔑 Bloomly - Plant.id API Key
🔑 Bloomly - Gemini API Key  
🔑 Bloomly - RevenueCat API Key
🔑 Bloomly - Apple Developer Team ID
🔑 Bloomly - App Store Connect Key
```

**Tags:** `bloomly`, `production`, `api-key`

### **Layer 2: Config.plist** (Local Development)

Only on your Mac, never in git:
```xml
<key>PLANT_ID_API_KEY</key>
<string>actual_key_here</string>
```

### **Layer 3: CI/CD Secrets** (Future)

If using GitHub Actions / fastlane later:
- GitHub Secrets
- Apple Connect API Key
- Never log or print keys

---

## 🛡️ Reading Keys in Code

### **APIKeys.swift** (Safe Pattern)

```swift
// File: Core/Utilities/APIKeys.swift

import Foundation

enum APIKeys {
    static let plantId: String = load("PLANT_ID_API_KEY")
    static let gemini: String = load("GEMINI_API_KEY")
    static let revenueCat: String = load("REVENUECAT_API_KEY")
    
    private static func load(_ key: String) -> String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let value = plist[key] as? String,
              !value.isEmpty,
              !value.contains("YOUR_") else {  // Catch template values!
            #if DEBUG
            fatalError("""
            ⚠️ Missing or invalid API key: \(key)
            
            Did you:
            1. Create Config.plist from Config.example.plist?
            2. Add real API keys (not YOUR_X_HERE placeholders)?
            3. Add Config.plist to Xcode project (Resources folder)?
            
            See docs/SECURITY.md for setup instructions.
            """)
            #else
            return ""  // Production: fail silently
            #endif
        }
        return value
    }
}
```

**Why this is safe:**
- ✅ Keys never appear in source code
- ✅ Build fails loudly in DEBUG if missing
- ✅ Detects template placeholders
- ✅ Production fails silently (no crash for users)

---

## 🚨 Emergency: Leaked API Key

bhai if you accidentally commit a key, **act FAST**:

### **Immediate (within 5 minutes):**

```bash
# 1. Rotate the key IMMEDIATELY
# Plant.id: Dashboard → API Keys → Regenerate
# Gemini: Cloud Console → Credentials → Rotate
# RevenueCat: Settings → API Keys → Regenerate

# 2. Update Config.plist with new key

# 3. Remove from git history (NUCLEAR option)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch Config.plist" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (DESTRUCTIVE - only if you're sure)
git push origin --force --all
```

### **Better: Use BFG Repo Cleaner**

```bash
# Install BFG
brew install bfg

# Clone fresh copy
git clone --mirror https://github.com/you/bloomly.git

# Remove sensitive file from history
bfg --delete-files Config.plist bloomly.git

# Push cleaned history
cd bloomly.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force
```

### **After Cleanup:**
- ✅ All collaborators must re-clone (history rewrote)
- ✅ Old key MUST be deactivated (assume compromised)
- ✅ Check API usage for abuse
- ✅ Consider GitHub Security Audit

---

## 📊 API Usage Monitoring

### **Plant.id:**
- Dashboard shows daily/monthly usage
- Set up usage alerts at 80% of free tier
- Free tier = 100/month
- $0.10 per call after

### **Gemini:**
- Cloud Console → APIs → Gemini
- Set quotas to prevent runaway costs
- Free tier = 50/day, 1500/month

### **Set Spending Alerts:**

```
Plant.id:
□ Alert at 80 calls/month (free tier warning)
□ Alert at $20/month (paid tier safety)

Gemini:
□ Set daily quota to 50 (free tier)
□ Set monthly spend cap to $5
```

---

## 🔍 Pre-Commit Checklist

Before EVERY commit, check:

```bash
# 1. What am I committing?
git status
git diff --staged

# 2. Search for accidental keys
git diff --staged | grep -iE "(api_key|api-key|apikey|secret|password|token)"
# Should return nothing

# 3. Search for hardcoded values
git diff --staged | grep -iE "(\"[A-Za-z0-9]{20,}\")"
# Be suspicious of long strings

# 4. Check .gitignore is honored
ls -la Config.plist  # Should exist
git ls-files Config.plist  # Should be empty (not tracked)
```

---

## 🤖 Pre-Commit Hook (Automated Protection)

Add this to prevent accidental commits:

```bash
# Create hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

# Block commits containing API keys
if git diff --cached --name-only | xargs grep -lE "(API_KEY|api_key|secret_key|password)" 2>/dev/null; then
    echo "❌ ERROR: Possible API key detected in commit!"
    echo "Review staged files for sensitive data."
    exit 1
fi

# Block commits of Config.plist
if git diff --cached --name-only | grep -q "Config.plist"; then
    echo "❌ ERROR: Config.plist should never be committed!"
    echo "It's in .gitignore. If you see this, something's wrong."
    exit 1
fi

# All good
exit 0
EOF

# Make executable
chmod +x .git/hooks/pre-commit
```

**Now git will BLOCK commits containing keys.** 🛡️

---

## 🎯 Production Deployment

When you launch in Week 10:

### **App Store Build:**
- ✅ Use PRODUCTION API keys (separate from dev)
- ✅ Set `ENVIRONMENT = production` in Config.plist
- ✅ Test with real Plant.id usage limits
- ✅ Monitor Sentry for errors
- ✅ Watch RevenueCat for purchase issues

### **Key Rotation Schedule:**
```
Every 3 months: Rotate all keys
After: Each major release
Immediately: If team member leaves
Immediately: If any leak detected
```

---

## 📚 Reading List

- [GitHub: Removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [Apple: Storing keys securely](https://developer.apple.com/documentation/security/keychain_services)
- [OWASP: Mobile Security](https://owasp.org/www-project-mobile-security-testing-guide/)

---

## ✅ Final Sanity Check

Before pushing to GitHub for first time:

- [ ] `.gitignore` is committed
- [ ] `Config.plist` is in .gitignore
- [ ] `Config.plist` NOT in `git ls-files`
- [ ] No keys in any `.swift` file
- [ ] No keys in screenshots in commits
- [ ] No keys in commit messages
- [ ] Pre-commit hook installed
- [ ] All keys stored in 1Password
- [ ] Spending alerts configured
- [ ] Production keys separate from dev

**If all checked → safe to push.** 🚀

---

**Remember:** API keys = money. Treat them like cash, not like code.
