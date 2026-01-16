# Quick Start: Deploy to GitHub

This is the fastest way to get your code on GitHub. For detailed instructions, see [GITHUB-BRANCH-DEPLOY.md](./GITHUB-BRANCH-DEPLOY.md).

---

## Step 1: Create Branch & Push to GitHub

```bash
cd /Users/marcoslacayo/logaby

# Create a new branch
git checkout -b production

# Stage all files
git add .

# Commit
git commit -m "Initial deployment: Landing page and iOS app"

# Set remote (if not already set)
git remote add origin https://github.com/marcoslabo/logaby.git
# OR if remote exists:
# git remote set-url origin https://github.com/marcoslabo/logaby.git

# Push to GitHub
git push -u origin production
```

**Authentication**: When prompted, use your GitHub username `marcoslabo` and a **Personal Access Token** (create at https://github.com/settings/tokens).

---

## Step 2: Deploy Landing Page to Vercel

1. Go to: https://vercel.com/new
2. Import `marcoslabo/logaby`
3. Set **Root Directory**: `logaby-landing`
4. Add environment variables (if needed):
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `CONVERTKIT_API_KEY`
   - `CONVERTKIT_FORM_ID`
5. Click **Deploy**

---

## Step 3: Connect Domain (Namecheap)

1. In Vercel: **Settings** → **Domains** → Add your domain
2. In Namecheap: Add DNS records provided by Vercel
3. Wait for DNS propagation

---

## Step 4: iOS App (Xcode)

```bash
# Open Xcode project
open /Users/marcoslacayo/logaby/Logaby.xcodeproj
```

Then in Xcode:
1. **Product** → **Archive**
2. **Distribute App** → **App Store Connect**
3. Upload to TestFlight/App Store

---

## That's it! 🚀

For troubleshooting and detailed steps, see [GITHUB-BRANCH-DEPLOY.md](./GITHUB-BRANCH-DEPLOY.md).
