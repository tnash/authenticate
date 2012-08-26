require 'devise'
require 'friendly_id'

class User < ActiveRecord::Base
  extend FriendlyId

  rolify
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable  :trackable :recoverable, :rememberable, :validatable,
  if self.respond_to?(:devise)
    devise :database_authenticatable, :registerable,
           :authentication_keys => [:login]
  end

  # Setup accessible (or protected) attributes for your model
  # :login is a virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'username'
  attr_accessor :login
  attr_accessible :name, :email, :password, :password_salt, :password_confirmation, :remember_me, :username, :login

  validates :username, :presence => true, :uniqueness => true
  before_validation :downcase_username
  friendly_id :username, :use => [:slugged]

  class << self

    def self.find_first_by_auth_conditions(warden_conditions)
      conditions = warden_conditions.dup
      if login == conditions.delete(:login)
        where(conditions).where(["lower(username) = :value OR lower(email) = :value", {:value => login.downcase}]).first
      else
        where(conditions).first
      end
    end

    # Find user by email or username.
    # https://github.com/plataformatec/devise/wiki/How-To:-Allow-users-to-sign_in-using-their-username-or-email-address
    def find_for_database_authentication(conditions)
      puts "#{__FILE__}:#{__LINE__}: conditions=#{conditions.inspect}"
      value = conditions[authentication_keys.first]
      where(["username = :value OR email = :value", {:value => value}]).first
    end
  end

  def can_delete?(user_to_delete = self)
    user_to_delete.persisted? &&
        !user_to_delete.has_role?(:superuser) &&
        ::Role[:admin].users.any? &&
        id != user_to_delete.id
  end

  def can_edit?(user_to_edit = self)
    user_to_edit.persisted? && (
    user_to_edit == self ||
        self.has_role?(:superuser)
    )
  end

  def add_role(title)
    puts "#{__FILE__}:#{__LINE__}: title=#{title.inspect}"
    #raise ArgumentException, "Role should be the title of the role not a role object." if title.is_a?(:Role)
    roles << ::Role[title] unless has_role?(title)
  end

  def has_role?(title)
    raise ArgumentException, "Role should be the title of the role not a role object." if title.is_a?(::Role)
    roles.any? { |r| r.title == title.to_s.camelize }
  end

  def create_first
    if valid?
      # first we need to save user
      save
      # add refinery role
      add_role(:admin)
      # add superuser role if there are no other users
      add_role(:superuser) if ::Role[:admin].users.count == 1
    end

    # return true/false based on validations
    valid?
  end

  def to_s
    username.to_s
  end

  private
  # To ensure uniqueness without case sensitivity we first downcase the username.
  # We do this here and not in SQL is that it will otherwise bypass indexes using LOWER:
  # SELECT 1 FROM "refinery_users" WHERE LOWER("refinery_users"."username") = LOWER('UsErNAME') LIMIT 1
  def downcase_username
    self.username = self.username.downcase if self.username?
  end

end
