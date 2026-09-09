# test/models/concurrent_approval_test.rb
require "test_helper"

# The D-05 proof. Two real connections, so transactional tests must be off:
# each thread has to see the other thread's committed rows.
class ConcurrentApprovalTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    @team     = Team.create!(name: "Race #{SecureRandom.hex(4)}")
    @approver = User.create!(name: "承認者", email: "race-a-#{SecureRandom.hex(4)}@example.com",
                             password: "password", role: :approver, team: @team)
    @team.update!(approver: @approver)
    @member   = User.create!(name: "申請者", email: "race-m-#{SecureRandom.hex(4)}@example.com",
                             password: "password", role: :member, team: @team)
    @category = Category.create!(name: "Race #{SecureRandom.hex(4)}")
    @budget   = Budget.create!(team: @team, category: @category,
                               year_month: MonthBucket.current, amount: 10_000)
    @first, @second = 2.times.map do |i|
      Expense.create!(user: @member, category: @category, used_on: Time.zone.today,
                      amount: 6_000, purpose: "race #{i}", status: :submitted,
                      submitted_at: Time.current)
    end
  end

  teardown do
    Expense.where(id: [@first.id, @second.id]).delete_all
    Budget.where(id: @budget.id).delete_all
    @team.update_columns(approver_id: nil)
    User.where(id: [@approver.id, @member.id]).delete_all
    Team.where(id: @team.id).delete_all
    Category.where(id: @category.id).delete_all
  end

  test "two simultaneous approvals can never overspend one budget" do
    gate = Concurrent::CyclicBarrier.new(2)
    outcomes = Queue.new

    [@first, @second].map { |expense|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          gate.wait # both threads enter the transaction at the same moment
          begin
            ApproveExpense.call(expense_id: expense.id, approver: @approver)
            outcomes << :approved
          rescue ApproveExpense::Refused, ActiveRecord::StatementInvalid,
                 ActiveRecord::Deadlocked
            outcomes << :refused
          end
        end
      end
    }.each(&:join)

    results = Array.new(outcomes.size) { outcomes.pop }

    assert_equal 1, results.count(:approved), "exactly one approval may win"
    assert_equal 1, results.count(:refused),  "the second must be refused, not queued"

    @budget.reload
    assert_equal 6_000, @budget.approved_total
    assert_operator @budget.approved_total, :<=, @budget.amount, "I-01 must hold"
    assert_equal @budget.approved_sum, @budget.approved_total, "counter must not drift"
    assert_equal 1, Expense.approved.where(id: [@first.id, @second.id]).count
  end
end
