class HomeController < ApplicationController
  def index
    if current_user.member?
      @expenses = current_user.expenses.order(created_at: :desc).limit(5)
    else
      @teams = current_user.approving_teams.order(:name)
      @pending_expenses = Expense.pending
                                 .where(user_id: User.where(team_id: @teams.select(:id)))
                                 .includes(:user, :category)
                                 .limit(5)
    end
  end
end
