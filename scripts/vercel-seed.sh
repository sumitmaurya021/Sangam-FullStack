#!/bin/bash

# Vercel deployment ke baad database seed karne ke liye script
# Usage: ./scripts/vercel-seed.sh

echo "🌱 Starting Vercel Database Seeding..."

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo "❌ Vercel CLI not found. Installing..."
    npm install -g vercel
fi

# Get production environment variables
echo "📡 Connecting to Vercel production..."

# Run database reset and seed on Vercel
echo "🗑️  Resetting database..."
vercel env pull .env.production

# Load environment and run commands
echo "🔄 Running database reset and seed..."
RAILS_ENV=production bundle exec rails db:reset DISABLE_DATABASE_ENVIRONMENT_CHECK=1
RAILS_ENV=production bundle exec rails db:seed

echo "✅ Database seeding completed!"
echo "🔑 Test user: test@example.com / password123"
