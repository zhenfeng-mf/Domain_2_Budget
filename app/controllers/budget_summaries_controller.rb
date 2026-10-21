class BudgetSummariesController < ApplicationController
  def index
    scope = if current_user.member?
      Budget.where(team_id: current_user.team_id)
    else
      Budget.joins(:team).where(teams: { approver_id: current_user.id })
    end

    @budgets = scope.includes(:team, :category).order(year_month: :desc, id: :desc)
  end
end
