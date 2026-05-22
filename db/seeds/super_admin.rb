# Create Super Admin User
puts "🔐 Creating Super Admin..."

super_admin = User.find_or_create_by!(email: 'admin@sangam.com') do |user|
  user.name = 'Super Admin'
  user.password = 'Admin@123456'
  user.password_confirmation = 'Admin@123456'
  user.super_admin = true
  user.bio = 'Super Administrator of Sangam'
end

if super_admin.persisted?
  puts "✅ Super Admin created successfully!"
  puts "📧 Email: admin@sangam.com"
  puts "🔑 Password: Admin@123456"
  puts "🔗 Access: /admin/dashboard"
else
  puts "❌ Failed to create Super Admin"
  puts super_admin.errors.full_messages
end
