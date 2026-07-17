class CreatePrivacyCases < ActiveRecord::Migration[8.1]
  def change
    create_table :privacy_cases do |t|
      t.references :account, null: false, foreign_key: true
      t.references :identity, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :state, null: false, default: "received"
      t.text :reason
      t.text :outcome
      t.datetime :acknowledged_at
      t.datetime :completed_at
      t.timestamps

      t.index [ :account_id, :state ]
      t.index [ :account_id, :identity_id, :kind ], name: "index_privacy_cases_on_tenant_subject_kind"
    end
  end
end
