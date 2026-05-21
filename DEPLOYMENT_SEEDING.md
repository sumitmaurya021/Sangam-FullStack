# 🚀 Vercel Deployment Seeding Guide

## ⚠️ Important: Vercel Deployment Notes

Vercel pe Rails app deploy karne ke liye aapko:
1. **PostgreSQL Database** (Vercel Postgres, Supabase, ya Railway)
2. **Vercel CLI** installed hona chahiye
3. **Environment Variables** properly set hone chahiye

---

## 🔧 Initial Setup (Ek baar karna hai)

### 1. Vercel CLI Install karo
```bash
npm install -g vercel
```

### 2. Vercel Login karo
```bash
vercel login
```

### 3. Database Environment Variables Set karo
Vercel Dashboard pe jao aur yeh environment variables add karo:
- `DATABASE_URL` - Your PostgreSQL connection string
- `RAILS_MASTER_KEY` - Your master.key file ka content
- `RAILS_ENV=production`

---

## 🚀 Deployment Commands

### Automatic Seeding (Deployment ke saath)
```bash
# Deploy karo (automatic migration + seed hoga)
vercel --prod

# Ya
git push origin main  # (agar Vercel Git integration hai)
```

**Note:** `package.json` me `vercel-build` script automatically:
1. ✅ Assets precompile karega
2. ✅ Database migrate karega  
3. ✅ Seeds run karega

---

## 🗑️ Manual Database Reset + Seed

### Option 1: Local se Vercel Database pe (Recommended)

#### Windows (PowerShell):
```powershell
# Environment variables download karo
vercel env pull .env.production

# Database reset aur seed
$env:RAILS_ENV="production"
$env:DISABLE_DATABASE_ENVIRONMENT_CHECK="1"
bundle exec rails db:reset
bundle exec rails db:seed

# Ya script use karo
.\scripts\vercel-seed.ps1
```

#### Linux/Mac (Bash):
```bash
# Environment variables download karo
vercel env pull .env.production

# Database reset aur seed
RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:reset
RAILS_ENV=production bundle exec rails db:seed

# Ya script use karo
chmod +x scripts/vercel-seed.sh
./scripts/vercel-seed.sh
```

### Option 2: Vercel CLI se Direct Commands
```bash
# Sirf seed run karo (existing data ke saath)
vercel env pull .env.production
RAILS_ENV=production bundle exec rails db:seed

# Database reset karo
RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:reset
```

### Option 3: Railway/Render Dashboard se (Agar waha database hai)
Agar aapka database Railway ya Render pe hai:
```bash
# Railway CLI
railway run rails db:reset DISABLE_DATABASE_ENVIRONMENT_CHECK=1
railway run rails db:seed

# Render Dashboard
# Web Service > Shell tab me jao aur run karo:
rails db:reset DISABLE_DATABASE_ENVIRONMENT_CHECK=1
rails db:seed
```

---

## Test Data Details

Seeds.rb file se yeh data create hoga:

### 👥 Users (4 total)
1. **Aarav Sharma** - aarav.sharma0@example.com
2. **Priya Patel** - priya.patel1@example.com  
3. **Rohan Verma** - rohan.verma2@example.com
4. **Rahul Sharma (Test User)** - test@example.com

**Password (sabke liye):** `password123`

### 📊 Data Created
- ✅ 4 Users (with avatars & cover photos)
- ✅ 12 Posts (3 per user, each with 7-9 images)
- ✅ 3 Friendships (accepted)
- ✅ 1 Pending friend request
- ✅ ~36 Likes (max 3 per post)
- ✅ ~36 Comments (max 3 per post)
- ✅ ~72 Replies (max 2 per comment)
- ✅ ~36 Shares (max 3 per post)

---

## ⚠️ Important Notes

1. **Automatic Seeding**: `vercel-build` script har deployment ke baad automatically seed run karti hai
2. **Data Loss**: Database reset purana data **permanently delete** kar dega
3. **Production Safety**: `DISABLE_DATABASE_ENVIRONMENT_CHECK=1` flag production me bhi reset allow karta hai
4. **Images**: Real human avatars (randomuser.me) aur random images (Lorem Picsum) download hoti hain
5. **Database**: Vercel Postgres, Supabase, ya Railway database use kar sakte hain

---

## 🔧 Troubleshooting

### Vercel CLI install nahi hai?
```bash
npm install -g vercel
vercel login
```

### Environment variables missing?
```bash
# Vercel Dashboard se download karo
vercel env pull .env.production

# Check karo
cat .env.production  # Linux/Mac
type .env.production  # Windows
```

### Database connection error?
```bash
# Check DATABASE_URL environment variable
vercel env ls

# Add karo agar missing hai
vercel env add DATABASE_URL
```

### Seed script fail ho rahi hai?
```bash
# Manual run karo step by step
vercel env pull .env.production

# Windows
$env:RAILS_ENV="production"
bundle exec rails db:migrate
bundle exec rails db:seed

# Linux/Mac
RAILS_ENV=production bundle exec rails db:migrate
RAILS_ENV=production bundle exec rails db:seed
```

---

## 🎯 Quick Commands (Vercel)

```bash
# Deploy karo (automatic seeding hogi)
vercel --prod

# Environment variables download karo
vercel env pull .env.production

# Database reset + seed (Windows)
.\scripts\vercel-seed.ps1

# Database reset + seed (Linux/Mac)
./scripts/vercel-seed.sh

# Sirf seed karo
RAILS_ENV=production bundle exec rails db:seed

# Logs dekho
vercel logs

# Production URL open karo
vercel open
```

---

## 📝 Login Credentials

**Test Account:**
- Email: `test@example.com`
- Password: `password123`

**Other Accounts:**
- `aarav.sharma0@example.com` / `password123`
- `priya.patel1@example.com` / `password123`
- `rohan.verma2@example.com` / `password123`

---

✅ **Setup Complete!** Ab har deployment ke baad automatically fresh test data mil jayega.
