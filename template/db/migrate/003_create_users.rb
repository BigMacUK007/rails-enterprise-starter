class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.references :account, null: false, foreign_key: true
      t.references :identity, foreign_key: true
      t.string :name, null: false
      t.string :role, default: "member", null: false
      t.boolean :active, default: true, null: false

      t.timestamps

      t.index [ :account_id, :identity_id ], unique: true
    end
  end
end
