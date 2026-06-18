class UserTagAffinity < ApplicationRecord
  belongs_to :user
  belongs_to :category_tag
end
