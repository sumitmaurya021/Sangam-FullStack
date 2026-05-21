#!/usr/bin/env bash
# exit on error
set -o errexit

# Install dependencies
bundle install

# Precompile assets
bundle exec rake assets:precompile

# Clean old assets
bundle exec rake assets:clean

# Run database migrations
bundle exec rails db:migrate

# Reset database and seed (only if SEED_DATABASE env var is set)
if [ "$SEED_DATABASE" = "true" ]; then
  echo "🗑️  Resetting database..."
  bundle exec rails db:reset DISABLE_DATABASE_ENVIRONMENT_CHECK=1
  echo "✅ Database reset complete!"
else
  # Just run seeds without reset
  echo "🌱 Seeding database..."
  bundle exec rails db:seed
  echo "✅ Database seeding complete!"
fi
