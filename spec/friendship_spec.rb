require File.join(File.dirname(__FILE__), 'spec_helper')

describe Circle::Friendship do
  describe 'associations' do
    it {should belong_to :user}
    it {should belong_to :friend}
  end

  describe 'status' do

    describe 'pending?' do
      it 'should have a pending status' do
        @friendship = Circle::Friendship.new(:status => 'pending')
        @friendship.should be_pending
      end
    end

    describe 'accepted?' do
      it 'should have an accepted status' do
        @friendship = Circle::Friendship.new(:status => 'accepted')
        @friendship.should be_accepted
      end
    end

    describe 'requested?' do
      it 'should have a requested status' do
        @friendship = Circle::Friendship.new(:status => 'requested')
        @friendship.should be_requested
      end
    end

    describe 'denied?' do
      it 'should have a denied status' do
        @friendship = Circle::Friendship.new(:status => 'denied')
        @friendship.should be_denied
      end
    end

  end

  describe 'accept!' do
    it 'should set the status to accepted' do
      @friendship = Circle::Friendship.new(:status => 'pending')
      @friendship.accept!
      @friendship.status.should == Circle::Friendship::FRIENDSHIP_ACCEPTED
    end

    it 'should increment the user friends counter' do
      @user = Fabricate(:user)
      @user2 = Fabricate(:user)
      @user.befriend(@user2)
      @user2.befriend(@user)

      @user.reload

      @user.friends_count.should == 1
    end
  end

  describe 'deny!' do
    it 'should set the status to denied' do
      @friendship = Circle::Friendship.new(:status => 'pending')
      @friendship.deny!
      @friendship.status.should == Circle::Friendship::FRIENDSHIP_DENIED
    end
  end

  describe 'block' do
    let(:friend) { mock('Friend', id: 1337, to_param: 1337) }
    let(:friendship) { Circle::Friendship.new.tap { |fs| fs.stub(:friend).and_return(friend) } }

    it 'should get blocked_at from the user\'s blocked users association' do
      mock_user = mock('User')
      mock_blocked_users = mock('BlockedUsers')
      mock_created_at = mock('DateTime')
      mock_result = mock('BlockedUser', created_at: mock_created_at)
      mock_results = [mock_result]

      friendship.should_receive(:user).and_return(mock_user)
      mock_user.should_receive(:blocked_user_info).and_return(mock_blocked_users)
      mock_blocked_users.should_receive(:where).with(blocked_user_id: friend.id).and_return(mock_results)

      friendship.blocked_at.should eq(mock_created_at)
    end

    it 'should get blocked? from user' do
      mock_blocked = mock('Boolean')
      mock_user = mock('User')

      mock_user.should_receive(:has_blocked?).with(friend).and_return(mock_blocked)
      friendship.should_receive(:user).and_return(mock_user)

      friendship.blocked?.should eq(mock_blocked)
    end
  end
end
