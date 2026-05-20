FactoryBot.define do
  factory :post do
    user { nil }
    content { "MyText" }
    image { "MyString" }
    likes_count { 1 }
    comments_count { 1 }
    shares_count { 1 }
  end
end
