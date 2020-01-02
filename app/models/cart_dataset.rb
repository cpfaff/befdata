# frozen_string_literal: true

## Links "Cart"s to "Dataset"s and maps to the "cart_datasets" table.
class CartDataset < ApplicationRecord
  belongs_to :cart
  belongs_to :dataset
  validates_uniqueness_of :dataset_id, scope: :cart_id
end
