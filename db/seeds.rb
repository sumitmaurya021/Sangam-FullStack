# Clear existing data (except super admin)
puts "🧹 Clearing existing data..."
Comment.destroy_all
Like.destroy_all
Share.destroy_all
Friendship.destroy_all
Post.destroy_all
User.where(super_admin: false).destroy_all

# Create Super Admin first
load Rails.root.join('db', 'seeds', 'super_admin.rb')

# Setup for image downloads
require 'net/http'
require 'open-uri'
require 'openssl'
require 'uri'
require 'json'

# -------------------------------------------------------
# Fetch real human avatar photos from randomuser.me API
# -------------------------------------------------------
def fetch_user_photos(count)
  puts "📡 Fetching #{count} real human photos..."
  uri = URI("https://randomuser.me/api/?results=#{count}&inc=picture&noinfo")

  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                             verify_mode: OpenSSL::SSL::VERIFY_NONE,
                             open_timeout: 10, read_timeout: 15) do |http|
    http.get(uri.request_uri)
  end

  data    = JSON.parse(response.body)
  photos  = data['results'].map { |r| r.dig('picture', 'large') }
  puts "✅ Got #{photos.size} photos"
  photos
rescue => e
  puts "  ⚠️  API Error: #{e.message}"
  []
end

# Fetch random photos from Lorem Picsum (more reliable than Unsplash)
def fetch_picsum_photo(width, height, seed_num)
  url = "https://picsum.photos/#{width}/#{height}?random=#{seed_num}"
  download_image(url)
rescue => e
  puts "  ⚠️  Picsum Error: #{e.message}"
  nil
end

def download_image(url, retry_count = 3)
  retry_count.times do |attempt|
    begin
      # Use open-uri which automatically follows redirects
      downloaded = URI.open(url, 
                           ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,
                           open_timeout: 15,
                           read_timeout: 20,
                           redirect: true)
      
      # Read the content
      content = downloaded.read
      
      if content && content.bytesize > 0
        ext = File.extname(URI(url).path).presence || '.jpg'
        tmp = Tempfile.new(['photo', ext], binmode: true)
        tmp.write(content)
        tmp.flush
        tmp.rewind
        
        puts "  ✓ Downloaded #{tmp.size} bytes"
        return tmp
      else
        puts "  ⚠️  Attempt #{attempt + 1}: Empty response"
      end
      
      sleep(1) if attempt < retry_count - 1
    rescue => e
      puts "  ⚠️  Attempt #{attempt + 1} failed: #{e.message}"
      sleep(1) if attempt < retry_count - 1
    end
  end
  
  puts "  ❌ All download attempts failed"
  nil
end

