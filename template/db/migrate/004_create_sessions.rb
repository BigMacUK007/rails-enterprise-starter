class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.references :identity, null: false, foreign_key: true
      t.string :user_agent
      t.string :ip_address
      t.datetime :step_up_verified_at

      t.timestamps

      t.index :updated_at
    end
  end
end
