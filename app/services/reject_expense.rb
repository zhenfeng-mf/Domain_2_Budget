class RejectExpense
  class Refused < StandardError; end

  def self.call(expense_id:, approver:)
    Expense.transaction do
      expense = Expense.lock.find(expense_id)
      raise Refused, "承認者のみ操作できます" unless approver.approver?
      raise Refused, "申請済みの申請のみ却下できます（I-05）" unless expense.submitted?
      raise Refused, "自分の申請は操作できません（A-04）" if expense.user_id == approver.id
      expense.update!(status: :rejected, decided_at: Time.current, decided_by: approver)
      expense
    end
  end
end
