# ================================================================
#  SANGAM SEEDS — 300 Users (Production Safe, Timeout Proof)
# ================================================================
require 'net/http'
require 'open-uri'
require 'openssl'
require 'uri'
require 'json'

# ----------------------------------------------------------------
# CLEAR ALL DATA
# ----------------------------------------------------------------
puts "🧹 Clearing all existing data..."
ActiveRecord::Base.transaction do
  Comment.delete_all
  Like.delete_all
  Share.delete_all
  Friendship.delete_all
  Post.delete_all
  ActiveStorage::Attachment.delete_all
  ActiveStorage::Blob.delete_all
  User.delete_all
end
puts "✅ All data cleared"

# ----------------------------------------------------------------
# IMAGE HELPERS
# ----------------------------------------------------------------
def download_image(url, timeout: 15)
  downloaded = URI.open(
    url,
    ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,
    open_timeout: timeout,
    read_timeout: timeout,
    redirect: true
  )
  content = downloaded.read
  return nil if content.nil? || content.bytesize < 1000

  tmp = Tempfile.new(['img', '.jpg'], binmode: true)
  tmp.write(content)
  tmp.flush
  tmp.rewind
  tmp
rescue => e
  puts "  ⚠️  Download failed: #{e.message}"
  nil
end

def picsum(width, height, seed)
  download_image("https://picsum.photos/seed/#{seed}/#{width}/#{height}")
end

def cleanup(file)
  return unless file
  file.close rescue nil
  file.unlink rescue nil
end

# ----------------------------------------------------------------
# FETCH 300 AVATAR PHOTOS (randomuser.me — one API call)
# ----------------------------------------------------------------
puts "\n📡 Fetching 300 avatar photos from randomuser.me..."
avatar_urls = []
begin
  uri = URI("https://randomuser.me/api/?results=300&inc=picture&noinfo")
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                        verify_mode: OpenSSL::SSL::VERIFY_NONE,
                        open_timeout: 15, read_timeout: 20) { |h| h.get(uri.request_uri) }
  avatar_urls = JSON.parse(res.body)['results'].map { |r| r.dig('picture', 'large') }
  puts "✅ Got #{avatar_urls.size} avatar URLs"
rescue => e
  puts "⚠️  randomuser.me failed: #{e.message} — will use Picsum fallback"
end

# ----------------------------------------------------------------
# INDIAN DATA
# ----------------------------------------------------------------
INDIAN_NAMES = [
  ["Aarav","Sharma"],["Priya","Patel"],["Rohan","Verma"],["Anjali","Singh"],
  ["Karan","Gupta"],["Sneha","Reddy"],["Vivaan","Kumar"],["Divya","Mehta"],
  ["Arjun","Joshi"],["Neha","Kapoor"],["Aditya","Rao"],["Pooja","Nair"],
  ["Rahul","Desai"],["Kavya","Iyer"],["Siddharth","Malhotra"],["Riya","Chopra"],
  ["Varun","Agarwal"],["Ishita","Bansal"],["Ayush","Saxena"],["Tanvi","Kulkarni"],
  ["Harsh","Pandey"],["Shreya","Mishra"],["Yash","Tiwari"],["Ananya","Sinha"],
  ["Kunal","Bhatt"],["Sakshi","Jain"],["Nikhil","Shah"],["Aditi","Pillai"],
  ["Akash","Menon"],["Ritika","Bose"],["Manish","Ghosh"],["Simran","Dutta"],
  ["Gaurav","Chatterjee"],["Nidhi","Mukherjee"],["Abhishek","Das"],["Megha","Sen"],
  ["Vishal","Roy"],["Pallavi","Banerjee"],["Rajat","Saha"],["Swati","Ganguly"],
  ["Deepak","Thakur"],["Preeti","Yadav"],["Sandeep","Chauhan"],["Komal","Rawat"],
  ["Mohit","Bisht"],["Shweta","Negi"],["Ankit","Garg"],["Ritu","Arora"],
  ["Sumit","Bhatia"],["Nikita","Khanna"],["Pankaj","Sethi"],["Priyanka","Kohli"],
  ["Vikas","Dhawan"],["Sonal","Bajaj"],["Ashish","Mittal"],["Naveen","Goyal"],
  ["Shivani","Aggarwal"],["Manoj","Jindal"],["Ruchi","Tandon"],["Sanjay","Vohra"],
  ["Geeta","Bhatia"],["Ramesh","Sood"],["Sunita","Khurana"],["Suresh","Malhotra"],
  ["Rekha","Kapoor"],["Dinesh","Sharma"],["Meena","Verma"],["Rajesh","Gupta"],
  ["Seema","Singh"],["Anil","Kumar"],["Kavita","Reddy"],["Vinod","Mehta"],
  ["Usha","Joshi"],["Prakash","Rao"],["Lata","Nair"],["Sunil","Desai"],
  ["Asha","Iyer"],["Mukesh","Agarwal"],["Nisha","Bansal"],["Ajay","Saxena"],
  ["Vandana","Kulkarni"],["Ravi","Pandey"],["Madhuri","Mishra"],["Saurabh","Tiwari"],
  ["Aarti","Sinha"],["Tarun","Bhatt"],["Jyoti","Jain"],["Rohit","Shah"],
  ["Manisha","Pillai"],["Amit","Menon"],["Shalini","Bose"],["Kiran","Ghosh"],
  ["Deepika","Dutta"],["Sachin","Chatterjee"],["Anita","Mukherjee"],["Vikram","Das"],
  ["Sunita","Sen"],["Arun","Roy"],["Poonam","Banerjee"],["Alok","Tripathi"]
].freeze

