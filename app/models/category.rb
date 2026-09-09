class Category < ApplicationRecord
  has_many :budgets,  dependent: :restrict_with_error
  has_many :expenses, dependent: :restrict_with_error
  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
end
