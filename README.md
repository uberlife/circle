# Circle

Friendship management gem for ActiveRecord 3

## Installation

Add this line to your application's Gemfile:

    gem 'circle'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install circle

## Usage

    $ rails g circle:migration

Add "has_circle" to your User model

    class User < ActiveRecord::Base
      has_circle
    end

Call methods as needed

    john = User.find_by_login 'john'
    mary = User.find_by_login 'mary'
    paul = User.find_by_login 'paul'

    # John wants to be friends with Mary
    # always return a friendship object
    john.befriend(mary)

    # Are they friends?
    john.friends?(mary) ==> false

    # Get the friendship object
    john.friendship_with(mary)

    # Mary accepts John's request if it exists
    mary.accept_friend_request(john)
    mary.friends?(john) ==> true

    # If both users request a friendship through befriend, they become friends.
    john.befriend(mary)
    mary.befriend(john)
    mary.friends?(john) ==> true

    # Mary can reject John's friendship.
    mary.deny_friend_request(john)

    # If you're dealing with a friendship object,
    # the following methods are available
    friendship.accept! # accept the request
    friendship.deny! # deny the request
    friendship.block!(true/false) # block request and add to the users block list if passed true. This is so you can have a one sided block (e.g. The user that initiated the block has the user put in their block list and the blocked user doesn't have the initiating user put in theirs)

    # The befriend method returns the friendship object and status.
    # The friendship object will be present only when the friendship is created
    # (that is, when is requested for the first time)
    # STATUS_ALREADY_FRIENDS       # => Users are already friends
    # STATUS_ALREADY_REQUESTED     # => User has already requested friendship
    # STATUS_IS_YOU                # => User is trying add himself as friend
    # STATUS_FRIEND_IS_REQUIRED    # => Friend argument is missing
    # STATUS_FRIENDSHIP_ACCEPTED   # => Friendship has been accepted
    # STATUS_REQUESTED             # => Friendship has been requested
    # STATUS_CANNOT_SEND           # => User cannot send friend requests
    # STATUS_BLOCKED               # => User has been blocked

    friendship, status = mary.befriend(john)

    if status == Circle::Friendship::STATUS_REQUESTED
      # the friendship has been requested
      Mailer.deliver_friendship_request(friendship)
    elsif status == Circle::Friendship::STATUS_ALREADY_FRIENDS
      # they're already friends
    else
      # ...
    end

    # You can specify whether or not a user can send or accept friend requests by defining two methods that return true or false.
    # If these are not defined, it is assumed true.

    class User < ActiveRecord::Base
      has_circle

      def can_send_friend_request?
        # check subscription plan or whatever
      end

      def can_accept_friend_request?
        # check subscription plan or whatever
      end
    end

## Future

1. Add Google+ style circles
2. Customizable User class
3. Customizable friendship table
4. Make ORM agnostic

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
