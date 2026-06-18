FactoryBot.define do
  factory :user_tag_affinity do
    user { nil }
    category_tag { nil }
    score { 1.5 }
  end
end
