# 🌥️ Cloudinary Setup Guide

## Step 1: Cloudinary Account बनाएं

1. [Cloudinary](https://cloudinary.com/) पर जाएं
2. **Sign Up for Free** पर क्लिक करें
3. अपना account create करें (Free plan में 25GB storage मिलता है)

## Step 2: Cloudinary Credentials प्राप्त करें

1. Cloudinary Dashboard में login करें
2. **Dashboard** पर जाएं
3. आपको ये credentials मिलेंगे:
   - **Cloud Name**
   - **API Key**
   - **API Secret**

## Step 3: Environment Variables Configure करें

### Local Development के लिए (.env file):

```env
CLOUDINARY_CLOUD_NAME=your_cloud_name_here
CLOUDINARY_API_KEY=your_api_key_here
CLOUDINARY_API_SECRET=your_api_secret_here
```

### Production Server के लिए:

#### Render.com:
1. Dashboard → Your Service → Environment
2. Add Environment Variables:
   - `CLOUDINARY_CLOUD_NAME`
   - `CLOUDINARY_API_KEY`
   - `CLOUDINARY_API_SECRET`

#### Vercel:
```bash
vercel env add CLOUDINARY_CLOUD_NAME
vercel env add CLOUDINARY_API_KEY
vercel env add CLOUDINARY_API_SECRET
```

#### Heroku:
```bash
heroku config:set CLOUDINARY_CLOUD_NAME=your_cloud_name
heroku config:set CLOUDINARY_API_KEY=your_api_key
heroku config:set CLOUDINARY_API_SECRET=your_api_secret
```

#### Railway:
1. Project → Variables
2. Add:
   - `CLOUDINARY_CLOUD_NAME`
   - `CLOUDINARY_API_KEY`
   - `CLOUDINARY_API_SECRET`

## Step 4: Bundle Install करें

```bash
bundle install
```

## Step 5: Server Restart करें

```bash
# Development
rails server

# Production
# Deploy your application
```

## ✅ Configuration Complete!

अब सभी images (avatars, cover photos, post images) automatically Cloudinary पर upload होंगी।

## 🎯 Benefits:

- ✅ **Free 25GB Storage** (Free plan)
- ✅ **Fast CDN Delivery** - Images तेज़ी से load होंगी
- ✅ **Automatic Image Optimization** - Bandwidth save होगी
- ✅ **Image Transformations** - Resize, crop, filters automatically
- ✅ **No Server Storage** - Server पर space नहीं भरेगी

## 🔍 Verify Setup:

1. Rails console में जाएं:
```bash
rails console
```

2. Check configuration:
```ruby
Cloudinary.config.cloud_name
# => "your_cloud_name"
```

3. Test upload:
```ruby
user = User.first
user.avatar.attached?
# => true (if avatar exists)
```

## 📊 Monitor Usage:

Cloudinary Dashboard → Media Library में सभी uploaded images देख सकते हैं।

## ⚠️ Important Notes:

1. **Free Plan Limits:**
   - 25 GB storage
   - 25 GB bandwidth/month
   - 25,000 transformations/month

2. **Security:**
   - `.env` file को `.gitignore` में add करें (already added)
   - API credentials को कभी भी public repository में commit न करें

3. **Development vs Production:**
   - Development में local storage use कर सकते हैं (faster testing)
   - Production में Cloudinary use करें (recommended)

## 🚀 Next Steps:

अब आप seed file run कर सकते हैं:
```bash
rails db:seed
```

सभी 1000 users के avatars, cover photos, और 5000 posts की images Cloudinary पर upload होंगी! 🎉
