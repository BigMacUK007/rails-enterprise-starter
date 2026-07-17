module T40
  # Entry points for data-subject rights flows. Models holding personal data
  # include PrivacySubject and implement privacy_export/privacy_erase!.
  # See docs/privacy/subject-rights.md.
  module Privacy
    class MissingHook < StandardError; end
    class TenantMismatch < StandardError; end

    OPERATIONS = %i[export correction restriction retention legal_hold erasure anonymisation].freeze

    class << self
      def export_for(identity, account: Current.account)
        operate!(:export, subject: identity, account: account)
      end

      def correct!(subject, account: Current.account, **attributes)
        operate!(:correction, subject: subject, account: account, attributes: attributes)
      end

      def restrict!(subject, account: Current.account, reason:)
        operate!(:restriction, subject: subject, account: account, reason: reason)
      end

      def apply_retention!(subject, account: Current.account, policy:)
        operate!(:retention, subject: subject, account: account, policy: policy)
      end

      def apply_legal_hold!(subject, account: Current.account, reason:)
        operate!(:legal_hold, subject: subject, account: account, reason: reason)
      end

      def erase!(subject, account: Current.account)
        operate!(:erasure, subject: subject, account: account)
      end

      def anonymize!(subject, account: Current.account)
        operate!(:anonymisation, subject: subject, account: account)
      end

      # An identity is a candidate for erasure when it no longer holds any
      # active account membership and is not a staff identity. Erasure is
      # irreversible — the decision to erase remains a human one.
      def erasure_candidate?(identity)
        identity.users.active.none? && !identity.staff?
      end

      private
        def operate!(operation, subject:, account:, **arguments)
          raise ArgumentError, "unknown privacy operation" unless OPERATIONS.include?(operation)
          raise TenantMismatch, "privacy operations require the current account" unless account.present? && account == Current.account
          raise TenantMismatch, "privacy subject does not belong to the current account" unless subject_belongs_to?(subject, account)

          method = "privacy_#{operation}!"
          method = "privacy_export" if operation == :export
          raise MissingHook, "#{subject.class} must implement ##{method}" unless subject.respond_to?(method)

          result = arguments.empty? ? subject.public_send(method) : subject.public_send(method, **arguments)
          AuditEvent.record!(action: "privacy.#{operation}", target: subject,
            changes: { account_id: account.id, operation: operation })
          result
        end


        def subject_belongs_to?(subject, account)
          if subject.respond_to?(:account_id)
            subject.account_id == account.id
          elsif subject.respond_to?(:users)
            subject.users.where(account: account).exists?
          else
            false
          end
        end
    end
  end
end
