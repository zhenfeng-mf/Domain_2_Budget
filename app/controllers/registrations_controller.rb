class RegistrationsController < ApplicationController
  skip_before_action :require_authentication, only: %i[new create]
  before_action :redirect_if_authenticated

  def new
    @user = User.new
    @teams = Team.order(:name)
  end

  def create
    @user = User.new(signup_params.merge(role: :member))

    if @user.save
      reset_session
      session[:user_id] = @user.id
      redirect_to root_path, notice: "アカウントを作成しました"
    else
      @teams = Team.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def signup_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :team_id)
  end

  def redirect_if_authenticated
    redirect_to root_path if authenticated?
  end
end
