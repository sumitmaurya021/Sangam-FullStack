# 🚀 Vercel Deployment - Quick Guide (Hindi)

## 📋 Sabse Pehle (One-time Setup)

### 1. Vercel CLI Install karo
```bash
npm install -g vercel
```

### 2. Login karo
```bash
vercel login
```

### 3. Database Setup (Choose one)

#### Option A: Vercel Postgres (Recommended)
```bash
# Vercel Dashboard pe jao
# Storage > Create Database > Postgres
# Connection string copy karo
```

#### Option B: Supabase (Free)
```bash
# https://supabase.com pe jao
# New Project banao
# Settings > Database > Connection String copy karo
```

#### Option C: Railway (Free)
```bash
# https://railway.app pe jao
# New Project > Add PostgreSQL
# Connection string copy karo
```

### 4. Environment Variables Set karo
```bash
# Vercel Dashboard > Settings > Environment Variables

DATABASE_URL=postgresql://user:pass@host:5432/dbname
RAILS_MASTER_KEY=your_master_key_here
RAILS_ENV=production
RACK_ENV=production
```

---

## 🚀 Deployment Kaise Karein?

### Method 1: Git Push (Automatic - Recommended)
```bash
git add .
git commit -m "Deploy to Vercel"
git push origin main
```
✅ Automatic deployment hogi + database migrate + seed

### Method 2: Vercel CLI (Manual)
```bash
vercel --prod
```
✅ Automatic deployment hogi + database migrate + seed

---

## 🗑️ Database Reset + Seed Kaise Karein?

### Windows Users (PowerShell):
```powershell
# Step 1: Environment variables download karo
vercel env pull .env.production

# Step 2: Database reset karo
$env:RAILS_ENV="production"
$env:DISABLE_DATABASE_ENVIRONMENT_CHECK="1"
bundle exec rails db:reset

# Step 3: Seed karo
bundle exec rails db:seed

# 🎯 Ya ek hi command me:
.\scripts\vercel-seed.ps1
```

### Linux/Mac Users (Bash):
```bash
# Step 1: Environment variables download karo
vercel env pull .env.production

# Step 2: Database reset + seed
RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:reset
RAILS_ENV=production bundle exec rails db:seed

# 🎯 Ya ek hi command me:
chmod +x scripts/vercel-seed.sh
./scripts/vercel-seed.sh
```

---

## 📊 Kya Data Create Hoga?

Jab aap seed karenge to yeh data automatically create hoga:

### 👥 Users (4)
1. **Aarav Sharma** - `aarav.sharma0@example.com`
2. **Priya Patel** - `priya.patel1@example.com`
3. **Rohan Verma** - `rohan.verma2@example.com`
4. **Test User** - `test@example.com` ⭐

**Password (sabke liye):** `password123`

### 📝 Content
- ✅ 12 Posts (3 per user, with 7-9 images each)
- ✅ 3 Friendships (accepted)
- ✅ 1 Pending friend request
- ✅ ~36 Likes
- ✅ ~36 Comments + ~72 Replies
- ✅ ~36 Shares
- ✅ Real avatars & cover photos

---

## 🎯 Common Commands

```bash
# Deploy karo
vercel --prod

# Environment variables dekho
vercel env ls

# Environment variables download karo
vercel env pull .env.production

# Logs dekho
vercel logs

# Production URL open karo
vercel open

# Database migrate karo (without seed)
RAILS_ENV=production bundle exec rails db:migrate

# Sirf seed karo (existing data ke saath)
RAILS_ENV=production bundle exec rails db:seed
```

---

## ❌ Common Errors & Solutions

### Error: "DATABASE_URL not found"
```bash
# Solution: Environment variable add karo
vercel env add DATABASE_URL
# Paste your PostgreSQL connection string
```

### Error: "RAILS_MASTER_KEY missing"
```bash
# Solution: Master key add karo
vercel env add RAILS_MASTER_KEY
# Paste content from config/master.key
```

### Error: "PG::ConnectionBad"
```bash
# Solution: Database URL check karo
vercel env pull .env.production
cat .env.production  # Check DATABASE_URL

# Database accessible hai ya nahi test karo
psql $DATABASE_URL
```

### Error: "Assets not loading"
```bash
# Solution: Assets precompile karo
RAILS_ENV=production bundle exec rails assets:precompile
git add public/assets
git commit -m "Add precompiled assets"
git push
```

---

## 🔐 Login Credentials

**Test Account (Use this):**
- 📧 Email: `test@example.com`
- 🔑 Password: `password123`

**Other Test Accounts:**
- `aarav.sharma0@example.com` / `password123`
- `priya.patel1@example.com` / `password123`
- `rohan.verma2@example.com` / `password123`

---

## 📝 Step-by-Step First Deployment

```bash
# 1. Vercel CLI install karo (agar nahi hai)
npm install -g vercel

# 2. Login karo
vercel login

# 3. Project link karo (first time only)
vercel link

# 4. Environment variables set karo (Vercel Dashboard se)
# DATABASE_URL, RAILS_MASTER_KEY, etc.

# 5. Deploy karo
vercel --prod

# 6. Database reset + seed karo (Windows)
vercel env pull .env.production
.\scripts\vercel-seed.ps1

# 7. Open karo aur test karo
vercel open
```

---

## ✅ Checklist

- [ ] Vercel CLI installed
- [ ] Vercel login done
- [ ] Database created (Vercel Postgres/Supabase/Railway)
- [ ] Environment variables set (DATABASE_URL, RAILS_MASTER_KEY)
- [ ] First deployment successful
- [ ] Database migrated
- [ ] Database seeded
- [ ] Test login working (test@example.com)

---

## 🆘 Help Chahiye?

### Vercel Documentation
- https://vercel.com/docs

### Database Options
- Vercel Postgres: https://vercel.com/docs/storage/vercel-postgres
- Supabase: https://supabase.com/docs
- Railway: https://docs.railway.app

### Rails on Vercel
- https://vercel.com/guides/deploying-rails-with-vercel

---

✅ **Ab aap ready hain!** Bas `vercel --prod` run karo aur deploy ho jayega! 🎉
