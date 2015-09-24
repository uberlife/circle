require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'Circle' do

  describe 'methods' do
    it {User.should respond_to(:has_circle)}
    it {Fabricate(:user).should respond_to(:befriend)}
    it {Fabricate(:user).should respond_to(:friends?)}
    it {Fabricate(:user).should respond_to(:accept_friend_request)}
    it {Fabricate(:user).should respond_to(:deny_friend_request)}
    it {Fabricate(:user).should respond_to(:unfriend)}
    it {Fabricate(:user).should respond_to(:block)}
    it {Fabricate(:user).should respond_to(:unblock)}
  end

  describe "user" do
    before(:each) do
      @bill = Fabricate(:user, login: 'Bill')
      @charles = Fabricate(:user, login: 'charles')
    end

    describe "using befriend" do

      it 'should not allow sending of requests if the user cannot send' do
        @bill.stub(:can_send_friend_request?) {false}
        friendship, status = stat = @bill.befriend(@charles)
        stat.should be_cannot_send
        friendship.should be_nil
        status.should == Circle::Friendship::STATUS_CANNOT_SEND
      end

      it 'should not fail if can_send_friend_request? is undefined' do
        @bill.befriend(@charles).should be_requested
      end

      it 'should create a friendship when each user befriends one another' do
        @bill.befriend(@charles)
        @charles.befriend(@bill)
        @bill.reload
        @charles.reload

        @bill.friends_count.should == 1
        @charles.friends_count.should == 1
      end

      it 'should not create a friendship if either user cannot accept requests' do
        @bill.befriend(@charles)
        @charles.stub(:can_accept_friend_request?) {false}
        friendship, status = @charles.befriend(@bill)
        friendship.should be_nil
        status.should == Circle::Friendship::STATUS_CANNOT_ACCEPT
      end

      it 'should return an error status if you try to friend yourself' do
        friendship, status = @bill.befriend(@bill)
        friendship.should be_nil
        status.should == Circle::Friendship::STATUS_FRIEND_IS_YOURSELF
      end

      it 'should return an error status when the passed in user is already a friend' do
        @bill.befriend(@charles)
        @charles.befriend(@bill)

        friendship, status = @bill.befriend(@charles)
        friendship.should be_nil
        status.should == Circle::Friendship::STATUS_ALREADY_FRIENDS

        [friendship, status].should be_already_friends
      end

      it 'should return an error status when the request has already been made' do |variable|
        @bill.befriend(@charles)

        friendship, status = @bill.befriend(@charles)
        friendship.should be_nil
        status.should == Circle::Friendship::STATUS_ALREADY_REQUESTED

        [friendship,status].should be_already_requested
      end

      it 'should re-request a friendship if the user is not blocked' do
        friendship, status = stat = @bill.befriend(@charles)
        friendship.should_not be_nil
        status.should == Circle::Friendship::STATUS_REQUESTED
        stat.should be_requested

        friendship, status = stat = @charles.deny_friend_request(@bill)
        friendship.should_not be_nil
        status.should == Circle::Friendship::STATUS_FRIENDSHIP_DENIED
        stat.should be_friendship_denied

        friendship, status = stat = @bill.befriend(@charles)
        friendship.should_not be_nil
        status.should == Circle::Friendship::STATUS_REQUESTED
        stat.should be_requested
      end

    end

    describe "accepting a request" do

      it 'should create a friendship when the user accepts a request' do
        @bill.befriend(@charles)
        @charles.accept_friend_request(@bill)
        @bill.reload
        @charles.reload

        @bill.friends_count.should == 1
        @charles.friends_count.should == 1
      end

      it 'should not create a friendship when the user attempts to accept if the user cannot accept' do
        @bill.befriend(@charles)
        @charles.stub(:can_accept_friend_request?) {false}
        friendship, status = stat = @charles.accept_friend_request(@bill)
        friendship.should be_nil
        status.should == Circle::Friendship::STATUS_CANNOT_ACCEPT
        stat.should be_cannot_accept
      end

      it 'should return a not found status if the request does not exist' do
        friendship, status = stat = @bill.accept_friend_request(@charles)
        friendship.should be_nil
        status.should == Circle::Friendship::STATUS_NOT_FOUND
        stat.should be_not_found
      end
    end

    describe "denying a request" do
      it 'should return the friendship object and a denied status' do
        @bill.befriend(@charles)
        friendship, status = stat = @charles.deny_friend_request(@bill)
        friendship.should_not be_nil
        status.should == Circle::Friendship::STATUS_FRIENDSHIP_DENIED
        stat.should be_friendship_denied
      end

      it 'should update the friendship object with a denied status' do
        @bill.befriend(@charles)
        friendship, status = @charles.deny_friend_request(@bill)
        friendship.should_not be_nil
        friendship.status.should == Circle::Friendship::FRIENDSHIP_DENIED
      end

      it 'should return a not found status if the request does not exist' do
        friendship, status = stat = @bill.deny_friend_request(@charles)
        friendship.should be_nil
        status.should == Circle::Friendship::STATUS_NOT_FOUND
        stat.should be_not_found
      end
    end

    describe 'unfriending' do
      it 'should remove the friendship if the user unfriends another user' do
        @bill.befriend(@charles)
        @charles.befriend(@bill)

        @bill.friends.include?(@charles).should be_truthy
        @charles.friends.include?(@bill).should be_truthy

        @bill.unfriend(@charles)

        @bill.friends.include?(@charles).should be_falsey
        @charles.friends.include?(@bill).should be_falsey
      end

      it 'should decrement the friends counter' do
        @bill.befriend(@charles)
        @charles.befriend(@bill)

        @bill.reload
        @charles.reload

        @bill.friends_count.should == 1
        @charles.friends_count.should == 1

        @bill.unfriend(@charles)

        @bill.reload
        @charles.reload

        @bill.friends_count.should == 0
        @charles.friends_count.should == 0

      end
    end

    describe 'destroying all friendships' do
      it "should remove all friendships for a user" do
        @bill.befriend(@charles)
        @charles.befriend(@bill)

        @bill.reload
        @charles.reload

        @bill.friends_count.should == 1
        @charles.friends_count.should == 1

        @bill.send(:destroy_all_friendships)

        @bill.reload
        @charles.reload

        @bill.friends_count.should == 0
        @charles.friends_count.should == 0
      end
    end

    describe "friends" do
      it 'should return the friends of a user' do
        @bill.befriend(@charles)
        @charles.befriend(@bill)

        @user = Fabricate(:user)

        @bill.befriend(@user)
        @user.befriend(@bill)

        @bill.friends.should == [@charles, @user]
        @charles.friends.should == [@bill]
        @user.friends.should == [@bill]
      end
    end

    describe 'blocking' do
      before(:each) do
        @charles.block(@bill)
      end

      it 'should block a user' do
        @bill.blocked_users.should be_empty
        @charles.blocked_users.should include @bill
      end

      it 'should allow friend requests to be sent, but they should not really be created' do
        friendship, status = @bill.befriend(@charles)
        friendship.should be_nil
        status.should == Circle::Friendship::STATUS_REQUESTED
        @bill.friendship_with(@charles).should be_nil
      end

      it 'should allow a user to request a friendship with a user they have previously blocked' do
        @charles.unblock(@bill)
        friendship, status = @charles.befriend(@bill)
        friendship.should_not be_nil
        status.should == Circle::Friendship::STATUS_REQUESTED
        @charles.friendship_with(@bill).should be_present
      end

      it 'should unblock user if a friendship request is sent from the user who has him blocked' do
        friendship, status = @charles.befriend(@bill)
        @charles.blocked_users.should be_empty
        status.should == Circle::Friendship::STATUS_REQUESTED
        @charles.friendship_with(@bill).should be_present
      end
    end

    describe 'unblocking' do
      before(:each) do
        @bill.befriend(@charles)
        @charles.block(@bill)
      end

      it 'should remove the blocked user' do
        @charles.unblock(@bill)
        @charles.reload
        @charles.blocked_users.should be_empty
      end
    end
  end
end
