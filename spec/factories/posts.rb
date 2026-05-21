FactoryBot.define do
  factory :post do
    user
    content { Faker::Lorem.paragraph(sentence_count: 3) }
    likes_count { 0 }
    comments_count { 0 }
    shares_count { 0 }
    
    # Don't set image by default as it requires ActiveStorage setup
    # Tests can attach images individually if needed
  end
end
