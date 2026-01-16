# Logaby Landing Page

A modern, conversion-optimized landing page for Logaby with waitlist functionality, email marketing automation via ConvertKit, and scarcity mechanics for early bird signups.

## Features

- 🎨 **Modern Design**: Beautiful, responsive layout with animations
- 📧 **Email Marketing**: ConvertKit integration for automated welcome sequences
- 🔥 **Scarcity Counter**: "X/50 spots left" for early bird signups (90% off)
- 📊 **Analytics Ready**: Optional Supabase tracking for signup metrics
- 🚀 **Deploy Ready**: One-click deployment to Vercel or Netlify

## Quick Start

### 1. Set Up ConvertKit

1. **Create a ConvertKit account** (free tier: up to 1,000 subscribers)
   - Go to [convertkit.com](https://convertkit.com)
   - Sign up for a free account

2. **Create a new form**:
   - In ConvertKit dashboard, go to **Grow** → **Landing Pages & Forms**
   - Click **Create New** → **Form**
   - Name it "Logaby Waitlist"

3. **Add custom field**:
   - Go to **Subscribers** → **Custom Fields**
   - Add field: `signup_number` (Number type)
   - Add field: `early_bird` (Boolean type)

4. **Create tags** (optional but recommended):
   - Go to **Subscribers** → **Tags**
   - Create tag: `early-bird` (for first 50 users)
   - Create tag: `waitlist` (for all signups)
   - Note the tag IDs (you'll see them in the URL when editing)

5. **Set up email sequence**:
   - Go to **Automate** → **Sequences**
   - Create a new sequence: "Logaby Waitlist Nurture"
   - Add emails:
     - **Email 1** (Immediate): "You're on the list! 🎉"
     - **Email 2** (Day 2): Problem/solution email
     - **Email 3** (Day 5): Feature highlight + scarcity reminder
     - **Email 4** (Launch day): "We're live! Here's your discount code"

6. **Get your API credentials**:
   - Go to **Settings** → **Advanced** → **API & Webhooks**
   - Copy your **API Key**
   - Copy your **Form ID** (from the form you created)

### 2. Configure the Landing Page

1. **Update `script.js`**:
   ```javascript
   const CONFIG = {
       CONVERTKIT_FORM_ID: 'YOUR_FORM_ID_HERE', // Replace with your Form ID
       CONVERTKIT_API_KEY: 'YOUR_API_KEY_HERE', // Replace with your API Key
       EARLY_BIRD_LIMIT: 50,
       SUPABASE_URL: '', // Optional
       SUPABASE_ANON_KEY: '' // Optional
   };
   ```

2. **Update tag IDs in `script.js`** (line ~120):
   ```javascript
   tags: isEarlyBird ? [YOUR_EARLY_BIRD_TAG_ID, YOUR_WAITLIST_TAG_ID] : [YOUR_WAITLIST_TAG_ID]
   ```

### 3. Test Locally

1. Open `index.html` in your browser
2. Test the email form with your own email
3. Check ConvertKit dashboard to confirm the subscriber was added
4. Verify you received the welcome email

### 4. Deploy to Vercel (Recommended)

1. **Install Vercel CLI** (optional):
   ```bash
   npm install -g vercel
   ```

2. **Deploy**:
   ```bash
   cd logaby-landing
   vercel
   ```

3. **Or use Vercel Dashboard**:
   - Go to [vercel.com](https://vercel.com)
   - Click **Add New** → **Project**
   - Import your Git repository
   - Deploy!

### Alternative: Deploy to Netlify

1. **Drag and drop**:
   - Go to [netlify.com](https://netlify.com)
   - Drag the `logaby-landing` folder to the deploy zone
   - Done!

2. **Or use Netlify CLI**:
   ```bash
   npm install -g netlify-cli
   cd logaby-landing
   netlify deploy
   ```

## Optional: Supabase Analytics

If you want to track signups in Supabase for analytics (in addition to ConvertKit):

1. **Create Supabase project**: [supabase.com](https://supabase.com)
2. **Run the SQL schema**:
   - Go to Supabase dashboard → **SQL Editor**
   - Copy and paste the contents of `supabase-schema.sql`
   - Run the query
3. **Get credentials**:
   - Go to **Settings** → **API**
   - Copy **Project URL** and **anon public** key
4. **Update `script.js`**:
   ```javascript
   SUPABASE_URL: 'https://your-project.supabase.co',
   SUPABASE_ANON_KEY: 'your_anon_key_here'
   ```

## Email Sequence Ideas

### Email 1: Welcome (Immediate)
**Subject**: You're on the Logaby waitlist! 🎉

Hi there!

You're officially on the list for Logaby — the hands-free baby tracker that works with your voice.

[If early bird] You're one of the first 50 people to join, which means you're locked in for **90% off** when we launch. We'll send you a discount code on launch day.

What happens next:
- We'll keep you updated on our progress
- You'll be the first to know when we launch
- You'll get exclusive early access

Talk soon,
The Logaby Team

### Email 2: Problem Email (Day 2)
**Subject**: Ever tried to log a feeding at 3am? 😴

We built Logaby because we were exhausted parents who couldn't keep track of anything.

[Story about fumbling with phone while holding baby]

That's why Logaby works with just your voice. No unlocking. No tapping. Just say "Hey Siri, tell Logaby 4oz bottle" and it's logged.

More updates coming soon!

### Email 3: Feature Highlight (Day 5)
**Subject**: Your partner will love this feature

One of our favorite features: **Multi-caregiver sync**.

Mom, dad, grandma, nanny — everyone sees the same data in real-time. No more "when did she eat last?" texts.

[Screenshot of dashboard]

Launch is coming soon. Stay tuned!

### Email 4: Launch (Launch Day)
**Subject**: We're live! Here's your 90% off code 🚀

Logaby is officially live!

[If early bird] As promised, here's your exclusive discount code: **EARLYBIRD90**

[Download link]

Thanks for being an early supporter!

## Customization

- **Colors**: Edit CSS variables in `styles.css` (lines 1-12)
- **Copy**: Edit text directly in `index.html`
- **Early bird limit**: Change `EARLY_BIRD_LIMIT` in `script.js`
- **Pricing**: Update pricing section in `index.html`

## Security Notes

- The ConvertKit API key is exposed in the browser (this is normal for client-side integrations)
- ConvertKit allows you to restrict API keys to specific domains in their dashboard
- For production, restrict your API key to your domain only

## Support

Questions? Check out:
- [ConvertKit API Docs](https://developers.convertkit.com/)
- [Supabase Docs](https://supabase.com/docs)
- [Vercel Docs](https://vercel.com/docs)

---

Built with ❤️ for exhausted parents everywhere.
