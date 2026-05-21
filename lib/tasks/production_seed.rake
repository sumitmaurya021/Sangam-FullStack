# Custom rake task for production seeding
namespace :db do
  desc "Reset database and seed with test data (PRODUCTION SAFE)"
  task reset_and_seed: :environment do
    puts "⚠️  WARNING: This will delete ALL data and create fresh test data!"
    puts "Environment: #{Rails.env}"
    
    if Rails.env.production?
      puts "🔄 Resetting production database..."
      
      # Clear all data
      puts "🗑️  Clearing existing data..."
      Comment.destroy_all
      Like.destroy_all
      Share.destroy_all
      Friendship.destroy_all
      Post.destroy_all
      User.destroy_all
      
      # Run seeds
      puts "🌱 Running seeds..."
      Rake::Task['db:seed'].invoke
      
      puts "✅ Database reset and seeded successfully!"
    else
      puts "❌ This task is designed for production. Use 'rails db:reset' for development."
    end
  end
  
  desc "Seed database without resetting (adds data)"
  task seed_only: :environment do
    puts "🌱 Seeding database..."
    Rake::Task['db:seed'].invoke
    puts "✅ Seeding completed!"
  end
end
