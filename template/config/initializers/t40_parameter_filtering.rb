# Additional sensitive parameters filtered from logs, error reports and
# request inspection, appended to the Rails defaults (which already cover
# passw, secret, token, key and friends).
#
# :code and :magic_link cover the passwordless sign-in flow; the rest cover
# common high-risk personal and financial fields.
Rails.application.config.filter_parameters += [
  :code, :magic_link, :cvv, :pan, :national_insurance, :nino, :dob, :date_of_birth
]
