class CreateCircleTables < ActiveRecord::Migration
  def self.up
    create_table :friendships, :force => true do |t|
      t.references :user, :friend
      t.datetime :requested_at, :accepted_at, :denied_at, :blocked_at
      t.string :status
      t.timestamps
    end

    create_table :blocked_users, :force => true do |t|
      t.references :user, :blocked_user
      t.timestamps
    end

    change_table :friendships do |t|
      t.index :user_id
      t.index :friend_id
      t.index :status
    end

    change_table :blocked_users do |t|
      t.index :user_id
      t.index :blocked_user_id
    end

    change_table :users do |t|
      t.integer :friends_cout, :default => 0, :null => false
    end
  end

  def self.down
    remove_column :users, :friends_count
    drop_table :friendships
    drop_table :blocked_users
  end
end