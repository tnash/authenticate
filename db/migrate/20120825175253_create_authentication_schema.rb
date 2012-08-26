class CreateAuthenticationSchema < ActiveRecord::Migration
  def change
    # Postgres apparently requires the users_roles table to exist before creating the roles table.
    create_table :users_roles, :id => false do |t|
      t.integer :user_id
      t.integer :role_id
    end

    add_index :users_roles, [:role_id, :user_id]
    add_index :users_roles, [:user_id, :role_id]

    create_table :roles do |t|
      t.string :title
      t.references :resource, :polymorphic => true

      t.timestamps
    end

    add_index(:roles, :title)
    add_index(:roles, [ :title, :resource_type, :resource_id ])



    create_table :users do |t|
      ## Database authenticatable
      t.string    :username,            :null => false
      t.string    :email,               :null => false
      t.string    :encrypted_password
      t.string    :password_salt
      t.string    :name
      t.string    :slug

      ## Trackable
      t.datetime  :current_sign_in_at
      t.datetime  :last_sign_in_at
      t.string    :current_sign_in_ip
      t.string    :last_sign_in_ip
      t.integer   :sign_in_count, :default => 0

      ## Rememerable
      t.datetime  :remember_created_at

      ## Recoverable
      t.string    :reset_password_token
      t.datetime  :reset_password_sent_at

      t.timestamps


      ## Confirmable
      # t.string   :confirmation_token
      # t.datetime :confirmed_at
      # t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, :default => 0 # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at

      ## Token authenticatable
      # t.string :authentication_token

      ## Invitable
      #t.string     :invitation_token, :limit => 60
      #t.datetime   :invitation_sent_at
      #t.datetime   :invitation_accepted_at
      #t.integer    :invitation_limit
      #t.references :invited_by, :polymorphic => true
      #t.index      :invitation_token # for invitable
      #t.index      :invited_by_id


      t.timestamps

    end

    add_index :users, :id
    add_index :users, :email,                :unique => true
    add_index :users, :reset_password_token, :unique => true
    # add_index :users, :confirmation_token,   :unique => true
    # add_index :users, :unlock_token,         :unique => true
    # add_index :users, :authentication_token, :unique => true

  end
end
