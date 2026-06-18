FactoryBot.define do
  factory :post_category_tag do
    post { nil }
    category_tag { nil }
    confidence_score { 1.5 }
  end
end
