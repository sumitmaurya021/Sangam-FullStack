FactoryBot.define do
  factory :article do
    title { "MyString" }
    user { nil }
    views_count { 1 }
    published { false }
  end
end
