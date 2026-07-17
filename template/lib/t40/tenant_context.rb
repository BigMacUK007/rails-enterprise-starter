module T40
  # Canonical tenant carriers for boundaries that do not have an
  # AccountScoped Active Record relation of their own. Callers never accept an
  # account id from request input: the default authority is Current.account.
  module TenantContext
    class MissingAccount < StandardError; end

    module_function

    def require_account!(account = Current.account)
      account || raise(MissingAccount, "an active account is required")
    end

    def cache_key(key, account: Current.account)
      "account/#{require_account!(account).id}/#{key}"
    end

    def storage_key(filename:, record: nil, account: Current.account)
      owner = require_account!(account)
      record_key = record ? "#{record.model_name.singular}/#{record.to_param}" : "unbound"
      "accounts/#{owner.id}/#{record_key}/#{File.basename(filename.to_s)}"
    end

    def rate_limit_key(scope:, discriminator:, account: Current.account)
      "account:#{require_account!(account).id}:#{scope}:#{discriminator}"
    end

    def log_context(account: Current.account)
      { account_id: require_account!(account).id }
    end
  end
end
