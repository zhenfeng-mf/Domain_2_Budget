class Team < ApplicationRecord
  belongs_to :approver, class_name: "User"
  has_many :members, class_name: "User", dependent: :restrict_with_error
  has_many :budgets, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validate  :approver_must_have_approver_role

  private

  def approver_must_have_approver_role
    return if approver.nil?
    errors.add(:approver, "は承認者ロールである必要があります") unless approver.approver?
  end
end
