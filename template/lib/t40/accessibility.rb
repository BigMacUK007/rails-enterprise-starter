require "nokogiri"

module T40
  # Small deterministic smoke audit for every representative server-rendered
  # flow. It catches structural regressions; the generated manual checklist
  # remains required for the behaviours automation cannot judge.
  module Accessibility
    module_function

    def audit(html)
      document = Nokogiri::HTML5(html)
      violations = []
      violations << "document language is missing" if document.at_css("html[lang]").nil?
      violations << "exactly one main landmark is required" unless document.css("main").one?
      violations << "exactly one h1 is required" unless document.css("h1").one?

      duplicate_ids = document.css("[id]").group_by { |node| node["id"] }.select { |_id, nodes| nodes.many? }.keys
      violations << "duplicate ids: #{duplicate_ids.join(", ")}" if duplicate_ids.any?

      document.css("input:not([type=hidden]):not([type=submit]):not([type=button]):not([type=reset]):not([type=image]), select, textarea").each do |field|
        id = field["id"]
        labelled = id.present? && document.at_css("label[for='#{id}']").present?
        labelled ||= field["aria-label"].present? || field["aria-labelledby"].present?
        violations << "unlabelled form control #{field.name}##{id}" unless labelled
      end

      violations
    end
  end
end
