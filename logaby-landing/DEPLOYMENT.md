# Deploying Logaby Landing Page to Namecheap Domain

## Quick Start Guide

### Step 1: Deploy to Vercel (Free Hosting)

1. **Create a Vercel account** (if you don't have one):
   - Go to [vercel.com](https://vercel.com)
   - Sign up with GitHub, GitLab, or Bitbucket (recommended) or email

2. **Deploy your landing page**:
   
   **Option A: Using Vercel CLI (Recommended)**
   ```bash
   # Install Vercel CLI globally
   npm install -g vercel
   
   # Navigate to your landing page folder
   cd /Users/marcoslacayo/logaby/logaby-landing
   
   # Deploy (follow the prompts)
   vercel
   ```
   
   **Option B: Using Vercel Dashboard**
   - Go to [vercel.com/new](https://vercel.com/new)
   - Click "Add New" → "Project"
   - Import your Git repository OR drag and drop the `logaby-landing` folder
   - Click "Deploy"

3. **Note your Vercel URL**: After deployment, you'll get a URL like `your-project.vercel.app`

---

### Step 2: Connect Your Namecheap Domain to Vercel

#### In Vercel Dashboard:

1. Go to your project in Vercel
2. Click **Settings** → **Domains**
3. Add your domain (e.g., `logaby.com` and `www.logaby.com`)
4. Vercel will show you DNS records to add

#### In Namecheap Dashboard:

1. **Log in to Namecheap**: [namecheap.com](https://www.namecheap.com)
2. Go to **Domain List** → Click **Manage** next to your domain
3. Click **Advanced DNS** tab

4. **Add DNS Records** (provided by Vercel):
   
   For **root domain** (logaby.com):
   - Type: `A Record`
   - Host: `@`
   - Value: `76.76.21.21` (Vercel's IP)
   - TTL: Automatic
   
   For **www subdomain** (www.logaby.com):
   - Type: `CNAME Record`
   - Host: `www`
   - Value: `cname.vercel-dns.com`
   - TTL: Automatic

5. **Remove conflicting records**:
   - Delete any existing A records for `@`
   - Delete any existing CNAME records for `www`
   - Keep MX records (for email) if you have them

6. **Save changes**

#### Verify Domain Connection:

1. Go back to Vercel → Settings → Domains
2. Wait 5-10 minutes for DNS propagation
3. Vercel will automatically verify and issue SSL certificate
4. Your site will be live at your domain! 🎉

---

### Step 3: Set Up ConvertKit (Before Going Live)

**IMPORTANT**: Update your ConvertKit credentials in `script.js` before your site goes live!

1. **Create ConvertKit account**: [convertkit.com](https://convertkit.com) (free up to 1,000 subscribers)

2. **Create a Form**:
   - Dashboard → **Grow** → **Landing Pages & Forms**
   - Click **Create New** → **Form**
   - Name: "Logaby Waitlist"

3. **Add Custom Fields**:
   - Go to **Subscribers** → **Custom Fields**
   - Add field: `signup_number` (Number type)
   - Add field: `early_bird` (Boolean type)

4. **Create Tags**:
   - Go to **Subscribers** → **Tags**
   - Create tag: `early-bird`
   - Create tag: `waitlist`
   - **Note the tag IDs** (visible in URL when editing each tag)

5. **Get API Credentials**:
   - Go to **Settings** → **Advanced** → **API & Webhooks**
   - Copy your **API Key**
   - Copy your **Form ID** (from the form you created)

6. **Update `script.js`**:
   - Replace `YOUR_FORM_ID_HERE` with your Form ID
   - Replace `YOUR_API_KEY_HERE` with your API Key
   - Update tag IDs on line 138

7. **Redeploy to Vercel**:
   ```bash
   vercel --prod
   ```

---

### Step 4: Test Everything

1. **Visit your live domain**
2. **Test email signup**:
   - Enter your email
   - Check ConvertKit dashboard for new subscriber
   - Check your email for welcome message (once sequence is set up)
3. **Test on mobile devices**
4. **Verify scarcity counter updates**

---

## Troubleshooting

### Domain not connecting?
- Wait 24-48 hours for full DNS propagation (usually takes 5-10 minutes)
- Verify DNS records in Namecheap match Vercel's requirements
- Use [whatsmydns.net](https://www.whatsmydns.net) to check DNS propagation

### Email signup not working?
- Check browser console for errors
- Verify ConvertKit credentials in `script.js`
- Make sure you've created custom fields in ConvertKit
- Check ConvertKit API key has proper permissions

### SSL certificate issues?
- Vercel automatically provisions SSL (Let's Encrypt)
- Wait 5-10 minutes after domain verification
- If issues persist, remove and re-add domain in Vercel

---

## Next Steps

After deployment:
1. ✅ Set up ConvertKit email sequence (10 nurture emails)
2. ✅ Create Facebook ad campaigns
3. ✅ Prepare Reddit marketing posts
4. ✅ Set up Google Analytics (optional)
5. ✅ Start driving traffic!

---

## Quick Reference

**Vercel Dashboard**: [vercel.com/dashboard](https://vercel.com/dashboard)  
**Namecheap Dashboard**: [namecheap.com/myaccount/domain-list](https://ap.www.namecheap.com/domains/list/)  
**ConvertKit Dashboard**: [app.convertkit.com](https://app.convertkit.com)  

**Need help?** Check the main [README.md](file:///Users/marcoslacayo/logaby/logaby-landing/README.md) for detailed ConvertKit setup instructions.
