class PrivacyCase < ApplicationRecord
  include AccountScoped

  KINDS = %w[export correction restriction retention legal_hold erasure anonymisation complaint].freeze
  TRANSITIONS = {
    "received" => %w[acknowledged rejected],
    "acknowledged" => %w[investigating rejected],
    "investigating" => %w[in_progress rejected],
    "in_progress" => %w[completed rejected],
    "completed" => [],
    "rejected" => []
  }.freeze

  belongs_to :identity

  validates :kind, inclusion: { in: KINDS }
  validates :state, inclusion: { in: TRANSITIONS.keys }

  def transition_to!(next_state, reason: nil, outcome: nil)
    next_state = next_state.to_s
    raise ArgumentError, "invalid privacy case transition #{state} -> #{next_state}" unless TRANSITIONS.fetch(state).include?(next_state)

    transaction do
      previous = state
      attributes = { state: next_state, reason: reason.presence || self.reason, outcome: outcome.presence || self.outcome }
      attributes[:acknowledged_at] = Time.current if next_state == "acknowledged"
      attributes[:completed_at] = Time.current if %w[completed rejected].include?(next_state)
      update!(attributes)
      AuditEvent.record!(action: "privacy_case.#{next_state}", target: self, reason: reason,
        changes: { from: previous, to: next_state, kind: kind })
    end
  end
end
