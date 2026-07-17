class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.jsonb :entitlements, null: false, default: {}
      # NULL for multi-account installations; true for the single account in
      # single-account mode. PostgreSQL permits many NULLs but only one true.
      t.boolean :single_account_guard

      t.timestamps
      t.index :single_account_guard, unique: true
    end
  end
end
