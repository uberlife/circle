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

    describe 'blocked?' do
      it 'should have a blocked status' do
        @friendship = Circle::Friendship.new(:status => 'blocked')
        @friendship.should be_blocked
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

  describe 'block!' do
    it 'should set the status to blocked' do
      @friendship = Circle::Friendship.new(:status => 'pending')
      @friendship.block!
      @friendship.status.should == Circle::Friendship::FRIENDSHIP_BLOCKED
    end

    it 'should create a blocked user when passed true' do
      @bill = Fabricate(:user, login: 'Bill')
      @charles = Fabricate(:user, login: 'charles')

      @bill.befriend(@charles)
      @charles.block(@bill)

      @bill.reload
      @charles.reload

      @bill.blocked_users.should be_empty
      @charles.blocked_users.include?(@bill).should be_true
    end
  end
end