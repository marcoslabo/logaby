# GitHub + Vercel Deployment Guide

Follow these steps to deploy your Logaby landing page using GitHub and Vercel (best practice):

---

## Step 1: Create GitHub Repository

1. **Go to GitHub**: [https://github.com/new](https://github.com/new)

2. **Fill in repository details**:
   - Repository name: `logaby-landing`
   - Description: "Logaby waitlist landing page with email marketing"
   - Visibility: **Public** (or Private if you prefer)
   - **DO NOT** check "Initialize this repository with a README"
   - Click **"Create repository"**

3. **Copy the commands** shown on the next page under "…or push an existing repository from the command line"

They should look like this:
```bash
git remote add origin https://github.com/YOUR_USERNAME/logaby-landing.git
git branch -M main
git push -u origin main
```

---

## Step 2: Push Your Code to GitHub

Run these commands in your terminal (I'll help you with this):

```bash
cd /Users/marcoslacayo/logaby/logaby-landing

# Add GitHub as remote (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/logaby-landing.git

# Push to GitHub
git branch -M main
git push -u origin main
```

---

## Step 3: Deploy to Vercel

1. **Go to Vercel**: [https://vercel.com/new](https://vercel.com/new)

2. **Sign up/Login**:
   - Click "Continue with GitHub"
   - Authorize Vercel to access your GitHub account

3. **Import your repository**:
   - You'll see a list of your GitHub repositories
   - Find `logaby-landing`
   - Click **"Import"**

4. **Configure project**:
   - Project Name: `logaby-landing` (or whatever you prefer)
   - Framework Preset: **Other** (it's just HTML/CSS/JS)
   - Root Directory: `./` (leave as is)
   - Build Command: (leave empty)
   - Output Directory: (leave empty)
   - Click **"Deploy"**

5. **Wait for deployment** (usually takes 30-60 seconds)

6. **Get your URL**: You'll get a URL like `logaby-landing.vercel.app`

---

## Step 4: Connect Your Namecheap Domain

### In Vercel:

1. Go to your project → **Settings** → **Domains**
2. Add your domain (e.g., `logaby.com`)
3. Add `www.logaby.com` too
4. Vercel will show you DNS records to add

### In Namecheap:

1. Log in to [Namecheap](https://www.namecheap.com)
2. Go to **Domain List** → Click **Manage** next to your domain
3. Click **Advanced DNS** tab
4. **Add these DNS records**:

   **For root domain (logaby.com)**:
   - Type: `A Record`
   - Host: `@`
   - Value: `76.76.21.21`
   - TTL: Automatic

   **For www subdomain (www.logaby.com)**:
   - Type: `CNAME Record`
   - Host: `www`
   - Value: `cname.vercel-dns.com`
   - TTL: Automatic

5. **Delete any conflicting records**:
   - Remove existing A records for `@`
   - Remove existing CNAME records for `www`

6. **Save changes**

### Verify:

1. Wait 5-10 minutes for DNS propagation
2. Go back to Vercel → Settings → Domains
3. Vercel will automatically verify and issue SSL certificate
4. Visit your domain - it should show your landing page! 🎉

---

## Step 5: Set Up Auto-Deployment

**Good news**: This is already done! 🎉

Every time you push to GitHub, Vercel will automatically deploy your changes.

**Workflow**:
```bash
# Make changes to your files
# Then:
git add .
git commit -m "Your commit message"
git push

# Vercel automatically deploys! ✨
```

---

## What domain did you buy?

Let me know your domain name and GitHub username, and I'll help you run the commands to push to GitHub!
