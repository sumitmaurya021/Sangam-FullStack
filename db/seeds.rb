# Clear existing data
puts "🧹 Clearing existing data..."
Comment.destroy_all
Like.destroy_all
Share.destroy_all
Friendship.destroy_all
Post.destroy_all
User.destroy_all

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
  ["Aarav",    "Sharma"],
  ["Priya",    "Patel"],
  ["Rohan",    "Verma"],
  ["Anjali",   "Singh"],
  ["Karan",    "Gupta"],
  ["Sneha",    "Reddy"],
  ["Vivaan",   "Kumar"],
  ["Divya",    "Mehta"],
  ["Arjun",    "Joshi"],
  ["Neha",     "Kapoor"]
]

INDIAN_CITIES      = %w[Mumbai Delhi Bangalore Hyderabad Chennai Kolkata Pune Jaipur]
INDIAN_PROFESSIONS = ["Software Engineer", "Doctor", "Teacher", "Business Owner",
                      "Data Analyst", "Graphic Designer", "Photographer", "Chef"]
INDIAN_HOBBIES     = %w[cricket cooking traveling photography reading music dancing yoga]

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
  "Coffee and code! ☕💻 #DeveloperLife"
]

COMMENTS_LIST = [
  "Bahut badhiya! 👏",   "Amazing post! ❤️",    "Love this! 🔥",
  "Bilkul sahi! 💯",     "Kya baat hai! 🙌",    "So relatable!",
  "Zabardast! 💪",       "Sahi hai bhai! 🤘",   "Bohot accha! 😊",
  "Mast hai! 🔥",        "Keep it up! ✨",       "Awesome! �"
]

# -------------------------------------------------------
# 3 Users only
# -------------------------------------------------------
puts "\n👥 Creating 3 users..."
users        = []
human_photos = fetch_user_photos(4) # 3 + 1 test user

4.times do |i|
  if i < 3
    fname, lname = INDIAN_NAMES[i]
    email_addr   = "#{fname.downcase}.#{lname.downcase}#{i}@example.com"
  else
    fname, lname = "Rahul", "Sharma"
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
# Friendships — max 3
# -------------------------------------------------------
puts "\n🤝 Creating friendships (max 3)..."
friendship_count = 0

[
  [users[0], users[1]],
  [users[1], users[2]],
  [users[0], users[2]]
].each do |u, f|
  next if u.friends_with?(f) || u.friend_request_pending?(f)
  fr = u.friendships.create(friend: f, status: 'accepted')
  friendship_count += 1 if fr.persisted?
end

# 1 pending request
u = users[3]; f = users[0]
u.friendships.create(friend: f, status: 'pending') unless u.friend_request_pending?(f)

puts "✅ #{friendship_count} friendships, 1 pending request"

# -------------------------------------------------------
# Posts — 3 per user, each with 7-9 images
# -------------------------------------------------------
puts "\n📝 Creating posts (3 per user, 7-9 images each)..."
post_count = 0

users.each do |user|
  3.times do |pi|
    post = user.posts.create!(content: POST_CONTENTS.sample)
    image_count = rand(7..9)
    attached_count = 0

    image_count.times do |ii|
      seed_num = (post_count * 1000) + (ii * 100) + rand(1..99)
      
      # Try Picsum with unique seed
      img = fetch_picsum_photo(800, 600, seed_num)
      
      # Retry with different seed if failed
      if img.nil?
        puts "    🔄 Retrying image #{ii + 1}..."
        img = fetch_picsum_photo(800, 600, seed_num + 5000)
      end
      
      # One more retry with completely different seed
      if img.nil?
        puts "    🔄 Final retry for image #{ii + 1}..."
        img = fetch_picsum_photo(800, 600, Time.now.to_i + ii)
      end
      
      if img && img.size > 0
        begin
          post.images.attach(io: img, filename: "p#{post_count}_i#{ii}.jpg", content_type: 'image/jpeg')
          attached_count += 1
          puts "    ✅ Image #{ii + 1} attached: #{img.size} bytes"
        rescue => e
          puts "    ❌ Attach failed: #{e.message}"
        end
      else
        puts "    ❌ Image #{ii + 1} failed - skipping"
      end
      
      # Close file after attachment
      img.close if img
      img.unlink if img rescue nil
    end

    post_count += 1
    puts "  📸 Post #{post_count}: #{user.name} — #{attached_count}/#{image_count} images attached"
  end
end
puts "✅ #{post_count} posts created"

# -------------------------------------------------------
# Likes — max 3 per post
# -------------------------------------------------------
puts "\n❤️  Creating likes (max 3 per post)..."
like_count = 0

Post.find_each do |post|
  users.sample(3).each do |liker|
    reaction = %w[like love haha wow sad angry].sample
    like     = post.likes.create(user: liker, reaction_type: reaction)
    like_count += 1 if like.persisted?
  end
end
puts "✅ #{like_count} likes"

# -------------------------------------------------------
# Comments — max 3 per post, max 2 replies per comment
# -------------------------------------------------------
puts "\n💬 Creating comments (max 3 per post)..."
comment_count = 0
reply_count   = 0

Post.find_each do |post|
  users.sample(3).each do |commenter|
    comment = post.comments.create(
      user:      commenter,
      content:   COMMENTS_LIST.sample,
      parent_id: nil
    )
    next unless comment.persisted?
    comment_count += 1

    # max 2 replies
    users.sample(2).each do |replier|
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
# Shares — max 3 per post
# -------------------------------------------------------
puts "\n🔄 Creating shares (max 3 per post)..."
share_count = 0

Post.find_each do |post|
  users.sample(3).each do |sharer|
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
