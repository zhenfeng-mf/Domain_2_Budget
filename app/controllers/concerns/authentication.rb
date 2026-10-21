module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :current_user, :authenticated?
  end

  private

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = User.find_by(id: session[:user_id]) if session[:user_id].present?
  end

  def authenticated?
    current_user.present?
  end

  def require_authentication
    redirect_to login_path, alert: "ログインしてください" unless authenticated?
  end
end
