class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:twitter]

  def self.from_omniauth(auth)
    # providerとuidでUserレコードを取得する
    # 存在しない場合は、ブロック内のコードを実行して作成する
    # where(auth.slice(:provider, :uid)).first_or_create do |user|
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      # auth.provider には "twitter"、
      # auth.uidには twitterアカウントに基づいた個別のIDが入っている
      # first_or_createメソッドが自動でproviderとuidを設定してくれるので、
      # ここでは設定は必要ない
      user.provider = auth.provider 
      user.uid      = auth.uid
      user.username = auth.info.nickname # twitterで利用している名前が入る
      user.email = auth.info.email # twitterの場合入らない
    end
  end


  # Devise の RegistrationsController はリソースを生成する前に self.new_sith_session を呼ぶ
  # つまり、self.new_with_sessionを実装することで、サインアップ前のuserオブジェクトを初期化する
  # ときに session からデータをコピーすることができます。
  # OmniauthCallbacksControllerでsessionに値を設定したので、それをuserオブジェクトにコピーします。
  def self.new_with_session(params, session)
    if session["devise.user_attributes"]
      new(session["devise.user_attributes"], without_protection: true) do |user|
        user.attributes = params
        user.valid?
      end
    else
      super
    end
  end

  # providerがある場合（Twitter経由で認証した）は、
  # passwordは要求しないようにする。
  def password_required?
    super && provider.blank?
  end

  # プロフィールを変更するときによばれる
  def update_with_password(params, *options)
    # パスワードが空の場合
    if encrypted_password.blank?
      # パスワードがなくても更新できる
      update_attributes(params, *options)
    else
      super
    end
  end

  # 認証トークンはユニークに。ただしnilは許可
  validates:authentication_token, uniqueness: true, allow_nil: true

  # 認証トークンが無い場合は作成
  def ensure_authentication_token
    self.authentication_token || generate_authentication_token
  end

  # 認証トークンの作成
  def generate_authentication_token
    loop do
      old_token = self.authentication_token
      token = SecureRandom.urlsafe_base64(24).tr('lIO0', 'sxyz')
      break token if (self.update!(authentication_token: token) rescue false) && old_token != token
    end
  end

  def delete_authentication_token
    self.update(authentication_token: nil)
  end

end
