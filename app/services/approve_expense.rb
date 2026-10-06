# The only place in the codebase allowed to write budgets.approved_total (D-04).
class ApproveExpense
  class Refused < StandardError; end

  def self.call(expense_id:, approver:)
    new(expense_id: expense_id, approver: approver).call
  end

  def initialize(expense_id:, approver:)
    @expense_id = expense_id
    @approver = approver
  end

  # Lock order is ALWAYS expense -> budget. Every future path must keep this
  # order or concurrent approvals can deadlock instead of serialising.
  def call
    Expense.transaction do
      # expense = Expense.find(@expense_id) for tests, but we need to lock the row for real concurrency.
      expense = Expense.lock.find(@expense_id)

      raise Refused, "承認者のみ承認できます" unless @approver.approver?
      raise Refused, "申請済みの申請のみ承認できます（I-05）" unless expense.submitted?
      raise Refused, "自分の申請は承認できません（A-04）" if expense.user_id == @approver.id

      budget = Budget.lock.find_by(
        team_id:     expense.user.team_id,
        category_id: expense.category_id,
        year_month:  expense.year_month
      )
      raise Refused, "対象月・カテゴリの予算がありません（A-03）" if budget.nil?

      # Re-read AFTER the lock. This is the line the race condition dies on.
      if budget.approved_total + expense.amount > budget.amount
        raise Refused, "残予算 #{budget.remaining} 円を超えるため承認できません（I-01）"
      end

      budget.update!(approved_total: budget.approved_total + expense.amount)
      expense.update!(status: :approved, decided_at: Time.current, decided_by: @approver)
      expense
    end
  end
end
