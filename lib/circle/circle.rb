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
      has_many :friends, through: :friendships, source: :friend, conditions: "friendships.status = 'accepted'"
      has_many :friendship_requests, class_name: "Circle::Friendship", foreign_key: :friend_id, conditions: "friendships.status = 'requested'"
      has_many :users_blocked, class_name: "Circle::BlockedUser"
      has_many :blocked_users, through: :users_blocked, source: :blocked_user
      after_destroy :destroy_all_friendships
    end
  end

  module InstanceMethods

    def befriend(friend)
      return nil, Circle::Friendship::STATUS_FRIEND_IS_REQUIRED unless friend
      return nil, Circle::Friendship::STATUS_FRIEND_IS_YOURSELF if self.id == friend.id
      return nil, Circle::Friendship::STATUS_ALREADY_FRIENDS if friends?(friend)
      return nil, Circle::Friendship::STATUS_BLOCKED if friend.blocked?(self) || blocked?(friend)
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

      if friendship && (friendship.denied? || friendship.blocked?)
        friendship.update_attributes({status: 'requested', requested_at: Time.now})
        request.update_attributes({status: 'pending', requested_at: Time.now})
      else
        ActiveRecord::Base.transaction do
          friendship = self.friendships.create(friend_id: friend.id, status: 'requested', requested_at: Time.now)
          request = friend.friendships.create(friend_id: id, status: 'pending', requested_at: Time.now)
        end
      end

      return friendship, Circle::Friendship::STATUS_REQUESTED
    end

    def friendship_with(friend)
      friendships.where(friend_id: friend.id).first
    end

    def friends?(friend)
      friendship = friendship_with(friend)
      !!(friendship && friendship.accepted?)
    end

    def blocked?(friend)
      !!users_blocked.where(blocked_user_id: friend).first
    end

    def unfriend(friend)
     ActiveRecord::Base.transaction do
        [friendship_with(friend), friend.friendship_with(self)].compact.each do |friendship|
          friendship.destroy if friendship
        end
      end
    end

    def accept_request(friend)
      return nil, Circle::Friendship::STATUS_CANNOT_ACCEPT unless can_accept_friend_request? rescue nil
      friendship = self.friendship_with(friend)
      if friendship.try(:pending?)
        requested = friend.friendship_with(self)

        ActiveRecord::Base.transaction do
          friendship.accept!
          requested.accept! unless requested.accepted?
        end

        return friendship, Circle::Friendship::STATUS_FRIENDSHIP_ACCEPTED
      else
        return nil, Circle::Friendship::STATUS_NOT_FOUND
      end
    end

    def deny_request(friend)
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
      request = friendship_with(friend)
      if request
        ActiveRecord::Base.transaction do
            request.block!(true)
            friend.friendship_with(self).try(:block!)
        end
        request.reload
        return request, Circle::Friendship::STATUS_BLOCKED
      else
        return nil, Circle::Friendship::STATUS_NOT_FOUND
      end
    end

    def unblock(friend)
      blocked_user = self.users_blocked.where(blocked_user_id: friend.id).first

      if blocked_user
        ActiveRecord::Base.transaction do
          blocked_user.destroy
        end
        return nil, Circle::Friendship::STATUS_UNBLOCKED
      else
        return nil, Circle::Friendship::STATUS_NOT_FOUND
      end
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