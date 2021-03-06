class User < ApplicationRecord
  has_many :from_messages, class_name: "Message", foreign_key: "from_id", dependent: :destroy
  has_many :to_messages, class_name: "Message", foreign_key: "to_id", dependent: :destroy
  has_many :sent_messages, through: :from_messages, source: :from
  has_many :received_messages, through: :to_messages, source: :to
  has_many :long_term_goals, dependent: :destroy
  has_many :mid_term_goals, dependent: :destroy
  has_many :short_term_goals, dependent: :destroy
  has_many :approaches, dependent: :destroy
  has_many :xrooms, dependent: :destroy
  has_many :active_relationships, class_name:  "Relationship",
                                  foreign_key: "follower_id",
                                  dependent:   :destroy
  has_many :passive_relationships, class_name:  "Relationship",
                                   foreign_key: "followed_id",
                                   dependent:   :destroy
  has_many :following, through: :active_relationships, source: :followed
  has_many :followers, through: :passive_relationships, source: :follower
  has_many :active_block_relationships, class_name: "BlockRelationship", foreign_key: "blocker_id", dependent: :destroy
  has_many :passive_block_relationships, class_name: "BlockRelationship", foreign_key: "blocked_id", dependent: :destroy
  has_many :blocking, through: :active_block_relationships, source: :blocked
  has_many :blockers, through: :passive_block_relationships, source: :blocker
  has_many :from_notices, class_name: "Notice",
            foreign_key: "from_id", dependent: :destroy
  has_many :to_notices, class_name: "Notice",
          foreign_key: "to_id", dependent: :destroy
  has_many :sent_notices, through: :from_notices, source: :from
  has_many :received_notices, through: :to_notices, source: :to
  attr_accessor :remember_token, :activation_token, :reset_token
  before_save :downcase_email
  before_create :create_activation_digest
  validates :name, presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
      format: { with: VALID_EMAIL_REGEX },
      uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
  
  
  class << self
    # 渡された文字列のハッシュ値を返す
    def digest(string)
      cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
      BCrypt::Password.create(string, cost: cost)
    end 
    
    # ランダムなトークンを返す
    def new_token 
      SecureRandom.urlsafe_base64
    end 
  end 
    
  # 永続セッションのためにユーザーをデータベースに記憶する
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end 
  
  # 渡されたトークンがダイジェストと一致したらtrueを返す
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end 
  
  # ユーザーのログイン情報を破棄する
  def forget 
    update_attribute(:remember_digest, nil)
  end 
  
  # アカウントを有効化する
  def activate
    update_attribute(:activated, true)
    update_attribute(:activated_at, Time.zone.now)
  end
  
  # 有効化用のメールを送信する
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end
  
  # パスワード再設定の属性を設定する
  def create_reset_digest
    self.reset_token = User.new_token
    update_attribute(:reset_digest,  User.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end

  # パスワード再設定のメールを送信する
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end
  
  # パスワード再設定の期限が切れている場合はtrueを返す
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end
  
    # ユーザーをフォローする
  def follow(other_user)
    following << other_user
    notice = Notice.new(from_id: self.id, to_id: other_user.id, 
              content: "#{self.name}さんがあなた（#{other_user.name}）をフォローしました", link_to: "/users/#{self.id}/long_term_goals")
    notice.save
  end

  # ユーザーをフォロー解除する
  def unfollow(other_user)
    active_relationships.find_by(followed_id: other_user.id).destroy
  end

  # 現在のユーザーがフォローしてたらtrueを返す
  def following?(other_user)
    following.include?(other_user)
  end
  
  # 検索機能のためのメソッド
  def self.search(search: nil, order: nil)
    if search.present?
      tmp = User.where(['name LIKE ?', "%#{search}%"])
    else
      tmp = User.all
    end
    tmp = tmp.sort { |a, b| b.followers.count <=> a.followers.count } if order.present?
    return tmp
  end
  
  # フォロワーランキングのためのメソッド
  def self.u_rank
    User.find(Relationship.group(:followed_id).order('count(followed_id) desc').limit(10).pluck(:followed_id))
  end 
  
  # あなたが最近更新した長期目標リストを返す
  def your_updated_l_goals
    self.long_term_goals.order('updated_at DESC').limit(20)
  end 
  
  # あなたが最近更新した中期目標リストを返す
  def your_updated_m_goals 
    self.mid_term_goals.order('updated_at DESC').limit(20)
  end 

  # あなたが最近更新した短期目標リストを返す
  def your_updated_s_goals 
    self.short_term_goals.order('updated_at DESC').limit(20)
  end 
  
  # あなたが最近更新したアプローチリストを返す
  def your_updated_approaches 
    self.approaches.order('updated_at DESC').limit(20)
  end 
  
  # あなたが最近作成したX Roomリストを返す
  def your_xrooms 
    self.xrooms.order('created_at DESC').limit(10)
  end 
  
  # あなたの実行中の長期目標リストを返す
  def your_ongoing_l_goals
    self.long_term_goals.where(status: '実行中').order('updated_at DESC').limit(10)
  end 
  
  # あなたの実行中の中期目標リストを返す
  def your_ongoing_m_goals
    self.mid_term_goals.where(status: '実行中').order('updated_at DESC').limit(10)
  end 
  
  # あなたの実行中の短期目標リストを返す
  def your_ongoing_s_goals
    self.short_term_goals.where(status: '実行中').order('updated_at DESC').limit(10)
  end 
  
  # あなたの実行中のアプローチリストを返す
  def your_ongoing_approaches
    self.approaches.where(status: '実行中').order('updated_at DESC').limit(10)
  end 
  
  # あなたが最近達成した長期目標リストを返す
  def your_achieved_l_goals
    self.long_term_goals.where(status: '達成済み').order('updated_at DESC').limit(10)
  end 
  
  # あなたが最近達成した中期目標リストを返す
  def your_achieved_m_goals
    self.mid_term_goals.where(status: '達成済み').order('updated_at DESC').limit(10)
  end 
  
  # あなたが最近達成した短期目標リストを返す
  def your_achieved_s_goals
    self.short_term_goals.where(status: '達成済み').order('updated_at DESC').limit(10)
  end 
  
  # あなたが最近達成したアプローチリストを返す
  def your_achieved_approaches
    self.approaches.where(status: '達成済み').order('updated_at DESC').limit(10)
  end 
  
  # あなたが最近フォローしたユーザーリストを返す
  def self.your_resent_followings(user_id)
    User.find(Relationship.where(follower_id: user_id).order('created_at DESC').limit(10).pluck(:followed_id))
  end
  
  # フォロワーが最近フォローしたユーザーリストを返す
  def self.followers_resent_followings(current_user_id)
    following_ids = Relationship.where(follower_id: current_user_id).pluck(:followed_id)
    User.find(Relationship.where(follower_id: following_ids).order('created_at desc').limit(20).pluck(:followed_id))
  end 
  
  # 他のユーザーにメールを送信する
  def send_message(other_user, room_id, content)
    from_messages.create!(to_id: other_user.id, room_id: room_id, content: content)
  end
  
  # ユーザーをブロックする
  def block(other_user)
    blocking << other_user
  end

  # ユーザーをブロックを解除する
  def unblock(other_user)
    active_block_relationships.find_by(blocked_id: other_user.id).destroy
  end

  # 現在のユーザーがブロックしてたらtrueを返す
  def blocking?(other_user)
    blocking.include?(other_user)
  end
  
  #通知を送る
  def send_notice(other_user, content)
    from_notices.create!(to_id: other_user.id, content: content)
  end
  
  private
    
    # メールアドレスを小文字にする
    def downcase_email
      self.email = email.downcase
    end
    
    # 有効化トークンとダイジェストを作成及び代入する
    def create_activation_digest
      self.activation_token = User.new_token
      self.activation_digest = User.digest(activation_token)
    end
end
