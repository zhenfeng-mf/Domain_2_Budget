require "test_helper"

class RegistrationsTest < ActionDispatch::IntegrationTest
  test "member signs up in an existing team then logs out and back in" do
    get signup_path
    assert_response :success
    assert_select "select[name='user[team_id]'] option", text: teams(:alpha).name

    assert_difference "User.count", 1 do
      post signup_path, params: { user: {
        name: "New Member", email: "new.member@example.com", team_id: teams(:alpha).id,
        password: "secure-password-123", password_confirmation: "secure-password-123",
        role: "approver"
      } }
    end

    user = User.find_by!(email: "new.member@example.com")
    assert user.member?
    assert_equal teams(:alpha), user.team
    assert_equal user.id, session[:user_id]
    assert_redirected_to root_path

    delete logout_path
    assert_nil session[:user_id]

    post login_path, params: { email: user.email, password: "secure-password-123" }
    assert_equal user.id, session[:user_id]
    assert_redirected_to root_path
  end

  test "signup cannot grant approver privileges" do
    assert_difference "User.count", 1 do
      post signup_path, params: { user: {
        name: "Role Tampering",
        email: "role.tampering@example.com",
        team_id: teams(:alpha).id,
        password: "password",
        password_confirmation: "password",
        role: "approver"
      } }
    end
  
    user = User.find_by!(email: "role.tampering@example.com")
  
    assert user.member?,
           "Signup must create a member even when approver is requested"
  end

  test "invalid registration shows errors and creates no user" do
    assert_no_difference "User.count" do
      post signup_path, params: { user: {
        name: "", email: users(:taro).email, team_id: teams(:alpha).id,
        password: "secure-password-123", password_confirmation: "different"
      } }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert'] li", minimum: 1
    assert_select "input[name='user[email]'][value='#{users(:taro).email}']"
  end

  test "unknown team cannot be used to register" do
    assert_no_difference "User.count" do
      post signup_path, params: { user: {
        name: "New Member", email: "new.member@example.com", team_id: 999_999_999,
        password: "secure-password-123", password_confirmation: "secure-password-123"
      } }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert'] li", minimum: 1
  end

  test "signed-in user cannot create another account" do
    post login_path, params: { email: users(:taro).email, password: "password" }

    assert_no_difference "User.count" do
      post signup_path, params: { user: {
        name: "Other", email: "other@example.com", team_id: teams(:alpha).id,
        password: "secure-password-123", password_confirmation: "secure-password-123"
      } }
    end

    assert_redirected_to root_path
  end
end
