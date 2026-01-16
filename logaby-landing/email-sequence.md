# Logaby Email Nurture Sequence (10 Emails)

This is a 10-email sequence designed to nurture waitlist subscribers, build anticipation, and convert them into paying customers at launch.

---

## Email 1: Welcome Email (Immediate)

**Subject**: You're on the Logaby waitlist! 🎉

**Body**:
```
Hi there!

You're officially on the list for Logaby — the hands-free baby tracker that works with your voice.

{{ if subscriber.early_bird }}
🔥 You're one of the first 50 people to join, which means you're locked in for **90% off** when we launch. We'll send you a discount code on launch day.
{{ else }}
We'll keep you updated on our progress and let you know as soon as we launch.
{{ endif }}

**What happens next:**
- We'll share updates on our development progress
- You'll be the first to know when we launch
- You'll get exclusive early access before the general public

In the meantime, have you ever tried to log a feeding at 3am while holding a crying baby? We have. That's why we built Logaby.

Talk soon,
The Logaby Team

P.S. Reply to this email anytime — we read every message!
```

**ConvertKit Settings**:
- Trigger: On form submission
- Delay: Immediate
- Tag: Add "waitlist"

---

## Email 2: The 3am Problem (Day 2)

**Subject**: Ever tried to log a feeding at 3am? 😴

**Body**:
```
Hey {{ subscriber.first_name | default: "there" }},

It's 3am. Your baby is crying. You're exhausted.

Your partner asks: "When did she eat last?"

You have no idea. You forgot to write it down... again.

So you fumble for your phone in the dark. Unlock it. Navigate to the app. Tap through menus. Try to remember what time it was. All while holding a squirming baby.

**There has to be a better way.**

That's exactly why we built Logaby.

With Logaby, you just say:
"Hey Siri, tell Logaby 4oz bottle"

Done. Logged. Timestamped. Synced to your partner's phone.

No unlocking. No tapping. No forgetting.

Just your voice.

More updates coming soon!

— The Logaby Team

P.S. What's your biggest frustration with current baby tracking apps? Hit reply and let us know!
```

**ConvertKit Settings**:
- Delay: 2 days after Email 1
- Segment: All waitlist subscribers

---

## Email 3: Voice Logging Deep Dive (Day 4)

**Subject**: How voice logging actually works

**Body**:
```
Hi {{ subscriber.first_name | default: "there" }},

You might be wondering: "How does voice logging actually work?"

Great question. Here's the magic:

**Step 1: One-time setup (30 seconds)**
Install Logaby, then add a Siri Shortcut or Google Assistant routine. You do this once.

**Step 2: Just speak**
Holding baby at 3am? Don't reach for your phone. Just say:
- "Hey Siri, tell Logaby 4oz bottle"
- "Hey Google, tell Logaby wet diaper"
- "Hey Siri, tell Logaby pumped 6oz"

**Step 3: It's logged**
Logaby parses what you said, categorizes it, timestamps it, and saves it. Check the dashboard anytime to see patterns.

**Works with:**
✅ Feedings (breast, bottle, amounts)
✅ Diapers (wet, dirty, both)
✅ Sleep (start, end, duration)
✅ Pumping (amounts, times)
✅ Medications, tummy time, and more

The best part? Your partner, grandma, nanny — everyone can log activities and see the same data in real-time.

No more "when did she eat last?" texts.

We'll share more about multi-caregiver sync in the next email!

— The Logaby Team
```

**ConvertKit Settings**:
- Delay: 4 days after Email 1

---

## Email 4: Family Sync Feature (Day 6)

**Subject**: Your partner will love this feature

**Body**:
```
Hey {{ subscriber.first_name | default: "there" }},

One of our favorite features: **Multi-caregiver sync**.

Here's the scenario:

Mom logs a feeding at 2pm.
Dad gets a notification.
Grandma checks the app and sees it instantly.
The nanny knows exactly when the last diaper change was.

**Everyone stays on the same page. In real-time.**

No more:
- "Did you feed her?" texts
- Duplicate logs
- Confusion about who did what
- Scrambling to remember details

Just one source of truth that everyone can access.

And because it works with voice, even grandma (who "doesn't do apps") can use it:
"Hey Siri, tell Logaby 5oz bottle"

Done.

{{ if subscriber.early_bird }}
🔥 Reminder: You're locked in for 90% off at launch. We're getting close!
{{ endif }}

More updates coming soon!

— The Logaby Team
```

