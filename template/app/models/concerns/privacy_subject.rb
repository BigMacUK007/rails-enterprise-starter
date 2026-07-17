# Registry for models that hold personal data. Including models MUST
# implement:
#
#   #privacy_export  — a hash of the personal data held for the subject
#   #privacy_erase!  — irreversible erasure or anonymisation that records
#                      audit evidence
#
# The registry (PrivacySubject.registered_models) feeds the data inventory
# and subject-rights flows — see T40::Privacy and
# docs/privacy/subject-rights.md.
module PrivacySubject
  extend ActiveSupport::Concern

  class << self
    def registered_models
      registered_model_names.filter_map(&:safe_constantize)
    end

    def register(model)
      return if model.name.nil?

      registered_model_names << model.name unless registered_model_names.include?(model.name)
    end

    private
      def registered_model_names
        @registered_model_names ||= []
      end
  end

  included do
    PrivacySubject.register(self)
  end

  def privacy_export
    raise NotImplementedError, "#{self.class} must implement #privacy_export"
  end

  def privacy_erase!
    raise NotImplementedError, "#{self.class} must implement #privacy_erase!"
  end
end
