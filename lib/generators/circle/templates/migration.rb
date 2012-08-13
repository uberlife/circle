class CreateCircleTables < ActiveRecord::Migration
  def self.up
    create_table :friendships, :force => true do |t|
      t.references :user, :friend
      t.datetime :requested_at, :accepted_at, :denied_at
      t.string :status
      t.timestamps
    end

    add_index :friendships, :user_id
    add_index :friendships, :friend_id
    add_index :friendships, :status

    add_column :users, :friends_count, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :users, :friends_count
    drop_table :friendships
  end
end