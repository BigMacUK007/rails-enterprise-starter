class CreateAuditEvents < ActiveRecord::Migration[8.1]
  def up
    create_table :audit_events do |t|
      # account is nullable: pre-authentication events (for example failed
      # sign-in attempts) are documented global events without a tenant.
      t.references :account, foreign_key: true, index: false
      t.references :identity, foreign_key: true
      t.references :impersonator, foreign_key: { to_table: :identities }
      t.string :action, null: false
      t.string :target_type
      t.bigint :target_id
      t.string :result, null: false, default: "success"
      t.string :reason
      t.string :correlation_id
      t.string :release
      t.jsonb :change_summary
      t.datetime :occurred_at, null: false

      # Append-only: audit events are never updated, so there is no updated_at.
      t.datetime :created_at, null: false

      t.index [ :account_id, :occurred_at ]
      t.index [ :target_type, :target_id ]
      t.index :correlation_id
      t.index :action
    end

    execute <<~SQL
      CREATE FUNCTION t40_reject_audit_event_mutation() RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'audit_events are append-only';
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER t40_audit_events_append_only
      BEFORE UPDATE OR DELETE ON audit_events
      FOR EACH ROW EXECUTE FUNCTION t40_reject_audit_event_mutation();
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS t40_audit_events_append_only ON audit_events"
    execute "DROP FUNCTION IF EXISTS t40_reject_audit_event_mutation()"
    drop_table :audit_events
  end
end
