require 'test_helper'

class LongTermGoalsControllerTest < ActionDispatch::IntegrationTest
  def setup 
    @user = users(:michael)
    @other_user = users(:archer)
    @long_term_goal = @user.long_term_goals.build
  end 
  
  test "should get new" do
    log_in_as(@user)
    get new_user_long_term_goal_path(user_id: @user.id)
    assert_response :success
  end

  # test "should get show" do
  #   log_in_as(@user)
  #   get user_long_term_goal_path(@long_term_goal)
  #   assert_response :success
  # end

  # test "should get edit" do
  #   log_in_as(@user)
  #   get edit_user_long_term_goal_path(@long_term_goal)
  #   assert_response :success
  # end
end
