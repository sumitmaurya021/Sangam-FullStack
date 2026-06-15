source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Redis for Action Cable (real-time messaging across browser windows)
gem "redis", "~> 5.0"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # RSpec for testing
  gem "rspec-rails", "~> 7.1"
  
  # FactoryBot for test data
  gem "factory_bot_rails", "~> 6.4"
  
  # Faker for generating fake data
  gem "faker", "~> 3.5"
end

# Pagination
gem "kaminari", "~> 1.2"

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  
  # Preview email in the browser instead of sending
  gem "letter_opener"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  
  # Code coverage analysis
  gem "simplecov", require: false
  
  # RSpec matchers for Capybara
  gem "capybara-screenshot"
  
  # Database cleaner for test isolation
  gem "database_cleaner-active_record"
  
  # Shoulda matchers for RSpec
  gem "shoulda-matchers", "~> 8.0"
end
gem "devise"
gem "omniauth-google-oauth2", "~> 1.1"
gem "omniauth-github",        "~> 2.0"
gem "omniauth-rails_csrf_protection", "~> 1.0"
gem "rotp",    "~> 6.3"   # TOTP 2FA (RFC 6238)
gem "rqrcode", "~> 2.2"   # QR code generation for authenticator app setup
gem 'dotenv-rails', groups: [:development, :test]
gem 'rack-timeout'

# Cloudinary for image storage
gem 'cloudinary', '~> 2.2'

# Groupdate for time-based grouping
gem 'groupdate', '~> 6.4'
