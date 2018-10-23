class User < ApplicationRecord
  has_many :from_messages, class_name: "Message", foreign_key: "from_id", dependent: :destroy
  has_many :to_messages, class_name: "Message", foreign_key: "to_id", dependent: :destroy
  has_many :sent_messages, through: :from_messages, source: :from
  has_many :received_messages, through: :to_messages, source: :to
  has_many :long_term_goals, dependent: :destroy
  has_many  :xrooms, dependent: :destroy
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
  def self.search(search)
    if search
      User.where(['name LIKE ?', "%#{search}%"])
    else
      User.all
    end
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
