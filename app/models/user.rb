class User < ApplicationRecord
  has_secure_password

  belongs_to :team
  has_many :expenses, dependent: :restrict_with_error
  has_many :approving_teams, class_name: "Team", foreign_key: :approver_id,
           inverse_of: :approver, dependent: :restrict_with_error

  enum :role, { member: 0, approver: 1 }, validate: true

  normalizes :email, with: ->(value) { value.to_s.strip.downcase }

  validates :name,  presence: true, length: { maximum: 50 }
  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
end
