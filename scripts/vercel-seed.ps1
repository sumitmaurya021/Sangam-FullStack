# Vercel deployment ke baad database seed karne ke liye PowerShell script
# Usage: .\scripts\vercel-seed.ps1

Write-Host "🌱 Starting Vercel Database Seeding..." -ForegroundColor Green

# Check if Vercel CLI is installed
$vercelInstalled = Get-Command vercel -ErrorAction SilentlyContinue
if (-not $vercelInstalled) {
    Write-Host "❌ Vercel CLI not found. Installing..." -ForegroundColor Red
    npm install -g vercel
}

# Get production environment variables
Write-Host "📡 Connecting to Vercel production..." -ForegroundColor Cyan
vercel env pull .env.production

# Run database reset and seed
Write-Host "🗑️  Resetting database..." -ForegroundColor Yellow
$env:RAILS_ENV = "production"
$env:DISABLE_DATABASE_ENVIRONMENT_CHECK = "1"

bundle exec rails db:reset
bundle exec rails db:seed

Write-Host "✅ Database seeding completed!" -ForegroundColor Green
Write-Host "🔑 Test user: test@example.com / password123" -ForegroundColor Cyan
