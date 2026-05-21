#!/bin/bash

# Render deployment ke baad database seed karne ke liye script
# Usage: ./scripts/render-seed.sh

echo "🌱 Starting Render Database Seeding..."

# Run database reset and seed
echo "🗑️  Resetting database..."
RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:reset

echo "🌱 Seeding database..."
RAILS_ENV=production bundle exec rails db:seed

echo "✅ Database seeding completed!"
echo "🔑 Test user: test@example.com / password123"
