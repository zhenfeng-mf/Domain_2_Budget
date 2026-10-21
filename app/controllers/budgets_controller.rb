class BudgetsController < ApplicationController
  before_action :require_approver
  before_action :set_budget, only: %i[edit update]
  before_action :require_future_month, only: %i[edit update]

  def index
    @budgets = Budget.joins(:team)
                     .where(teams: { approver_id: current_user.id })
                     .includes(:team, :category)
                     .order(year_month: :desc, id: :desc)
  end

  def new
    @budget = Budget.new(year_month: MonthBucket.current.next_month)
    load_form_options
  end

  def create
    team = current_user.approving_teams.find_by(id: budget_params[:team_id])
    return head :forbidden unless team

    @budget = team.budgets.new(
      category_id: budget_params[:category_id],
      year_month: parsed_month(budget_params[:year_month]),
      amount: budget_params[:amount]
    )

    if @budget.save
      redirect_to budgets_path, notice: "予算を作成しました"
    else
      load_form_options
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    saved = @budget.with_lock { @budget.update(update_params) }

    if saved
      redirect_to budgets_path, notice: "予算額を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_budget
    @budget = Budget.joins(:team)
                    .where(teams: { approver_id: current_user.id })
                    .find(params[:id])
  end

  def require_future_month
    return if @budget.year_month > MonthBucket.current

    redirect_to budgets_path, alert: "翌月以降の予算のみ変更できます"
  end

  def update_params
    params.require(:budget).permit(:amount)
  end

  def budget_params
    params.require(:budget).permit(:team_id, :category_id, :year_month, :amount)
  end

  def parsed_month(value)
    return unless value.to_s.match?(/\A\d{4}-(?:0[1-9]|1[0-2])\z/)

    Date.strptime(value, "%Y-%m")
  rescue Date::Error
    nil
  end

  def load_form_options
    @teams = current_user.approving_teams.order(:name)
    @categories = Category.order(:name)
  end

  def require_approver
    render plain: "予算の管理は承認者のみ可能です", status: :forbidden unless current_user.approver?
  end
end
