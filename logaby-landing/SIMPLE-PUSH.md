# Simple Push to GitHub

Since you already have `marcoslabo/logaby` repository, just run these commands:

```bash
cd /Users/marcoslacayo/logaby/logaby-landing

# Set the remote (if not already set)
git remote set-url origin https://github.com/marcoslabo/logaby.git

# Push the code (you'll need to authenticate)
git push -u origin main --force
```

When it asks for authentication, use your GitHub credentials for the `marcoslabo` account.

---

## After Pushing to GitHub

Once the code is on GitHub, go to:
1. **Vercel**: https://vercel.com/new
2. **Import** the `marcoslabo/logaby` repository
3. **Deploy**
4. **Connect your Namecheap domain** in Vercel settings

That's it!
