# Test-only tenant-owned model backed by a temporary table, so tenancy
# concerns (AccountScoped, SoftDeletable, PrivacySubject plumbing) can be
# exercised without shipping a placeholder domain model in the starter.
#
# The table is created once per suite run directly on the connection; it never
# appears in db/schema.rb.
class TenantWidget < ApplicationRecord
  include AccountScoped
end

RSpec.configure do |config|
  config.before(:suite) do
    connection = ActiveRecord::Base.connection
    next if connection.table_exists?(:tenant_widgets)

    connection.create_table(:tenant_widgets) do |t|
      t.references :account, null: false
      t.string :name, null: false, default: "Widget"
      t.datetime :deleted_at
      t.timestamps
    end
  end
end
