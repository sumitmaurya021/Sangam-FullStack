class PostCategoryTag < ApplicationRecord
  belongs_to :post
  belongs_to :category_tag
end
