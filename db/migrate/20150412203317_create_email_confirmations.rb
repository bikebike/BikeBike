class CreateEmailConfirmations < ActiveRecord::Migration
  def change
    create_table :email_confirmations do |t|
      t.string :token
      t.integer :user_id
      t.datetime :expiry
      t.string :url

      t.timestamps null: false
    end
  end
end
