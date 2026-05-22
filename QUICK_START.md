# ⚡ Quick Start Guide

## 🎯 3 Simple Steps:

### 1️⃣ Install Cloudinary Gem
```bash
bundle install
```

### 2️⃣ Get Cloudinary Credentials
1. Go to [cloudinary.com](https://cloudinary.com) → Sign Up (Free)
2. Dashboard → Copy these 3 values:
   - Cloud Name
   - API Key
   - API Secret

### 3️⃣ Update .env File
Open `.env` and replace:
```env
CLOUDINARY_CLOUD_NAME=your_cloud_name    # ← Paste your Cloud Name
CLOUDINARY_API_KEY=your_api_key          # ← Paste your API Key
CLOUDINARY_API_SECRET=your_api_secret    # ← Paste your API Secret
```

## 🚀 Run Seed:
```bash
rails db:seed
```

## ⏱️ Wait 20-30 minutes...

## ✅ Done! 
- 1000 users created
- 5000 posts with images
- All images on Cloudinary CDN

## 🔑 Login:
- Email: `test@example.com`
- Password: `password123`

---

**Need help?** Read `CLOUDINARY_SETUP.md` for detailed instructions.
