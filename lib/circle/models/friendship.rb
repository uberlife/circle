class Circle::Friendship < ActiveRecord::Base
  self.table_name = "friendships"

  STATUS_ALREADY_FRIENDS     = 1
  STATUS_ALREADY_REQUESTED   = 2
  STATUS_FRIEND_IS_YOURSELF  = 3
  STATUS_FRIENDSHIP_ACCEPTED = 4
  STATUS_FRIENDSHIP_DENIED   = 5
  STATUS_REQUESTED           = 6
  STATUS_CANNOT_SEND         = 7
  STATUS_CANNOT_ACCEPT       = 8
  STATUS_NOT_FOUND           = 9
  STATUS_BLOCKED             = 10
  STATUS_UNBLOCKED           = 11

  FRIENDSHIP_ACCEPTED = "accepted"
  FRIENDSHIP_PENDING = "pending"
  FRIENDSHIP_REQUESTED = "requested"
  FRIENDSHIP_DENIED = "denied"
  FRIENDSHIP_BLOCKED = "blocked"

  attr_accessible :friend_id, :status, :requested_at, :accepted_at, :denied_at if defined? Rails and (Rails.version < "4" or defined?(::ProtectedAttributes))

  scope :pending, -> { where(status: FRIENDSHIP_PENDING) }
  scope :accepted, -> { where(status: FRIENDSHIP_ACCEPTED) }
  scope :requested, -> { where(status: FRIENDSHIP_REQUESTED) }
  scope :denied, -> { where(status: FRIENDSHIP_DENIED) }

  belongs_to :user
  belongs_to :friend, class_name: 'User', foreign_key: 'friend_id'

  after_destroy do |f|
    User.decrement_counter(:friends_count, f.user_id) if f.status == FRIENDSHIP_ACCEPTED
  end


  def pending?
    status == FRIENDSHIP_PENDING
  end

  def accepted?
    status == FRIENDSHIP_ACCEPTED
  end

  def requested?
    status == FRIENDSHIP_REQUESTED
  end

  def denied?
    status == FRIENDSHIP_DENIED
  end

  def blocked_at
    user.blocked_user_info.where(blocked_user_id: friend.id).first.try(:created_at)
  end

  def blocked?
    user.has_blocked?(friend)
  end

  def accept!
    unless accepted?
      self.transaction do
        User.increment_counter(:friends_count, user_id)
        update_attribute(:status, FRIENDSHIP_ACCEPTED)
        update_attribute(:accepted_at, Time.now)
      end
    end
  end

  def deny!
    self.transaction do
      update_attribute(:status, Circle::Friendship::FRIENDSHIP_DENIED)
      update_attribute(:denied_at, Time.now)
    end
  end
end

class Array
  def circle_statuses
    @circle_statuses ||= Circle::Friendship::constants.select do |i|
      i.to_s =~ /STATUS/
    end.map {|s| s.downcase.to_s.gsub /status_/,"" }
  end

  def method_missing method_name, *args, &block
    begin
      if circle_statuses.include?(method_name.to_s.downcase.match(/(\w+)\?/)[1])
        const_name = "status_#{Regexp.last_match[1]}".upcase
        const_value = Circle::Friendship.const_get const_name
        return self.last == const_value
      end
    rescue Exception => e
      # handle this. in some strange cases it brakes.

      super method_name, *args, &block
    end

    super method_name, *args, &block
  end
end
