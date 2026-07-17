class CreateT40JobExecutions < ActiveRecord::Migration[8.1]
  def change
    create_table :t40_job_executions do |t|
      t.references :account, null: false, foreign_key: true
      t.string :idempotency_key, null: false
      t.string :job_class, null: false
      t.string :state, null: false, default: "running"
      t.jsonb :result
      t.datetime :completed_at
      t.timestamps

      t.index %i[account_id idempotency_key], unique: true, name: "index_t40_jobs_on_tenant_idempotency_key"
    end
  end
end