# -------------------------------------------------------
# Indian Data
# -------------------------------------------------------
INDIAN_NAMES = [
  ["Aarav", "Sharma"], ["Priya", "Patel"], ["Rohan", "Verma"], ["Anjali", "Singh"],
  ["Karan", "Gupta"], ["Sneha", "Reddy"], ["Vivaan", "Kumar"], ["Divya", "Mehta"],
  ["Arjun", "Joshi"], ["Neha", "Kapoor"], ["Aditya", "Rao"], ["Pooja", "Nair"],
  ["Rahul", "Desai"], ["Kavya", "Iyer"], ["Siddharth", "Malhotra"], ["Riya", "Chopra"],
  ["Varun", "Agarwal"], ["Ishita", "Bansal"], ["Ayush", "Saxena"], ["Tanvi", "Kulkarni"],
  ["Harsh", "Pandey"], ["Shreya", "Mishra"], ["Yash", "Tiwari"], ["Ananya", "Sinha"],
  ["Kunal", "Bhatt"], ["Sakshi", "Jain"], ["Nikhil", "Shah"], ["Aditi", "Pillai"],
  ["Akash", "Menon"], ["Ritika", "Bose"], ["Manish", "Ghosh"], ["Simran", "Dutta"],
  ["Gaurav", "Chatterjee"], ["Nidhi", "Mukherjee"], ["Abhishek", "Das"], ["Megha", "Sen"],
  ["Vishal", "Roy"], ["Pallavi", "Banerjee"], ["Rajat", "Saha"], ["Swati", "Ganguly"],
  ["Deepak", "Thakur"], ["Preeti", "Yadav"], ["Sandeep", "Chauhan"], ["Komal", "Rawat"],
  ["Mohit", "Bisht"], ["Shweta", "Negi"], ["Ankit", "Garg"], ["Ritu", "Arora"],
  ["Sumit", "Bhatia"], ["Nikita", "Khanna"], ["Pankaj", "Sethi"], ["Anjali", "Kohli"],
  ["Vikas", "Dhawan"], ["Sonal", "Bajaj"], ["Ashish", "Mittal"], ["Priyanka", "Singhal"],
  ["Naveen", "Goyal"], ["Shivani", "Aggarwal"], ["Manoj", "Jindal"], ["Ruchi", "Tandon"],
  ["Sanjay", "Vohra"], ["Geeta", "Bhatia"], ["Ramesh", "Sood"], ["Sunita", "Khurana"],
  ["Suresh", "Malhotra"], ["Rekha", "Kapoor"], ["Dinesh", "Sharma"], ["Meena", "Verma"],
  ["Rajesh", "Gupta"], ["Seema", "Singh"], ["Anil", "Kumar"], ["Kavita", "Reddy"],
  ["Vinod", "Mehta"], ["Usha", "Joshi"], ["Prakash", "Rao"], ["Lata", "Nair"],
  ["Sunil", "Desai"], ["Asha", "Iyer"], ["Mukesh", "Agarwal"], ["Nisha", "Bansal"],
  ["Ajay", "Saxena"], ["Vandana", "Kulkarni"], ["Ravi", "Pandey"], ["Madhuri", "Mishra"],
  ["Saurabh", "Tiwari"], ["Aarti", "Sinha"], ["Tarun", "Bhatt"], ["Jyoti", "Jain"],
  ["Rohit", "Shah"], ["Manisha", "Pillai"], ["Amit", "Menon"], ["Shalini", "Bose"],
  ["Kiran", "Ghosh"], ["Deepika", "Dutta"], ["Sachin", "Chatterjee"], ["Anita", "Mukherjee"],
  ["Vikram", "Das"], ["Sunita", "Sen"], ["Arun", "Roy"], ["Poonam", "Banerjee"]
]

INDIAN_CITIES      = %w[Mumbai Delhi Bangalore Hyderabad Chennai Kolkata Pune Jaipur Ahmedabad Surat Lucknow Kanpur Nagpur Indore Thane Bhopal Visakhapatnam Pimpri-Chinchwad Patna Vadodara Ghaziabad Ludhiana Agra Nashik Faridabad Meerut Rajkot Kalyan-Dombivli Vasai-Virar Varanasi Srinagar Aurangabad Dhanbad Amritsar Navi-Mumbai Allahabad Ranchi Howrah Coimbatore Jabalpur Gwalior Vijayawada Jodhpur Madurai Raipur Kota Chandigarh Guwahati]

INDIAN_PROFESSIONS = ["Software Engineer", "Doctor", "Teacher", "Business Owner", "Data Analyst", 
                      "Graphic Designer", "Photographer", "Chef", "Lawyer", "Architect", 
                      "Marketing Manager", "HR Manager", "Sales Executive", "Content Writer", 
                      "Digital Marketer", "CA", "Engineer", "Consultant", "Entrepreneur", 
                      "Fashion Designer", "Interior Designer", "Fitness Trainer", "Pharmacist",
                      "Bank Manager", "Civil Engineer", "Mechanical Engineer", "Professor",
                      "Journalist", "Video Editor", "Web Developer", "Mobile App Developer"]

INDIAN_HOBBIES     = %w[cricket cooking traveling photography reading music dancing yoga painting 
                        singing blogging gaming cycling swimming badminton football chess 
                        gardening meditation sketching writing poetry movies shopping hiking 
                        volunteering coding fitness fashion foodie]

