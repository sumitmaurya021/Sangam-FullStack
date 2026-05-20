# RSpec Test Suite

This project uses RSpec for testing with FactoryBot, Faker, and SimpleCov.

## Setup

All testing gems are already installed. If you need to reinstall:

```bash
bundle install
```

## Running Tests

### Run all tests
```bash
bundle exec rspec
```

### Run specific test file
```bash
bundle exec rspec spec/models/user_spec.rb
```

### Run specific test by line number
```bash
bundle exec rspec spec/models/user_spec.rb:10
```

### Run tests by type
```bash
# Model tests
bundle exec rspec spec/models

# Request tests
bundle exec rspec spec/requests

# System tests
bundle exec rspec spec/system
```

## Code Coverage

SimpleCov generates code coverage reports automatically when you run tests.

View coverage report:
```bash
# Run tests first
bundle exec rspec

# Open coverage report (Windows)
start coverage/index.html

# Or navigate to coverage/index.html in your browser
```

Coverage reports show:
- Overall code coverage percentage
- Coverage by file and directory
- Lines that are not covered by tests

## Test Structure

### Models (`spec/models/`)
- Unit tests for model validations
- Tests for model methods
- Tests for associations and callbacks

### Requests (`spec/requests/`)
- Integration tests for HTTP requests
- Tests for controller actions
- Tests for response status and content

### System (`spec/system/`)
- End-to-end tests using Capybara
- Tests for user interactions
- Tests for JavaScript functionality

## Factories

FactoryBot factories are defined in `spec/factories/`.

### Using Factories

```ruby
# Create a user
user = create(:user)

# Build a user (not saved)
user = build(:user)

# Create with specific attributes
user = create(:user, email: 'test@example.com')

# Create with traits
user = create(:user, :with_name)
```

## Faker

Faker generates realistic fake data for tests.

```ruby
# Random email
Faker::Internet.email

# Random name
Faker::Name.first_name

# Random text
Faker::Lorem.paragraph
```

## Test Helpers

### Devise Helpers

```ruby
# Sign in a user (request/system tests)
sign_in user

# Sign out
sign_out user
```

### Database Cleaner

Database Cleaner automatically cleans the database between tests to ensure test isolation.

## Best Practices

1. **Use factories instead of fixtures** - More flexible and maintainable
2. **Use Faker for dynamic data** - Prevents test pollution
3. **Keep tests focused** - One assertion per test when possible
4. **Use descriptive test names** - Clearly state what is being tested
5. **Test edge cases** - Not just happy paths
6. **Keep tests fast** - Use `build` instead of `create` when possible
7. **Check code coverage** - Aim for >80% coverage

## Continuous Integration

Tests should be run in CI/CD pipeline before deployment.

Example GitHub Actions workflow:
```yaml
- name: Run tests
  run: bundle exec rspec
  
- name: Upload coverage
  uses: actions/upload-artifact@v2
  with:
    name: coverage
    path: coverage/
```

## Troubleshooting

### Tests failing due to database
```bash
# Reset test database
rails db:test:prepare
```

### System tests not running
```bash
# Install Chrome driver
# Download from: https://chromedriver.chromium.org/
```

### Coverage not generating
```bash
# Make sure SimpleCov is required in rails_helper.rb
# Check that tests are actually running
```

## Additional Resources

- [RSpec Documentation](https://rspec.info/)
- [FactoryBot Documentation](https://github.com/thoughtbot/factory_bot)
- [Faker Documentation](https://github.com/faker-ruby/faker)
- [SimpleCov Documentation](https://github.com/simplecov-ruby/simplecov)
- [Capybara Documentation](https://github.com/teamcapybara/capybara)
