module T40Starter
  # One planned install step. `type` is :file, :migration or :edit.
  # `status` is :create, :skip, :conflict, :edit, :project_owned or :noop. `content` carries
  # the full desired file content so apply never recomputes a decision the
  # plan already made.
  Action = Struct.new(:type, :status, :target, :source, :content, :reason, keyword_init: true) do
    def conflict? = status == :conflict

    def change? = %i[create edit].include?(status)

    # Machine-readable shape for --json output (content is deliberately
    # excluded: it can be large and is an apply-time concern).
    def to_h
      {
        "type" => type.to_s,
        "status" => status.to_s,
        "target" => target,
        "source" => source,
        "reason" => reason
      }.compact
    end
  end
end
