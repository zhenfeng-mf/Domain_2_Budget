require "test_helper"

class SessionsTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.load_seed
  end

  test "seeded member logs in and out" do
    get root_path
    assert_redirected_to login_path

    get login_path
    assert_response :success
    assert_select "form[action='#{login_path}']"

    post login_path, params: { email: " MEMBER@EXAMPLE.COM ", password: "demo-password-123" }
    assert_redirected_to root_path
    assert_equal User.find_by!(email: "member@example.com").id, session[:user_id]

    get root_path
    assert_response :success
    assert_select "form[action='#{logout_path}']"

    delete logout_path
    assert_redirected_to login_path
    assert_nil session[:user_id]

    get root_path
    assert_redirected_to login_path
  end

  test "seeded approver can log in" do
    post login_path, params: { email: "approver@example.com", password: "demo-password-123" }

    assert_redirected_to root_path
    assert_equal User.find_by!(email: "approver@example.com").id, session[:user_id]
  end

  test "wrong password leaves the user signed out" do
    post login_path, params: { email: "member@example.com", password: "wrong-password" }

    assert_response :unprocessable_entity
    assert_nil session[:user_id]
    assert_select "[role='alert']", text: /正しくありません/
  end
end
