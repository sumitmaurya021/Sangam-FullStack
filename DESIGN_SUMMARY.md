# Sangam - Social Media Platform

## 📁 Project Structure

### CSS Files (Organized by Feature)
```
app/assets/stylesheets/
├── users/
│   ├── sessions.css       # Login page styles
│   ├── registrations.css  # Signup page styles
│   └── passwords.css      # Password reset styles
└── home/
    └── dashboard.css      # Dashboard styles
```

## 🎨 Design Features

### 1. Login Page (`users/sessions`)
**Location:** `app/views/users/sessions/new.html.erb`
**CSS:** `app/assets/stylesheets/users/sessions.css`

**Features:**
- ✅ Purple gradient background with animation
- ✅ Centered white card with shadow
- ✅ Animated logo with floating effect
- ✅ Smooth input focus animations
- ✅ Remember me checkbox
- ✅ Forgot password link
- ✅ Sign up button with green gradient
- ✅ Fully responsive (mobile, tablet, desktop)
- ✅ Loading animations on submit

**Animations:**
- Gradient background shift
- Card slide up on load
- Logo floating effect
- Input field lift on focus
- Button ripple effect
- Shimmer effect on card border

### 2. Signup Page (`users/registrations`)
**Location:** `app/views/users/registrations/new.html.erb`
**CSS:** `app/assets/stylesheets/users/registrations.css`

**Features:**
- ✅ Green gradient background
- ✅ Scale-in animation for card
- ✅ Email and password fields
- ✅ Password confirmation
- ✅ Terms and policy notice
- ✅ Error message display with shake animation
- ✅ Responsive design
- ✅ Link back to login

**Animations:**
- Scale in effect
- Staggered fade-in for form fields
- Shake animation for errors
- Button hover effects

### 3. Password Reset Pages (`users/passwords`)
**Location:** 
- `app/views/users/passwords/new.html.erb` (Request reset)
- `app/views/users/passwords/edit.html.erb` (Change password)

**CSS:** `app/assets/stylesheets/users/passwords.css`

**Features:**
- ✅ Pink gradient background
- ✅ Bounce-in animation
- ✅ Search and Cancel buttons
- ✅ Password strength hint
- ✅ Success/error messages
- ✅ Responsive layout

**Animations:**
- Bounce in effect
- Slide down for success messages
- Shake for errors

### 4. Dashboard (`home/index`)
**Location:** `app/views/home/index.html.erb`
**CSS:** `app/assets/stylesheets/home/dashboard.css`

**Features:**
- ✅ Fixed header with navigation
- ✅ Search bar with expand animation
- ✅ Notification icon with badge
- ✅ Profile dropdown menu
- ✅ Three-column layout (sidebar, feed, widgets)
- ✅ Responsive design (collapses on mobile)
- ✅ Smooth animations throughout

**Header Components:**
- Logo with gradient
- Search input (expands on focus)
- Home icon button
- Notification icon with badge
- Profile button with dropdown

**Profile Dropdown:**
- User avatar with initial
- User name and email
- View Profile option
- Settings option
- Logout button
- Smooth slide-down animation
- Click outside to close

**Layout:**
- Left sidebar: User menu, Friends, Pages, Saved
- Center feed: Welcome card, posts area
- Right widgets: Sponsored, Contacts

**Responsive Breakpoints:**
- Desktop (>1200px): Full 3-column layout
- Tablet (768-1200px): 2 columns (feed + widgets)
- Mobile (<768px): Single column

## 🎭 Animation Effects

### Global Animations
1. **Gradient Shift** - Background gradients animate smoothly
2. **Slide Up** - Cards slide up on page load
3. **Fade In** - Elements fade in with stagger effect
4. **Scale In** - Cards scale in from center
5. **Bounce In** - Playful bounce effect
6. **Shimmer** - Border shimmer effect
7. **Float** - Logo floating animation
8. **Pulse** - Notification badge pulse
9. **Spin** - Loading spinner
10. **Shake** - Error message shake

### Interaction Animations
- Input focus: Lift and glow effect
- Button hover: Lift with shadow increase
- Button click: Ripple effect
- Dropdown: Slide down with fade
- Links: Lift on hover

## 📱 Responsive Design

### Mobile (< 480px)
- Single column layout
- Reduced padding
- Smaller font sizes
- Stacked buttons
- Hidden sidebar and widgets

### Tablet (480px - 1200px)
- Two column layout
- Adjusted spacing
- Visible feed and widgets
- Hidden sidebar

### Desktop (> 1200px)
- Full three column layout
- All features visible
- Optimal spacing

## 🎨 Color Scheme

