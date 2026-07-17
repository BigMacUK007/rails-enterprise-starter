class CreateSupportAccessGrants < ActiveRecord::Migration[8.1]
  def change
    create_table :support_access_grants do |t|
      t.references :account, null: false, foreign_key: true, index: false
      t.references :identity, null: false, foreign_key: true # the staff member
      t.references :granted_by, null: false, foreign_key: { to_table: :identities }
      t.string :reason, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at

      t.timestamps

      t.index [ :account_id, :expires_at ]
    end
  end
end