POST_CONTENTS = [
  "आज का दिन बहुत अच्छा रहा! 🌟 #GoodVibes #IndianLife",
  "Just had the best biryani! 🍛 #FoodLover #IndianCuisine",
  "Weekend plans: Cricket match! 🏏 #CricketLove",
  "Celebrating Diwali with family! 🪔✨ #FestivalOfLights",
  "Morning chai hits different! ☕ #ChaiLover",
  "Exploring Old Delhi today! 🏛️ #TravelDiaries",
  "Great yoga session! 🧘‍♀️ #YogaLife #Wellness",
  "Love the monsoon rain! 🌧️ #MonsoonMagic",
  "Excited about new project! 💼 #WorkLife",
  "Family time is the best! ❤️ #FamilyFirst",
  "Trying Paneer Tikka recipe! 🍢 #Cooking",
  "Sunset at Marine Drive! 🌅 #Mumbai",
  "Amazing Bollywood movie! 🎬 #BollywoodFan",
  "Startup life is rewarding! 💪 #Entrepreneur",
  "Team India victory! 🏆 #CricketFever",
  "Coffee and code! ☕💻 #DeveloperLife",
  "Goa trip was amazing! 🏖️ #BeachVibes #GoaDiaries",
  "Homemade dal makhani! 😋 #IndianFood #Foodie",
  "Morning walk at India Gate! 🚶‍♂️ #DelhiDiaries",
  "IPL match tonight! 🏏 #IPL2024 #Cricket",
  "Trying street food at Chandni Chowk! 🍲 #StreetFood",
  "Holi celebrations! 🎨 #FestivalOfColors #Holi",
  "New job, new beginnings! 🎉 #CareerGrowth",
  "Ganesh Chaturthi vibes! 🙏 #GanpatiBappaMorya",
  "Trekking in Himalayas! ⛰️ #Adventure #Trekking",
  "Navratri dandiya night! 💃 #Navratri #Garba",
  "Masala dosa for breakfast! 🥞 #SouthIndian",
  "Gateway of India visit! 🏛️ #MumbaiDiaries",
  "Eid Mubarak to all! 🌙 #EidCelebration",
  "Taj Mahal darshan! 🕌 #WonderOfTheWorld #Agra",
  "Pongal celebrations! 🍚 #TamilFestival #Pongal",
  "Durga Puja pandal hopping! 🎭 #DurgaPuja #Kolkata",
  "Onam Sadhya feast! 🍛 #Onam #Kerala",
  "Lohri bonfire night! 🔥 #Lohri #Punjab",
  "Baisakhi harvest festival! 🌾 #Baisakhi #Celebration",
  "Janmashtami dahi handi! 🏺 #Janmashtami #Krishna",
  "Raksha Bandhan memories! 🎀 #RakshaBandhan #Siblings",
  "Karva Chauth fasting! 🌙 #KarvaChauth #Tradition",
  "Makar Sankranti kite flying! 🪁 #MakarSankranti",
  "Ugadi new year celebration! 🎊 #Ugadi #NewYear",
  "Bihu dance performance! 💃 #Bihu #Assam",
  "Thrissur Pooram festival! 🐘 #ThrissurPooram",
  "Pushkar Camel Fair! 🐪 #Pushkar #Rajasthan",
  "Hornbill Festival experience! 🎭 #Nagaland #Festival",
  "Hemis Festival in Ladakh! 🏔️ #Ladakh #HemisFestival",
  "Konark Sun Temple visit! ☀️ #Odisha #Heritage",
  "Hampi ruins exploration! 🏛️ #Karnataka #History",
  "Backwaters of Kerala! 🚣 #Kerala #Backwaters",
  "Rishikesh river rafting! 🌊 #Adventure #Rishikesh",
  "Varanasi Ganga Aarti! 🪔 #Varanasi #Spiritual"
]

