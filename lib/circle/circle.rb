require File.join(File.dirname(__FILE__), 'models', 'friendship')
require File.join(File.dirname(__FILE__), 'models', 'blocked_user')


module Circle
  def self.included(receiver)
    receiver.extend ClassMethods
  end

  module ClassMethods
    def has_circle
      include Circle::InstanceMethods

      has_many :friendships, class_name: "Circle::Friendship"
      has_many :friends, -> { where "friendships.status = 'accepted'" }, through: :friendships, source: :friend
      has_many :friendship_requests, -> { where "friendships.status = 'requested'" }, class_name: "Circle::Friendship", foreign_key: :friend_id
      has_many :blocked_user_info, class_name: "Circle::BlockedUser"
      has_many :blocked_users, through: :blocked_user_info, source: :blocked_user
      after_destroy :destroy_all_friendships
    end

		def after_friendship_request method
			ClassMethods.instance_variable_set :@after_friendship_request_callback, method
		end

		def after_friendship_accepted method
			ClassMethods.instance_variable_set :@after_friendship_accepted_callback, method
		end

  end

  module InstanceMethods

    def befriend(friend)
      return nil, Circle::Friendship::STATUS_FRIEND_IS_REQUIRED unless friend
      return nil, Circle::Friendship::STATUS_FRIEND_IS_YOURSELF if self.id == friend.id
      unblock(friend)
      return nil, Circle::Friendship::STATUS_ALREADY_FRIENDS if friends?(friend)
      return nil, Circle::Friendship::STATUS_REQUESTED if am_blocked_by?(friend) # don't let user know he's blocked
      return nil, Circle::Friendship::STATUS_CANNOT_SEND unless can_send_friend_request? rescue nil

      friendship = self.friendship_with(friend)
      request = friend.friendship_with(self)

      return nil, Circle::Friendship::STATUS_ALREADY_REQUESTED if friendship && friendship.requested?

      if friendship && friendship.pending?
        return nil, Circle::Friendship::STATUS_CANNOT_ACCEPT unless can_accept_friend_request? && friend.can_accept_friend_request? rescue nil

        ActiveRecord::Base.transaction do
          friendship.accept!
          request.accept!
        end

        return friendship, Circle::Friendship::STATUS_FRIENDSHIP_ACCEPTED
      end

      if friendship
        friendship.update_attributes({status: 'requested', requested_at: Time.now})
        request.update_attributes({status: 'pending', requested_at: Time.now})
      else
        ActiveRecord::Base.transaction do
          friendship = self.friendships.create(friend_id: friend.id, status: 'requested', requested_at: Time.now)
          request = friend.friendships.create(friend_id: id, status: 'pending', requested_at: Time.now)
        end
      end

      status = friendship, Circle::Friendship::STATUS_REQUESTED
      callback_method = ClassMethods.instance_variable_get :@after_friendship_request_callback
      self.send(callback_method, status) unless callback_method.nil?

			return status
    end

    def friendship_with(friend)
      friendships.where(friend_id: friend.id).first
    end

    def friends?(friend)
      friendship = friendship_with(friend)
      !!(friendship && friendship.accepted?)
    end

    def has_blocked?(friend)
      blocked_user_info.where(blocked_user_id: friend).count > 0
    end
    alias_method :have_blocked?, :has_blocked?

    def am_blocked_by?(friend)
      friend.has_blocked?(self)
    end

    def unfriend(friend)
     ActiveRecord::Base.transaction do
        [friendship_with(friend), friend.friendship_with(self)].compact.each do |friendship|
          friendship.destroy if friendship
        end
      end
    end

    def accept_friend_request(friend)
      return nil, Circle::Friendship::STATUS_CANNOT_ACCEPT unless can_accept_friend_request? rescue nil
      friendship = self.friendship_with(friend)
      if friendship.try(:pending?)
        requested = friend.friendship_with(self)

        ActiveRecord::Base.transaction do
          friendship.accept!
          requested.accept! unless requested.accepted?
        end

        status = friendship, Circle::Friendship::STATUS_FRIENDSHIP_ACCEPTED
        callback_method = ClassMethods.instance_variable_get :@after_friendship_accepted_callback
        self.send(callback_method, status) unless callback_method.nil?

				status
      else
        [nil, Circle::Friendship::STATUS_NOT_FOUND]
      end
    end

    def deny_friend_request(friend)
      request = friendship_with(friend)
      if request.try(:pending?)
        ActiveRecord::Base.transaction do
          [friendship_with(friend), friend.friendship_with(self)].compact.each do |friendship|
            friendship.deny! if friendship
          end
        end
        request.reload
        return request, Circle::Friendship::STATUS_FRIENDSHIP_DENIED
      else
        return nil, Circle::Friendship::STATUS_NOT_FOUND
      end
    end

    def block(friend)
      return nil, Circle::Friendship::STATUS_NOT_FOUND if friend.blank?
      return nil, Circle::Friendship::STATUS_FRIEND_IS_YOURSELF if id == friend.id
      ActiveRecord::Base.transaction do
        blocked_user_info.create(blocked_user_id: friend.id) unless have_blocked?(friend)
      end
      [friendship_with(friend), Circle::Friendship::STATUS_BLOCKED]
    end

    def unblock(friend)
      return nil, Circle::Friendship::STATUS_NOT_FOUND unless have_blocked?(friend)

      ActiveRecord::Base.transaction do
        blocked_user_info.where(blocked_user_id: friend.id).destroy_all
      end

      [nil, Circle::Friendship::STATUS_UNBLOCKED]
    end

    private
      def destroy_all_friendships
        ActiveRecord::Base.transaction do
          Circle::Friendship.destroy_all({user_id: id})
          Circle::Friendship.destroy_all({friend_id: id})
        end
      end
  end
end