### Login Page
- Primary: Purple gradient (#667eea to #764ba2)
- Background: Animated gradient
- Text: Dark (#050505) and Gray (#666)

### Signup Page
- Primary: Green gradient (#42e695 to #3bb2b8)
- Background: Animated gradient
- Text: Dark and Gray

### Password Reset
- Primary: Pink gradient (#f093fb to #f5576c)
- Background: Animated gradient
- Text: Dark and Gray

### Dashboard
- Header: White (#ffffff)
- Background: Light gray (#f0f2f5)
- Primary: Purple gradient
- Text: Dark (#050505) and Gray (#65676b)
- Accent: Blue for links

## 🧪 Testing Setup

### Test Framework: RSpec
**Location:** `spec/`

### Test Coverage Tools:
1. **RSpec** - Testing framework
2. **FactoryBot** - Test data generation
3. **Faker** - Realistic fake data
4. **SimpleCov** - Code coverage analysis
5. **Capybara** - System/integration testing
6. **Shoulda Matchers** - RSpec matchers

### Test Files Created:

#### Model Tests
- `spec/models/user_spec.rb`
  - Validation tests
  - Devise module tests
  - Factory tests
  - Password encryption tests

#### Request Tests
- `spec/requests/users/sessions_spec.rb` - Login functionality
- `spec/requests/users/registrations_spec.rb` - Signup functionality
- `spec/requests/users/passwords_spec.rb` - Password reset
- `spec/requests/home_spec.rb` - Dashboard and landing page

#### System Tests
- `spec/system/user_authentication_spec.rb`
  - End-to-end login flow
  - End-to-end signup flow
  - Password reset flow
  - Dashboard interactions
  - Profile dropdown functionality
  - Responsive design tests

#### Factories
- `spec/factories/users.rb`
  - User factory with Faker
  - Traits: `:with_name`, `:confirmed`, `:unconfirmed`

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run with coverage
bundle exec rspec

# Run specific test
bundle exec rspec spec/models/user_spec.rb

# Run system tests only
bundle exec rspec spec/system
```

### Code Coverage
- SimpleCov generates coverage reports in `coverage/`
- Open `coverage/index.html` to view detailed coverage
- Configured to exclude: bin/, db/, spec/, config/, vendor/

## 📦 Dependencies Added

```ruby
# Testing gems
gem "rspec-rails", "~> 7.1"
gem "factory_bot_rails", "~> 6.4"
gem "faker", "~> 3.5"
gem "simplecov", require: false
gem "capybara-screenshot"
gem "database_cleaner-active_record"
gem "shoulda-matchers", "~> 6.0"
```

## 🚀 How to Use

### 1. Install Dependencies
```bash
bundle install
```

### 2. Setup Database
```bash
rails db:create
rails db:migrate
```

### 3. Run Tests
```bash
bundle exec rspec
```

### 4. Start Server
```bash
rails server
```

### 5. Visit Pages
- Login: http://localhost:3000/users/sign_in
- Signup: http://localhost:3000/users/sign_up
- Dashboard: http://localhost:3000/

## ✨ Key Features

1. **Professional Design** - Modern, clean UI inspired by Indian social connectivity
2. **Smooth Animations** - Every interaction is animated
3. **Fully Responsive** - Works on all devices
4. **Custom CSS** - No frameworks, pure CSS
5. **Organized Structure** - Separate CSS files for each feature
6. **Comprehensive Tests** - Full test coverage with RSpec
7. **Realistic Test Data** - Using Faker for dynamic data
8. **Code Coverage** - SimpleCov tracks test coverage

## 📝 Notes

- All CSS is custom-written, no Bootstrap or Tailwind
- Each page has its own CSS file in organized folders
- Animations are smooth and performant
- Design is mobile-first and responsive
- Tests cover all major functionality
- FactoryBot and Faker ensure clean test data
- SimpleCov provides detailed coverage reports

## 🎯 Test Coverage Goals

- Models: 100%
- Controllers/Requests: 95%+
- System/Integration: 90%+
- Overall: 90%+

## 🔧 Configuration Files

- `.rspec` - RSpec configuration
- `spec/rails_helper.rb` - Rails test configuration
- `spec/spec_helper.rb` - RSpec configuration
- `spec/support/factory_bot.rb` - FactoryBot setup
- `spec/support/shoulda_matchers.rb` - Shoulda matchers setup

## 📚 Documentation

- Test documentation: `spec/README.md`
- Design summary: This file
- Code comments: Throughout CSS files

---

**Created by:** Kiro AI Assistant
**Date:** 2026
**Framework:** Ruby on Rails 8.1.3
**Testing:** RSpec with FactoryBot, Faker, SimpleCov
