class LongTermGoalsController < ApplicationController
  #before_action :set_long_term_goal, only: [:show, :edit, :update, :destroy]
  before_action :logged_in_user 
  before_action :correct_user_for_l_goal, only: [:edit, :update]
  
  
  def new
    @user = User.find(params[:user_id])
    @long_term_goal = @user.long_term_goals.build
  end

  def create
    @user = current_user 
    @long_term_goal = @user.long_term_goals.build(long_term_goal_params)
    if @long_term_goal.save 
      flash[:success] = "長期目標を作成しました"
      redirect_to user_long_term_goals_path
    else 
      render 'new'
    end 
  end
  
  def index 
    @user = User.find(params[:user_id])
    @long_term_goals = @user.long_term_goals.rank(:row_order)
  end 

  def show
  end

  def edit
  end

  def update
  end

  def destroy
  end
  
  def sort 
    long_term_goal = LongTermGoal.find(params[:long_term_goal_id])
    long_term_goal.update(long_term_goal_params)
    render body: nil
  end 
  
  
  private 
  
    # def set_long_term_goal
    #   @long_term_goal = LongTermGoal.find(params[:id])
    # end 
  
    def long_term_goal_params
      params.require(:long_term_goal).permit(:category, :content, :row_order_position)
    end 
    
    
    # beforeアクション
    
    # 正しいユーザーかどうか確認
    def correct_user_for_l_goal 
      @user = User.find(params[:user_id])
      redirect_to(root_url) unless current_user?(@user)
    end 
end
