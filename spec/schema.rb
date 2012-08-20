ActiveRecord::Schema.define(:version => 0) do
  begin
    drop_table :users
    drop_table :friendships
  rescue
  end

  create_table :users do |t|
    t.string :login
    t.integer :friends_count, :default => 0, :null => false
  end

  create_table :friendships do |t|
    t.references :user, :friend
    t.string :status
    t.datetime :requested_at, :accepted_at, :denied_at, :blocked_at
    t.timestamps
  end

  create_table :blocked_users, :force => true do |t|
    t.references :user, :blocked_user
    t.timestamps
  end
end