CITIES = %w[Mumbai Delhi Bangalore Hyderabad Chennai Kolkata Pune Jaipur
            Ahmedabad Surat Lucknow Nagpur Indore Bhopal Patna Vadodara
            Chandigarh Guwahati Coimbatore Kochi Visakhapatnam Agra Varanasi].freeze

PROFESSIONS = ["Software Engineer","Doctor","Teacher","Business Owner","Data Analyst",
               "Graphic Designer","Photographer","Chef","Lawyer","Architect",
               "Marketing Manager","HR Manager","Content Writer","Digital Marketer",
               "CA","Civil Engineer","Professor","Journalist","Web Developer",
               "Fitness Trainer","Entrepreneur","Fashion Designer","Pharmacist"].freeze

HOBBIES = %w[cricket cooking traveling photography reading music dancing yoga
             painting singing gaming cycling swimming badminton chess gardening
             meditation writing movies fitness foodie blogging].freeze

POST_CONTENTS = [
  "आज का दिन बहुत अच्छा रहा! 🌟 #GoodVibes",
  "Just had the best biryani! 🍛 #FoodLover #IndianCuisine",
  "Weekend plans: Cricket match! 🏏 #CricketLove",
  "Celebrating Diwali with family! 🪔✨ #FestivalOfLights",
  "Morning chai hits different! ☕ #ChaiLover",
  "Exploring Old Delhi today! 🏛️ #TravelDiaries",
  "Great yoga session this morning! 🧘‍♀️ #YogaLife",
  "Love the monsoon rain! 🌧️ #MonsoonMagic",
  "Excited about new project! 💼 #WorkLife",
  "Family time is the best! ❤️ #FamilyFirst",
  "Trying Paneer Tikka recipe! 🍢 #Cooking",
  "Sunset at Marine Drive! 🌅 #Mumbai",
  "Amazing Bollywood movie last night! 🎬 #BollywoodFan",
  "Startup life is so rewarding! 💪 #Entrepreneur",
  "Team India victory! 🏆 #CricketFever",
  "Coffee and code! ☕💻 #DeveloperLife",
  "Goa trip was absolutely amazing! 🏖️ #BeachVibes",
  "Homemade dal makhani tonight! 😋 #IndianFood",
  "Morning walk at India Gate! 🚶‍♂️ #DelhiDiaries",
  "IPL match tonight! 🏏 #IPL #Cricket",
  "Street food at Chandni Chowk! 🍲 #StreetFood",
  "Holi celebrations with friends! 🎨 #FestivalOfColors",
  "New job, new beginnings! 🎉 #CareerGrowth",
  "Trekking in Himalayas! ⛰️ #Adventure",
  "Masala dosa for breakfast! 🥞 #SouthIndian",
  "Gateway of India visit! 🏛️ #MumbaiDiaries",
  "Taj Mahal darshan! 🕌 #WonderOfTheWorld",
  "Backwaters of Kerala! 🚣 #Kerala",
  "Rishikesh river rafting! 🌊 #Adventure",
  "Varanasi Ganga Aarti! 🪔 #Spiritual",
].freeze

