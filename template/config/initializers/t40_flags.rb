# Validates feature-flag metadata at boot. Every flag in
# config/t40/feature-flags.yml must declare a description, an owner, a
# removal_by date and a boolean default — temporary release controls must not
# become permanent debris. Missing flags always read as disabled (safe
# default); durable customer capabilities belong in Account entitlements, not
# here.
Rails.application.config.after_initialize do
  T40::Flags.validate!
end
