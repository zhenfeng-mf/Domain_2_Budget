class Expense < ApplicationRecord
  belongs_to :user
  belongs_to :category
  belongs_to :decided_by, class_name: "User", optional: true

  enum :status, { draft: 0, submitted: 1, approved: 2, rejected: 3 }, validate: true

  scope :pending, -> { where(status: :submitted).order(:submitted_at) }

  validates :used_on, presence: true
  validates :amount, numericality: { only_integer: true, greater_than_or_equal_to: 1 } # I-03
  validates :purpose, presence: true, length: { maximum: 255 }
  validate :used_on_is_immutable_once_out_of_draft   # I-08
  validate :terminal_states_are_immutable            # I-11 protects approved_total
  validate :matching_budget_must_exist, if: :requires_budget?  # I-10 / A-03

  def year_month
    MonthBucket.for(used_on)
  end

  def budget
    return nil if used_on.blank? || category_id.blank?
    Budget.for(team: user.team, category: category, on: used_on)
  end

  def editable_by?(actor)
    # A-01: a member may still fix a 申請済み request; 承認済み/却下 are terminal (A-02)
    user_id == actor.id && (draft? || submitted?)
  end

  private

  def requires_budget?
    !draft? && used_on.present? && category_id.present? && user_id.present?
  end

  def matching_budget_must_exist
    return if budget.present?
    errors.add(:base,
      "#{MonthBucket.label(used_on)} の #{category&.name} に予算が未設定のため申請できません（A-03）")
  end

  def used_on_is_immutable_once_out_of_draft
    return if new_record? || !used_on_changed?
    return if status_was == "draft"   # a draft may still move months (A-06)
    errors.add(:used_on, "は申請後は変更できません（I-08）")
  end

  def terminal_states_are_immutable
    return if new_record?
    return unless status_was.in?(%w[approved rejected])
    return if (changed - %w[updated_at]).empty?
    errors.add(:base, "承認済み・却下の申請は変更できません（I-11 / A-02）")
  end
end
