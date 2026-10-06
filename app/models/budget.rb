class Budget < ApplicationRecord
  belongs_to :team
  belongs_to :category

  validates :year_month, presence: true,
            uniqueness: { scope: %i[team_id category_id] }          # I-02 app layer
  validates :amount, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :approved_total,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :year_month_must_be_first_of_month                        # D-08
  validate :amount_must_cover_approved_total                         # I-04
  validate :team_must_have_an_approver, on: :create                  # D-10
  validate :past_months_cannot_be_created, on: :create               # I-09
  validate :only_future_months_may_change_amount, on: :update        # I-09

  def self.for(team:, category:, on:)
    find_by(team: team, category: category, year_month: MonthBucket.for(on))
  end

  def remaining
    amount - approved_total
  end

  # Reconciliation: the truth D-04 promises to track.
  def approved_sum
    Expense.approved
           .where(category_id: category_id)
           .where(user_id: team.members.select(:id))
           .where(used_on: year_month..year_month.end_of_month)
           .sum(:amount)
  end

  private

  def year_month_must_be_first_of_month
    return if year_month.blank?
    return if year_month == MonthBucket.for(year_month)
    errors.add(:year_month, "は月初日で保存してください")
  end

  def amount_must_cover_approved_total
    return if amount.blank? || approved_total.blank?
    return if amount >= approved_total
    errors.add(:amount, "は承認済み合計 #{approved_total} 円を下回れません（I-04）")
  end

  def team_must_have_an_approver
    errors.add(:team, "に承認者が設定されていません") if team.present? && team.approver_id.nil?
  end

  def past_months_cannot_be_created
    return if year_month.blank?
    return if year_month >= MonthBucket.current
    errors.add(:year_month, "は過去月の予算を作成できません（I-09）")
  end

  def only_future_months_may_change_amount
    return unless amount_changed?          # approved_total updates are unaffected
    return if year_month.present? && year_month > MonthBucket.current
    errors.add(:year_month, "は翌月以降の予算のみ変更できます（I-09）")
  end
end
