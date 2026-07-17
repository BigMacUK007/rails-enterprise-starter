class CreateIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :identities do |t|
      t.string :email_address, null: false
      t.boolean :staff, default: false, null: false

      t.timestamps

      t.index :email_address, unique: true
    end
  end
end
