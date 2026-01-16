# Quick Start Checklist for Logaby GTM Launch

Use this checklist to launch your landing page and start collecting emails!

---

## ✅ Phase 1: Deploy Landing Page (Do This First!)

### Step 1: Deploy to Vercel
```bash
# Install Vercel CLI
npm install -g vercel

# Navigate to landing page folder
cd /Users/marcoslacayo/logaby/logaby-landing

# Deploy
vercel
```

**Follow the prompts:**
- Set up and deploy? **Y**
- Which scope? Choose your account
- Link to existing project? **N**
- Project name? **logaby-landing** (or whatever you prefer)
- Directory? **./** (current directory)
- Override settings? **N**

**Result**: You'll get a URL like `logaby-landing.vercel.app`

---

### Step 2: Connect Your Namecheap Domain

**In Vercel Dashboard** ([vercel.com/dashboard](https://vercel.com/dashboard)):
1. Go to your project → **Settings** → **Domains**
2. Add your domain (e.g., `logaby.com`)
3. Add `www.logaby.com` too
4. Vercel will show you DNS records to add

**In Namecheap** ([namecheap.com](https://www.namecheap.com)):
1. Log in → **Domain List** → **Manage** (your domain)
2. Click **Advanced DNS** tab
3. **Add these records**:
   - Type: `A Record` | Host: `@` | Value: `76.76.21.21`
   - Type: `CNAME` | Host: `www` | Value: `cname.vercel-dns.com`
4. **Delete** any existing A or CNAME records that conflict
5. Save changes

**Wait**: 5-10 minutes for DNS to propagate
**Verify**: Visit your domain - it should show your landing page!

---

## ✅ Phase 2: Set Up ConvertKit (Email Collection)

### Step 1: Create ConvertKit Account
1. Go to [convertkit.com](https://convertkit.com)
2. Sign up (free up to 1,000 subscribers)
3. Complete onboarding

### Step 2: Create Form
1. Dashboard → **Grow** → **Landing Pages & Forms**
2. Click **Create New** → **Form**
3. Name: "Logaby Waitlist"
4. Save the form

### Step 3: Add Custom Fields
1. Go to **Subscribers** → **Custom Fields**
2. Click **Create Custom Field**
3. Add these fields:
   - Name: `signup_number` | Type: **Number**
   - Name: `early_bird` | Type: **Text** (use "true" or "false")

### Step 4: Create Tags
1. Go to **Subscribers** → **Tags**
2. Create tag: `early-bird`
3. Create tag: `waitlist`
4. **Note the tag IDs** (in the URL when you click each tag, e.g., `convertkit.com/subscribers/tags/1234567`)

### Step 5: Get API Credentials
1. Go to **Settings** → **Advanced** → **API & Webhooks**
2. Copy your **API Key**
3. Go back to your form, copy the **Form ID** (in the URL or form settings)

### Step 6: Update Your Landing Page
Open `script.js` and update these lines:

```javascript
const CONFIG = {
    CONVERTKIT_FORM_ID: 'YOUR_FORM_ID_HERE', // Paste your Form ID
    CONVERTKIT_API_KEY: 'YOUR_API_KEY_HERE', // Paste your API Key
    EARLY_BIRD_LIMIT: 50,
    SUPABASE_URL: '', // Leave empty for now
    SUPABASE_ANON_KEY: '' // Leave empty for now
};
```

And update line 138 with your tag IDs:
```javascript
tags: isEarlyBird ? [EARLY_BIRD_TAG_ID, WAITLIST_TAG_ID] : [WAITLIST_TAG_ID]
// Example: tags: isEarlyBird ? [1234567, 1234568] : [1234568]
```

### Step 7: Redeploy
```bash
cd /Users/marcoslacayo/logaby/logaby-landing
vercel --prod
```

---

## ✅ Phase 3: Set Up Email Sequence

### Create Email Sequence in ConvertKit
1. Go to **Automate** → **Sequences**
2. Click **Create Sequence**
3. Name: "Logaby Waitlist Nurture"
4. Add 10 emails (copy from `email-sequence.md`)

**Email Schedule**:
- Email 1: Immediate (Welcome)
- Email 2: Day 2 (Problem)
- Email 3: Day 4 (Voice feature)
- Email 4: Day 6 (Family sync)
- Email 5: Day 8 (Reports)
- Email 6: Day 10 (Social proof)
- Email 7: Day 12 (Scarcity)
- Email 8: Day 14 (Founder story)
- Email 9: Day 16 (Pre-launch)
- Email 10: Launch day (manual send)

### Set Up Automation
1. Go to **Automate** → **Automations**
2. Click **Create Automation**
3. Trigger: **Subscribes to a form** → Select "Logaby Waitlist"
4. Action: **Subscribe to sequence** → Select "Logaby Waitlist Nurture"
5. Save

---

## ✅ Phase 4: Test Everything

### Test Email Signup
1. Visit your live domain
2. Enter your email in the waitlist form
3. Submit

**Verify**:
- ✅ Success message appears
- ✅ Email appears in ConvertKit dashboard
- ✅ Welcome email arrives in your inbox
- ✅ Custom fields are populated
- ✅ Tags are applied

**If something doesn't work**:
- Check browser console for errors (F12)
- Verify ConvertKit credentials in `script.js`
- Check ConvertKit automation is active

---

## ✅ Phase 5: Start Marketing

### Facebook Ads (Optional)
1. Set up Facebook Business Manager
2. Create Facebook Page for Logaby
3. Use ad copy from `facebook-ads.md`
4. Start with $5-10/day budget
5. Track with UTM links

### Reddit Marketing (Free!)
1. Join target subreddits (see `reddit-strategy.md`)
2. Comment on posts for 2-3 days (build karma)
3. Post value-first content
4. Engage with every comment
5. Track with UTM links

**Recommended Reddit Posts**:
- r/NewParents: "How do you track baby stuff when you never have a free hand?"
- r/beyondthebump: "LPT: Use voice commands to track baby stuff"
- r/ExclusivelyPumping: "Hands-free pumping tracking"

---

## 📊 Track Your Progress

### Metrics to Monitor
- **Waitlist signups**: Check ConvertKit dashboard
- **Traffic sources**: Use UTM parameters
- **Email open rates**: Check ConvertKit analytics
- **Conversion rate**: Visitors → signups

### UTM Tracking Links
- Facebook: `?utm_source=facebook&utm_medium=paid&utm_campaign=campaign_name`
- Reddit: `?utm_source=reddit&utm_medium=organic&utm_campaign=subreddit_name`
- Email: `?utm_source=email&utm_medium=convertkit&utm_campaign=sequence`

---

## 🎯 Success Milestones

- [ ] Landing page live on custom domain
- [ ] SSL certificate active (https://)
- [ ] Email signup working
- [ ] First test subscriber in ConvertKit
- [ ] Welcome email received
- [ ] Email sequence active
- [ ] First 10 real signups
- [ ] First 50 signups (early bird limit)
- [ ] 100 signups
- [ ] Ready to launch!

---

## 🆘 Need Help?

**Deployment Issues**: Check [DEPLOYMENT.md](file:///Users/marcoslacayo/logaby/logaby-landing/DEPLOYMENT.md)

**Email Setup**: Check [email-sequence.md](file:///Users/marcoslacayo/logaby/logaby-landing/email-sequence.md)

**Facebook Ads**: Check [facebook-ads.md](file:///Users/marcoslacayo/logaby/logaby-landing/facebook-ads.md)

**Reddit Marketing**: Check [reddit-strategy.md](file:///Users/marcoslacayo/logaby/logaby-landing/reddit-strategy.md)

---

## 🚀 You're Ready!

Start with Phase 1 (deployment) and work your way through. You can do this! 💪