**ConvertKit Settings**:
- Delay: 6 days after Email 1

---

## Email 5: Reports & Healthcare Sharing (Day 8)

**Subject**: "How much has she been eating?"

**Body**:
```
Hi {{ subscriber.first_name | default: "there" }},

You're at the pediatrician.

The doctor asks: "How much has she been eating? Any patterns with sleep?"

You scramble through scattered notes, trying to piece together the last week.

**Sound familiar?**

With Logaby, you have professional reports ready to share:

📊 **Daily summaries**: Total feedings, sleep hours, diaper counts
📈 **Weekly trends**: Patterns and insights
📋 **Exportable reports**: PDF or CSV to share with doctors

One tap, and you can send a detailed report to:
- Your pediatrician
- Lactation consultant
- Sleep specialist
- Anyone who needs the data

No more guessing. No more "I think she ate around..."

Just accurate, timestamped data that helps your healthcare team help your baby.

We're almost ready to launch. Stay tuned!

— The Logaby Team
```

**ConvertKit Settings**:
- Delay: 8 days after Email 1

---

## Email 6: Social Proof (Day 10)

**Subject**: What early testers are saying

**Body**:
```
Hey {{ subscriber.first_name | default: "there" }},

We've been testing Logaby with a small group of parents.

Here's what they're saying:

---

**"I can't believe I ever used a regular baby tracker. This is SO much easier."**
— Sarah M., mom of twins

**"My husband actually uses it now. He never logged anything before because it was too complicated."**
— Jessica L., first-time mom

**"The voice logging is a game-changer when you're holding a baby. I don't know how I lived without it."**
— Mike D., dad of 2

**"I showed the reports to our pediatrician and she was impressed. Finally, accurate data!"**
— Amanda K., mom of 1

---

These are real parents who've been using Logaby in beta.

And they're not going back to their old apps.

{{ if subscriber.early_bird }}
🔥 You're one of the first 50 on the waitlist. Launch is coming soon, and your 90% discount is waiting!
{{ else }}
Launch is coming soon. We can't wait to get this in your hands!
{{ endif }}

— The Logaby Team
```

**ConvertKit Settings**:
- Delay: 10 days after Email 1

---

## Email 7: Scarcity Reminder (Day 12)

**Subject**: Early bird spots are running out

**Body**:
```
Hi {{ subscriber.first_name | default: "there" }},

Quick update:

{{ if subscriber.early_bird }}
🔥 **You're locked in for 90% off!**

You were one of the first 50 people to join the waitlist, which means you're guaranteed the early bird discount when we launch.

Regular price: $29.99
Your price: **$2.99**

We're in final testing now. Launch is coming very soon!

{{ else }}
We're down to the last few early bird spots (90% off).

If you know any other exhausted parents who need Logaby, send them to [your-domain.com] before spots run out!

{{ endif }}

In the meantime, here's a sneak peek of the dashboard:
[You can add a screenshot here when ready]

Almost there!

— The Logaby Team
```

**ConvertKit Settings**:
- Delay: 12 days after Email 1

---

## Email 8: Behind the Scenes (Day 14)

**Subject**: Why we built Logaby (founder story)

**Body**:
```
Hey {{ subscriber.first_name | default: "there" }},

I want to share why we built Logaby.

I'm a new parent. And like you, I was exhausted.

I tried every baby tracking app. They all had the same problem:

**They required me to have a free hand.**

But when you're holding a crying baby at 3am, you don't have a free hand.

I'd forget to log feedings. My partner and I would duplicate entries. The pediatrician would ask about patterns and I'd have no idea.

One night, I was feeding my daughter and thought:

"Why can't I just *tell* my phone to log this?"

So I built Logaby.

It started as a simple Siri shortcut. Then it grew into a full app with:
- Multi-caregiver sync
- Smart reminders
- Professional reports
- Pumping tracking
- And more

Now, hundreds of beta testers are using it every day.

And they're telling us it's changed how they track their babies.

**That's why we built this.**

Not to make another baby tracker.

But to make the *last* baby tracker you'll ever need.

Launch is coming soon. Thank you for being part of this journey.

— [Your Name]
Founder, Logaby
```