COMMENTS = [
  "Bahut badhiya! 👏","Amazing! ❤️","Love this! 🔥","Bilkul sahi! 💯",
  "Kya baat hai! 🙌","So relatable!","Zabardast! 💪","Sahi hai bhai! 🤘",
  "Bohot accha! 😊","Mast hai! 🔥","Keep it up! ✨","Awesome! 👍",
  "Superb! 🌟","Waah! 😍","Kamaal ka! 🔥","Too good! 👌",
  "Shandar! ✨","Lajawab! 💯","Gazab! 🙌","Dhaasu! 💪",
  "Mindblowing! 🤯","Jhakaas! 🎊","Bindaas! 😎","Maza aa gaya! 😋",
  "On point! 🎯","Nailed it! 👏","Goals! 🎯","Vibes! ✨",
  "Facts! 📢","Fire! 🔥",
].freeze

# ----------------------------------------------------------------
# SUPER ADMIN
# ----------------------------------------------------------------
puts "\n🔐 Creating Super Admin..."
admin = User.create!(
  name:                  "Super Admin",
  email:                 "admin@sangam.com",
  password:              "Admin@123456",
  password_confirmation: "Admin@123456",
  super_admin:           true,
  bio:                   "Super Administrator of Sangam 🔮"
)
puts "✅ Super Admin: admin@sangam.com / Admin@123456"

# ----------------------------------------------------------------
# TEST USER (easy login for testing)
# ----------------------------------------------------------------
puts "\n👤 Creating Test User..."
test_user = User.create!(
  name:                  "Test User",
  email:                 "test@sangam.com",
  password:              "Test@123456",
  password_confirmation: "Test@123456",
  bio:                   "Test account for Sangam 🧪 | Mumbai"
)
puts "✅ Test User: test@sangam.com / Test@123456"

# ----------------------------------------------------------------
# 298 NORMAL USERS (total = 300 with admin + test)
# ----------------------------------------------------------------
puts "\n👥 Creating 298 normal users..."
users = [test_user]

298.times do |i|
  fname, lname = INDIAN_NAMES[i % INDIAN_NAMES.length]
  suffix       = i > 0 ? i.to_s : ""
  email        = "#{fname.downcase}.#{lname.downcase}#{suffix}@example.com"
  city         = CITIES.sample
  profession   = PROFESSIONS.sample
  hobby        = HOBBIES.sample(2).join(" & ")

  user = User.create!(
    name:                  "#{fname} #{lname}",
    email:                 email,
    password:              "password123",
    password_confirmation: "password123",
    bio:                   "#{profession} from #{city} | #{hobby} lover 🌟"
  )

  # Avatar
  avatar_file = avatar_urls[i] ? download_image(avatar_urls[i]) : nil
  avatar_file ||= picsum(400, 400, "avatar#{i}")
  if avatar_file
    user.avatar.attach(io: avatar_file, filename: "avatar_#{i}.jpg", content_type: "image/jpeg")
    cleanup(avatar_file)
  end

  # Cover photo
  cover_file = picsum(1200, 400, "cover#{i}")
  if cover_file
    user.cover_photo.attach(io: cover_file, filename: "cover_#{i}.jpg", content_type: "image/jpeg")
    cleanup(cover_file)
  end

  users << user
  puts "  ✅ [#{i+1}/298] #{user.name}" if (i + 1) % 30 == 0
end

puts "✅ #{users.count} normal users created (+ 1 admin = #{User.count} total)"

# ----------------------------------------------------------------
# FRIENDSHIPS — ~600 accepted + 100 pending
# ----------------------------------------------------------------
puts "\n🤝 Creating friendships..."
friendship_count = 0
attempts = 0