COMMENTS_LIST = [
  "Bahut badhiya! 👏", "Amazing post! ❤️", "Love this! 🔥",
  "Bilkul sahi! 💯", "Kya baat hai! 🙌", "So relatable!",
  "Zabardast! 💪", "Sahi hai bhai! 🤘", "Bohot accha! 😊",
  "Mast hai! 🔥", "Keep it up! ✨", "Awesome! 👍",
  "Ekdum mast! 🎉", "Superb! 🌟", "Waah! 😍",
  "Kamaal ka! 🔥", "Dil jeet liya! ❤️", "Too good! 👌",
  "Shandar! ✨", "Lajawab! 💯", "Gazab! 🙌",
  "Dhaasu! 💪", "Ekdum perfect! 👏", "Mindblowing! 🤯",
  "Khatarnak! 🔥", "Jhakaas! 🎊", "Bindaas! 😎",
  "Maza aa gaya! 😋", "Shandaar! 🌟", "Kamaal! 👍",
  "Ekdum solid! 💪", "Bahut hard! 🔥", "Lit hai! 🔥",
  "Dope! 🎯", "Fire! 🔥", "Sick! 😍",
  "Killing it! 💯", "On point! 🎯", "Nailed it! 👏",
  "Slaying! 💅", "Goals! 🎯", "Vibes! ✨",
  "Mood! 😊", "Same! 🙌", "Felt! ❤️",
  "Real! 💯", "Facts! 📢", "Truth! ✅"
]

# -------------------------------------------------------
# 1000 Users (Indian names)
# -------------------------------------------------------
puts "\n👥 Creating 1000 users..."
users        = []
human_photos = fetch_user_photos(1000)

1000.times do |i|
  if i < 999
    fname, lname = INDIAN_NAMES[i % INDIAN_NAMES.length]
    email_addr   = "#{fname.downcase}.#{lname.downcase}#{i}@example.com"
  else
    fname, lname = "Test", "User"
    email_addr   = "test@example.com"
  end

  city       = INDIAN_CITIES.sample
  profession = INDIAN_PROFESSIONS.sample
  hobby      = INDIAN_HOBBIES.sample(2).join(", ")

  user = User.create!(
    name:                  "#{fname} #{lname}",
    email:                 email_addr,
    password:              "password123",
    password_confirmation: "password123",
    bio:                   "#{profession} from #{city} | #{hobby} lover 🌟"
  )

  # Avatar — real human photo with retry
  avatar_file = nil
  if human_photos[i]
    puts "  📥 Downloading avatar from randomuser.me..."
    avatar_file = download_image(human_photos[i])
  end
  
  # If download failed, try Picsum as backup
  if avatar_file.nil?
    puts "  🔄 Trying Picsum for #{fname} avatar..."
    avatar_file = fetch_picsum_photo(400, 400, i * 100)
  end
  
  # If still failed, try another Picsum seed
  if avatar_file.nil?
    puts "  🔄 Retrying with different Picsum seed..."
    avatar_file = fetch_picsum_photo(400, 400, (i * 100) + 999)
  end
  
  if avatar_file && avatar_file.size > 0
    user.avatar.attach(io: avatar_file, filename: "avatar_#{i}.jpg", content_type: 'image/jpeg')
    puts "  ✅ Avatar attached: #{avatar_file.size} bytes"
  else
    puts "  ❌ Avatar failed for #{fname} - no image attached"
  end
  avatar_file.close if avatar_file
  avatar_file.unlink if avatar_file rescue nil

  # Cover photo - use Picsum with retry
  puts "  📥 Downloading cover photo..."
  cover_file = fetch_picsum_photo(1200, 400, (i + 100) * 10)
  
  # Retry with different seed if failed
  if cover_file.nil?
    puts "  🔄 Retrying cover photo..."
    cover_file = fetch_picsum_photo(1200, 400, (i + 200) * 10)
  end
  
  if cover_file && cover_file.size > 0
    user.cover_photo.attach(io: cover_file, filename: "cover_#{i}.jpg", content_type: 'image/jpeg')
    puts "  ✅ Cover attached: #{cover_file.size} bytes"
  else
    puts "  ❌ Cover photo failed for #{fname} - no image attached"
  end
  cover_file.close if cover_file
  cover_file.unlink if cover_file rescue nil

  users << user
  puts "  ✅ #{user.name} (#{user.email})"
end

puts "✅ Total users: #{users.count}"

# -------------------------------------------------------
# Friendships — 3000 random friendships
# -------------------------------------------------------
puts "\n🤝 Creating friendships (3000 random)..."
friendship_count = 0

3000.times do
  u = users.sample
  f = users.sample
  next if u == f || u.friends_with?(f) || u.friend_request_pending?(f)
  
  fr = u.friendships.create(friend: f, status: 'accepted')
  friendship_count += 1 if fr.persisted?
end

