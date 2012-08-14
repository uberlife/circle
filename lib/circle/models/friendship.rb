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

  FRIENDSHIP_ACCEPTED = "accepted"
  FRIENDSHIP_PENDING = "pending"
  FRIENDSHIP_REQUESTED = "requested"
  FRIENDSHIP_DENIED = "denied"

  attr_accessible :friend_id, :status, :requested_at, :accepted_at, :denied_at

  scope :pending, conditions: {status: FRIENDSHIP_PENDING}
  scope :accepted, conditions: {status: FRIENDSHIP_ACCEPTED}
  scope :requested, conditions: {status: FRIENDSHIP_REQUESTED}
  scope :denied, conditions: {status: FRIENDSHIP_DENIED}

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