while friendship_count < 600 && attempts < 3000
  attempts += 1
  u = users.sample
  f = users.sample
  next if u == f
  next if Friendship.exists?(user_id: u.id, friend_id: f.id)
  next if Friendship.exists?(user_id: f.id, friend_id: u.id)

  Friendship.create!(user: u, friend: f, status: "accepted")
  friendship_count += 1
end

100.times do
  u = users.sample
  f = users.sample
  next if u == f
  next if Friendship.exists?(user_id: u.id, friend_id: f.id)
  next if Friendship.exists?(user_id: f.id, friend_id: u.id)
  Friendship.create!(user: u, friend: f, status: "pending")
end

puts "✅ #{friendship_count} friendships, 100 pending requests"

# ----------------------------------------------------------------
# POSTS — 600 posts (2 per user avg), each with 1-3 images
# ----------------------------------------------------------------
puts "\n📝 Creating 600 posts with images..."
posts = []
post_num = 0

600.times do |pi|
  user    = users.sample
  content = POST_CONTENTS.sample
  post    = user.posts.create!(content: content)

  img_count = rand(1..3)
  img_count.times do |ii|
    img = picsum(800, 600, "post#{pi}img#{ii}")
    if img
      post.images.attach(io: img, filename: "post#{pi}_#{ii}.jpg", content_type: "image/jpeg")
      cleanup(img)
    end
  end

  posts << post
  post_num += 1
  puts "  📸 #{post_num}/600 posts done" if post_num % 100 == 0
end

puts "✅ #{posts.count} posts created"

# ----------------------------------------------------------------
# LIKES — 5-20 per post
# ----------------------------------------------------------------
puts "\n❤️  Creating likes..."
like_count = 0

posts.each do |post|
  users.sample(rand(5..20)).each do |liker|
    next if liker.id == post.user_id
    reaction = %w[like love haha wow sad angry].sample
    like = Like.create(user: liker, post: post, reaction_type: reaction)
    like_count += 1 if like.persisted?
  end
end

puts "✅ #{like_count} likes"

# ----------------------------------------------------------------
# COMMENTS — 3-8 per post
# ----------------------------------------------------------------
puts "\n💬 Creating comments..."
comment_count = 0

posts.each do |post|
  users.sample(rand(3..8)).each do |commenter|
    comment = Comment.create(user: commenter, post: post, content: COMMENTS.sample)
    comment_count += 1 if comment.persisted?
  end
end

puts "✅ #{comment_count} comments"

# ----------------------------------------------------------------
# SHARES — 2-8 per post
# ----------------------------------------------------------------
puts "\n🔄 Creating shares..."
share_count = 0

posts.each do |post|
  users.sample(rand(2..8)).each do |sharer|
    next if sharer.id == post.user_id
    share = Share.create(user: sharer, post: post)
    share_count += 1 if share.persisted?
  end
end

puts "✅ #{share_count} shares"

# ----------------------------------------------------------------
# SUMMARY
# ----------------------------------------------------------------
puts "\n" + "=" * 55
puts "🎉  SEED COMPLETE!"
puts "=" * 55
puts "👥  Users:        #{User.count} (1 admin + 1 test + 298 normal)"
puts "📝  Posts:        #{Post.count}"
puts "🤝  Friendships:  #{Friendship.where(status: 'accepted').count}"
puts "📬  Pending:      #{Friendship.where(status: 'pending').count}"
puts "❤️   Likes:        #{Like.count}"
puts "💬  Comments:     #{Comment.count}"
puts "🔄  Shares:       #{Share.count}"
puts "=" * 55
puts ""
puts "🔐  SUPER ADMIN:"
puts "    Email:    admin@sangam.com"
puts "    Password: Admin@123456"
puts "    URL:      /admin/dashboard"
puts ""
puts "👤  TEST USER:"
puts "    Email:    test@sangam.com"
puts "    Password: Test@123456"
puts ""
puts "👥  NORMAL USERS:"
puts "    Email:    firstname.lastname0@example.com"
puts "    Password: password123"
puts "=" * 55
