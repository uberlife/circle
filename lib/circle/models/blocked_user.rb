class Circle::BlockedUser < ActiveRecord::Base
  self.table_name = "blocked_users"

  belongs_to :user
  belongs_to :blocked_user, class_name: 'User', foreign_key: 'blocked_user_id'

  attr_accessible :blocked_user_id if defined? Rails and (Rails.version < "4" or defined?(::ProtectedAttributes))
end