# 200 pending requests
puts "📬 Creating 200 pending friend requests..."
200.times do
  u = users.sample
  f = users.sample
  next if u == f || u.friends_with?(f) || u.friend_request_pending?(f)
  
  u.friendships.create(friend: f, status: 'pending')
end

puts "✅ #{friendship_count} friendships, 200 pending requests"

# -------------------------------------------------------
# Posts — 5000 posts, each with 3-5 images
# -------------------------------------------------------
puts "\n📝 Creating posts (5000 posts, 3-5 images each)..."
post_count = 0

5000.times do |pi|
  user = users.sample
  post = user.posts.create!(content: POST_CONTENTS.sample)
  image_count = rand(3..5)
  attached_count = 0

  image_count.times do |ii|
    seed_num = (post_count * 1000) + (ii * 100) + rand(1..99)
    
    # Try Picsum with unique seed
    img = fetch_picsum_photo(800, 600, seed_num)
    
    # Retry with different seed if failed
    if img.nil?
      img = fetch_picsum_photo(800, 600, seed_num + 5000)
    end
    
    if img && img.size > 0
      begin
        post.images.attach(io: img, filename: "p#{post_count}_i#{ii}.jpg", content_type: 'image/jpeg')
        attached_count += 1
      rescue => e
        puts "    ❌ Attach failed: #{e.message}"
      end
    end
    
    # Close file after attachment
    img.close if img
    img.unlink if img rescue nil
  end

  post_count += 1
  puts "  📸 Post #{post_count}: #{user.name} — #{attached_count}/#{image_count} images attached" if post_count % 50 == 0
end
puts "✅ #{post_count} posts created"

# -------------------------------------------------------
# Likes — 5-15 per post (random)
# -------------------------------------------------------
puts "\n❤️  Creating likes (5-15 per post)..."
like_count = 0

Post.find_each do |post|
  num_likes = rand(5..15)
  users.sample(num_likes).each do |liker|
    next if liker.id == post.user_id
    reaction = %w[like love haha wow sad angry].sample
    like     = post.likes.create(user: liker, reaction_type: reaction)
    like_count += 1 if like.persisted?
  end
end
puts "✅ #{like_count} likes"

# -------------------------------------------------------
# Comments — 3-8 per post, 1-3 replies per comment
# -------------------------------------------------------
puts "\n💬 Creating comments (3-8 per post)..."
comment_count = 0
reply_count   = 0

Post.find_each do |post|
  num_comments = rand(3..8)
  users.sample(num_comments).each do |commenter|
    comment = post.comments.create(
      user:      commenter,
      content:   COMMENTS_LIST.sample,
      parent_id: nil
    )
    next unless comment.persisted?
    comment_count += 1

    # 1-3 replies per comment
    num_replies = rand(1..3)
    users.sample(num_replies).each do |replier|
      reply = post.comments.create(
        user:      replier,
        content:   COMMENTS_LIST.sample,
        parent_id: comment.id
      )
      reply_count += 1 if reply.persisted?
    end
  end
end
puts "✅ #{comment_count} comments, #{reply_count} replies"

# -------------------------------------------------------
# Shares — 2-10 per post (random)
# -------------------------------------------------------
puts "\n🔄 Creating shares (2-10 per post)..."
share_count = 0

Post.find_each do |post|
  num_shares = rand(2..10)
  users.sample(num_shares).each do |sharer|
    next if sharer.id == post.user_id
    share = post.shares.create(user: sharer)
    share_count += 1 if share.persisted?
  end
end
puts "✅ #{share_count} shares"

# -------------------------------------------------------
# Summary
# -------------------------------------------------------
puts "\n" + "=" * 50
puts "🎉 Seed complete!"
puts "=" * 50
puts "👥 Users:       #{User.count}"
puts "📝 Posts:       #{Post.count}"
puts "🤝 Friendships: #{Friendship.where(status: 'accepted').count}"
puts "📬 Pending:     #{Friendship.where(status: 'pending').count}"
puts "❤️  Likes:       #{Like.count}"
puts "💬 Comments:    #{Comment.count}"
puts "🔄 Shares:      #{Share.count}"
puts "=" * 50
puts "🔑 test@example.com / password123"
puts "=" * 50
