# Email Configuration Guide

## Overview
Yeh project email functionality ke liye configure ho gaya hai. Development aur Production dono environments ke liye alag-alag setup hai.

---

## Development Environment

### Letter Opener Setup
Development mein emails browser mein open hote hain instead of actually send hone ke.

**Configuration:**
- `config/environments/development.rb` mein `letter_opener` gem use ho raha hai
- Jab bhi koi email send hoga, automatically browser mein open ho jayega

**Testing:**
```ruby
# Rails console mein test karo
UserMailer.welcome_email(User.first).deliver_now
```

---

## Production Environment

### Gmail SMTP Setup

#### Step 1: Gmail App Password Generate Karo

1. **Google Account Settings** mein jao: https://myaccount.google.com/
2. **Security** section mein jao
3. **2-Step Verification** enable karo (agar already nahi hai)
4. **App Passwords** search karo
5. Naya app password generate karo:
   - App select karo: "Mail"
   - Device select karo: "Other" (custom name)
   - Name do: "Rails App"
6. 16-digit password copy karo

#### Step 2: Environment Variables Update Karo

`.env` file mein yeh values update karo:

```env
MAILER_HOST=yourdomain.com
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_DOMAIN=gmail.com
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_16_digit_app_password
```

**Important Notes:**
- `SMTP_PASSWORD` mein app-specific password use karo, regular password nahi
- `MAILER_HOST` mein apna actual domain name dalo (production ke liye)

---

## Alternative SMTP Providers

### SendGrid
```env
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_DOMAIN=yourdomain.com
SMTP_USERNAME=apikey
SMTP_PASSWORD=your_sendgrid_api_key
```

### Mailgun
```env
SMTP_ADDRESS=smtp.mailgun.org
SMTP_PORT=587
SMTP_DOMAIN=yourdomain.com
SMTP_USERNAME=postmaster@yourdomain.com
SMTP_PASSWORD=your_mailgun_password
```

### AWS SES
```env
SMTP_ADDRESS=email-smtp.us-east-1.amazonaws.com
SMTP_PORT=587
SMTP_DOMAIN=yourdomain.com
SMTP_USERNAME=your_aws_access_key
SMTP_PASSWORD=your_aws_secret_key
```

---

## Testing Email Configuration

### Development Test
```bash
# Rails console open karo
rails console

# Test email bhejo (Devise user ke liye)
user = User.first
UserMailer.welcome_email(user).deliver_now

# Ya Devise confirmation email test karo
user.send_confirmation_instructions
```

### Production Test
```bash
# Production console mein
RAILS_ENV=production rails console

# Test email bhejo
UserMailer.test_email('recipient@example.com').deliver_now
```

---

## Common Issues & Solutions

### Issue 1: "Net::SMTPAuthenticationError"
**Solution:** 
- Gmail app password sahi se copy kiya hai check karo
- 2-Step Verification enabled hai confirm karo
- Less secure app access OFF rakho (app password use karne ke baad)

### Issue 2: "Connection timeout"
**Solution:**
- SMTP_PORT correct hai check karo (587 ya 465)
- Firewall email ports ko block to nahi kar raha
- Internet connection stable hai

### Issue 3: Development mein email browser mein nahi khul raha
**Solution:**
```bash
# Letter opener gem install hai check karo
bundle list | grep letter_opener

# Server restart karo
rails server
```

### Issue 4: "Sender address rejected"
**Solution:**
- SMTP_USERNAME mein valid email address use karo
- Domain verification complete hai (production ke liye)

---

## Mailer Example

Agar aapko custom mailer banana hai:

```bash
# Mailer generate karo
rails generate mailer UserMailer welcome_email

# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  default from: 'noreply@yourdomain.com'

  def welcome_email(user)
    @user = user
    mail(to: @user.email, subject: 'Welcome to Our App!')
  end
end
```

---

## Security Best Practices

1. **.env file ko .gitignore mein rakho** (already added hai)
2. **Production mein environment variables use karo** (Heroku, AWS, etc.)
3. **App-specific passwords use karo**, regular passwords nahi
4. **Rate limiting implement karo** email sending ke liye
5. **Email validation add karo** before sending

---

## Monitoring

Production mein email delivery monitor karne ke liye:

1. **Gmail:** Sent folder check karo
2. **SendGrid/Mailgun:** Dashboard mein delivery stats dekho
3. **Rails Logs:** `log/production.log` mein email delivery logs check karo

---

## Support

Agar koi issue aaye to:
1. Rails logs check karo: `tail -f log/development.log`
2. SMTP credentials verify karo
3. Internet connectivity test karo
4. Provider-specific documentation padho

---

**Last Updated:** May 20, 2026
