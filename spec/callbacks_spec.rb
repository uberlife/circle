require "spec_helper"

describe Circle, "callbacks" do

	class User < ActiveRecord::Base
		has_circle

		after_friendship_request :after_friendship_request_cb
		after_friendship_accepted :after_friendship_accepted_cb

		attr_accessor :after_friendship_request_value,
			:after_friendship_accepted_value
	
		def after_friendship_request_cb status=nil
			@after_friendship_request_value = status
		end

		def after_friendship_accepted_cb status=nil
			@after_friendship_accepted_value = status
		end
	end

	let(:bill){ Fabricate(:user, login: 'Bill') }
	let(:mike){ Fabricate(:user, login: 'Mike') }
	
	describe "after" do
		it "after_friendship_request" do
			bill.befriend mike
			bill.after_friendship_request_value.last.should ==
				Circle::Friendship::STATUS_REQUESTED
		end
		
		it "after_friendship_accepted" do
			bill.befriend mike
			mike.accept_friend_request bill
			
			mike.after_friendship_accepted_value.last.should ==
				Circle::Friendship::STATUS_FRIENDSHIP_ACCEPTED
		end
	end
end