**ConvertKit Settings**:
- Delay: 14 days after Email 1

---

## Email 9: Pre-Launch Countdown (Day 16)

**Subject**: 🚀 Launching in 3 days!

**Body**:
```
Hi {{ subscriber.first_name | default: "there" }},

**We're launching in 3 days!**

Here's what to expect:

📅 **Launch Date**: [Insert date]
⏰ **Time**: 9am PST / 12pm EST
📱 **Available on**: iOS (iPhone & iPad) | Android coming soon

{{ if subscriber.early_bird }}
🔥 **Your early bird discount code will arrive on launch day**

Check your email at 9am PST on [launch date] for:
- Your exclusive 90% off code
- Download link
- Quick start guide

{{ else }}
**You'll get:**
- Launch announcement
- Download link
- Special launch week pricing

{{ endif }}

**What to do now:**
1. Mark your calendar for [launch date]
2. Make sure you're following us on [social media links if you have them]
3. Tell other exhausted parents about Logaby!

We can't wait to get this in your hands.

See you in 3 days!

— The Logaby Team

P.S. Have questions? Reply to this email — we're here to help!
```

**ConvertKit Settings**:
- Delay: 16 days after Email 1 (or adjust based on your launch timeline)

---

## Email 10: Launch Announcement (Launch Day)

**Subject**: 🎉 Logaby is LIVE! Here's your discount code

**Body**:
```
Hi {{ subscriber.first_name | default: "there" }},

**IT'S HERE!**

Logaby is officially live and ready to download!

{{ if subscriber.early_bird }}
🔥 **Your Early Bird Discount Code: EARLYBIRD90**

Regular price: $29.99
Your price: **$2.99** (90% off!)

This code is exclusive to the first 50 waitlist subscribers (that's you!).

{{ else }}
**Launch Week Special: LAUNCH50**

Get 50% off during launch week!
Regular price: $29.99
Launch price: **$14.99**

This code expires in 7 days.
{{ endif }}

**👉 Download Logaby now:**
- iOS: [App Store link]
- Android: Coming soon!

**Quick Start Guide:**
1. Download the app
2. Create your account
3. Set up Siri Shortcut (takes 30 seconds)
4. Start logging with your voice!

**Need help?**
- Watch our setup video: [link]
- Read the quick start guide: [link]
- Email us: support@logaby.com

**Thank you** for being an early supporter. We can't wait to hear what you think!

Now go get some sleep (and let Logaby do the tracking 😴).

— The Logaby Team

P.S. Love Logaby? Leave us a review in the App Store! It helps other exhausted parents find us. ❤️
```

**ConvertKit Settings**:
- Send manually on launch day OR
- Schedule for specific launch date/time

---

## Setting Up in ConvertKit

1. **Create a Sequence**:
   - Go to **Automate** → **Sequences**
   - Click **Create Sequence**
   - Name: "Logaby Waitlist Nurture"

2. **Add Each Email**:
   - Click **Add Email** for each of the 10 emails above
   - Copy/paste subject and body
   - Set delays as specified
   - Use merge tags: `{{ subscriber.first_name }}`, `{{ subscriber.early_bird }}`

3. **Set Up Automation**:
   - Go to **Automate** → **Automations**
   - Create rule: "When subscriber joins form [Logaby Waitlist], subscribe to sequence [Logaby Waitlist Nurture]"

4. **Test**:
   - Add yourself as a test subscriber
   - Verify emails are sent with correct timing
   - Check merge tags populate correctly

---

## Customization Tips

- Replace `[your-domain.com]` with your actual domain
- Add your name/photo to founder story (Email 8)
- Insert actual launch date in Emails 9 & 10
- Add screenshots/images where indicated
- Update discount codes as needed
- Add social media links if you have them

---

**Need help setting this up?** Check the [README.md](file:///Users/marcoslacayo/logaby/logaby-landing/README.md) for detailed ConvertKit instructions!
