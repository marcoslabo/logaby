# GitHub Branch Creation & Deployment Guide

This guide walks you through creating a GitHub branch and deploying both the **Logaby Landing Page** and **Logaby iOS App** to GitHub.

---

## Prerequisites

- GitHub account: `marcoslabo`
- Repository: `marcoslabo/logaby`
- Git installed on your machine
- GitHub credentials ready for authentication

---

## Step 1: Initialize Git Repository (if not already done)

First, check if the repository is already initialized:

```bash
cd /Users/marcoslacayo/logaby
git status
```

If you see "not a git repository", initialize it:

```bash
git init
```

---

## Step 2: Create a New Branch

Create a new branch for your deployment. This keeps your main branch clean and allows for easier rollbacks:

```bash
# Create and switch to a new branch called 'production' (or any name you prefer)
git checkout -b production

# Alternative branch names you might consider:
# git checkout -b deploy
# git checkout -b v1.0
# git checkout -b launch
```

---

## Step 3: Stage All Files

Add both the landing page and the iOS app to the repository:

```bash
# Add all files in the repository
git add .

# Or add specific directories:
# git add logaby-landing/
# git add Logaby/
# git add ios/
# git add Logaby.xcodeproj/
```

---

## Step 4: Commit Your Changes

Create a commit with a descriptive message:

```bash
git commit -m "Initial deployment: Landing page and iOS app"
```

---

## Step 5: Set Remote Repository

Connect your local repository to the GitHub repository:

```bash
# Add the remote repository
git remote add origin https://github.com/marcoslabo/logaby.git

# If remote already exists, update it:
# git remote set-url origin https://github.com/marcoslabo/logaby.git
```

Verify the remote is set correctly:

```bash
git remote -v
```

---

## Step 6: Push to GitHub

Push your branch to GitHub:

```bash
# Push the production branch to GitHub
git push -u origin production

# If you want to push to main instead:
# git push -u origin main
```

When prompted, enter your GitHub credentials:
- **Username**: `marcoslabo`
- **Password**: Use a **Personal Access Token** (not your GitHub password)

> **Note**: If you don't have a Personal Access Token, create one at:
> https://github.com/settings/tokens
> 
> Required scopes: `repo` (Full control of private repositories)

---

## Step 7: Verify on GitHub

1. Go to: https://github.com/marcoslabo/logaby
2. Check that your branch appears in the branch dropdown
3. Verify both directories are present:
   - `logaby-landing/` (landing page)
   - `Logaby/` (iOS app)
   - `ios/` (iOS configuration)
   - `Logaby.xcodeproj/` (Xcode project)

---

## Step 8: Deploy Landing Page to Vercel

Now that your code is on GitHub, deploy the landing page:

### 8.1: Connect to Vercel

1. Go to: https://vercel.com/new
2. Click **"Import Git Repository"**
3. Select `marcoslabo/logaby`
4. Click **"Import"**

### 8.2: Configure Project Settings

- **Framework Preset**: Other (or None)
- **Root Directory**: `logaby-landing`
- **Build Command**: Leave empty (static site)
- **Output Directory**: `./` (current directory)

### 8.3: Environment Variables

If your landing page uses environment variables (check `.env.example`):

1. Click **"Environment Variables"**
2. Add each variable from your `.env.example`:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `CONVERTKIT_API_KEY`
   - `CONVERTKIT_FORM_ID`

### 8.4: Deploy

1. Click **"Deploy"**
2. Wait for deployment to complete (usually 1-2 minutes)
3. You'll get a URL like: `https://logaby-xyz.vercel.app`

### 8.5: Connect Custom Domain (Namecheap)

1. In Vercel, go to **Project Settings** → **Domains**
2. Add your domain (e.g., `logaby.com`)
3. Vercel will provide DNS records to add
4. Go to Namecheap:
   - Navigate to **Domain List** → **Manage** → **Advanced DNS**
   - Add the DNS records provided by Vercel
   - Common records:
     - **A Record**: `@` → Vercel IP
     - **CNAME**: `www` → `cname.vercel-dns.com`
5. Wait for DNS propagation (can take up to 48 hours, usually much faster)

---

## Step 9: iOS App Deployment (TestFlight/App Store)

The iOS app deployment is separate from GitHub and uses Xcode:

### 9.1: Prepare for App Store

1. Open Xcode:
   ```bash
   open /Users/marcoslacayo/logaby/Logaby.xcodeproj
   ```

2. **Select a Team**:
   - Go to **Project Settings** → **Signing & Capabilities**
   - Select your Apple Developer Team

3. **Archive the App**:
   - In Xcode menu: **Product** → **Archive**
   - Wait for the archive to complete

### 9.2: Upload to App Store Connect

1. Once archived, the **Organizer** window opens
2. Select your archive
3. Click **"Distribute App"**
4. Choose **"App Store Connect"**
5. Follow the prompts to upload

### 9.3: TestFlight Distribution

1. Go to: https://appstoreconnect.apple.com
2. Navigate to your app
3. Go to **TestFlight** tab
4. Add internal/external testers
5. Submit for TestFlight review

### 9.4: App Store Submission

1. In App Store Connect, go to **App Store** tab
2. Fill in all required metadata:
   - App description
   - Screenshots
   - Keywords
   - Privacy policy URL
3. Submit for review

---

## Step 10: Set Up Automatic Deployments (Optional)

### For Landing Page (Vercel)

Vercel automatically deploys when you push to GitHub:

```bash
# Make changes to landing page
cd /Users/marcoslacayo/logaby/logaby-landing
# Edit files...

# Commit and push
git add .
git commit -m "Update landing page"
git push origin production
```

Vercel will automatically detect the push and redeploy.

### For iOS App (GitHub Actions - Optional)

You can set up GitHub Actions to automate builds, but App Store submission still requires manual steps.

---

## Common Commands Reference

```bash
# Check current branch
git branch

# Switch branches
git checkout main
git checkout production

# Pull latest changes
git pull origin production

# View commit history
git log --oneline

# Check repository status
git status

# View remote repositories
git remote -v
```

---

## Troubleshooting

### Authentication Failed

If you get authentication errors:
1. Use a Personal Access Token instead of password
2. Create one at: https://github.com/settings/tokens
3. When prompted for password, paste the token

### Push Rejected

If push is rejected due to conflicts:
```bash
# Pull latest changes first
git pull origin production --rebase

# Then push again
git push origin production
```

### Vercel Build Failed

1. Check build logs in Vercel dashboard
2. Verify `Root Directory` is set to `logaby-landing`
3. Ensure all environment variables are set correctly

### iOS App Won't Archive

1. Ensure you have a valid Apple Developer account
2. Check that provisioning profiles are up to date
3. Verify bundle identifier is unique

---

## Next Steps

- ✅ Code is on GitHub
- ✅ Landing page deployed to Vercel
- ✅ Custom domain connected
- ✅ iOS app submitted to TestFlight/App Store

Your Logaby project is now live! 🎉
