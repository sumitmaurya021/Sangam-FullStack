#!/usr/bin/env bash
# exit on error
set -o errexit

echo "🚀 Starting Render build with database reset..."

# Install dependencies
echo "📦 Installing dependencies..."
bundle install

# Precompile assets
echo "🎨 Precompiling assets..."
bundle exec rake assets:precompile

# Clean old assets
echo "🧹 Cleaning old assets..."
bundle exec rake assets:clean

# Run database migrations
echo "🔄 Running migrations..."
bundle exec rails db:migrate

# Reset database (delete all data)
echo "🗑️  Resetting database (deleting all data)..."
bundle exec rails db:reset DISABLE_DATABASE_ENVIRONMENT_CHECK=1

echo "✅ Build complete! Database reset and seeded with test data."
echo "🔑 Login: test@example.com / password123"
