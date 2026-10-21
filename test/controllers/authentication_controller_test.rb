require "test_helper"

class AuthenticationProbeController < ApplicationController
  def index
    render plain: "#{current_user.email}|#{authenticated?}"
  end
end

class AuthenticationTest < ActionController::TestCase
  tests AuthenticationProbeController

  with_routing do |routes|
    routes.draw { get "probe" => "authentication_probe#index" }
  end

  test "anonymous request redirects to login" do
    get :index

    assert_redirected_to "/login"
  end

  test "session user is recognized on a private action" do
    get :index, session: { user_id: users(:taro).id }

    assert_response :success
    assert_equal "taro@example.com|true", response.body
  end

  test "session for a deleted user redirects to login" do
    get :index, session: { user_id: 999_999_999 }

    assert_redirected_to "/login"
  end
end
