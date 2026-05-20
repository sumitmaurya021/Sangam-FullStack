# Clear existing data
puts "Clearing existing data..."
Comment.destroy_all
Like.destroy_all
Share.destroy_all
Friendship.destroy_all
Post.destroy_all
User.destroy_all

# Create users
puts "Creating users..."
users = []

10.times do |i|
  user = User.create!(
    name: Faker::Name.name,
    email: "user#{i+1}@example.com",
    password: "password123",
    password_confirmation: "password123",
    bio: Faker::Lorem.sentence(word_count: 10)
  )
  users << user
  puts "Created user: #{user.name}"
end

# Create main test user
main_user = User.create!(
  name: "Test User",
  email: "test@example.com",
  password: "password123",
  password_confirmation: "password123",
  bio: "This is a test user account"
)
users << main_user
puts "Created main test user: #{main_user.email}"

# Create friendships
puts "\nCreating friendships..."
users.each_with_index do |user, i|
  # Each user befriends 3-5 random other users
  friends_count = rand(3..5)
  potential_friends = users - [user]
  
  friends_count.times do
    friend = potential_friends.sample
    next if user.friends_with?(friend) || user.friend_request_pending?(friend)
    
    friendship = user.friendships.create(friend: friend, status: 'accepted')
    puts "#{user.name} is now friends with #{friend.name}" if friendship.persisted?
  end
end

# Create some pending friend requests
puts "\nCreating pending friend requests..."
5.times do
  user = users.sample
  friend = (users - [user]).sample
  next if user.friends_with?(friend) || user.friend_request_pending?(friend)
  
  friendship = user.friendships.create(friend: friend, status: 'pending')
  puts "#{user.name} sent friend request to #{friend.name}" if friendship.persisted?
end

# Create posts
puts "\nCreating posts..."
users.each do |user|
  rand(3..8).times do
    post = user.posts.create!(
      content: Faker::Lorem.paragraph(sentence_count: rand(2..5))
    )
    puts "Created post by #{user.name}"
    
    # Add likes to posts
    likers = users.sample(rand(0..7))
    likers.each do |liker|
      post.likes.create(user: liker)
    end
    
    # Add comments to posts
    commenters = users.sample(rand(0..5))
    commenters.each do |commenter|
      post.comments.create!(
        user: commenter,
        content: Faker::Lorem.sentence(word_count: rand(5..15))
      )
    end
    
    # Add shares to posts
    sharers = users.sample(rand(0..3))
    sharers.each do |sharer|
      post.shares.create(user: sharer)
    end
  end
end

puts "\n✅ Seed data created successfully!"
puts "\n📊 Summary:"
puts "Users: #{User.count}"
puts "Posts: #{Post.count}"
puts "Friendships: #{Friendship.count}"
puts "Likes: #{Like.count}"
puts "Comments: #{Comment.count}"
puts "Shares: #{Share.count}"
puts "\n🔑 Test Account:"
puts "Email: test@example.com"
puts "Password: password123"
