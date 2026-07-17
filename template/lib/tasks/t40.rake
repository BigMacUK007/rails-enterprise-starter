namespace :t40 do
  desc "Create the first account, identity and owner membership (idempotent). ENV: ACCOUNT_NAME, ADMIN_EMAIL"
  task bootstrap: :environment do
    account_name = ENV["ACCOUNT_NAME"].to_s.strip
    admin_email = ENV["ADMIN_EMAIL"].to_s.strip

    if account_name.empty? || admin_email.empty?
      abort "Usage: ACCOUNT_NAME=\"Acme Ltd\" ADMIN_EMAIL=owner@example.com bin/rails t40:bootstrap"
    end

    account = if T40::Installation.single_account?
      abort "Single-account mode found more than one account; reconcile the data before bootstrapping." if Account.count > 1
      Account.first || Account.create!(name: account_name)
    else
      Account.find_or_create_by!(name: account_name)
    end
    identity = Identity.find_or_create_by!(email_address: admin_email)
    user = User.find_or_create_by!(account: account, identity: identity) do |membership|
      membership.name = admin_email
      membership.role = :owner
    end

    puts "Account:  ##{account.id} #{account.name}"
    puts "Identity: ##{identity.id} #{identity.email_address}"
    puts "User:     ##{user.id} role=#{user.role} active=#{user.active}"
    puts
    puts "To sign in: start the application, visit /session/new and enter"
    puts "#{identity.email_address} — a short-lived single-use code will be"
    puts "emailed (check your Action Mailer delivery configuration)."
  end

  desc "Pretty-print the installed control manifest (config/t40/control-manifest.yml)"
  task controls: :environment do
    path = Rails.root.join("config/t40/control-manifest.yml")
    abort "No control manifest at #{path}. Run bin/setup-enterprise from the starter first." unless path.exist?

    manifest = YAML.safe_load_file(path, permitted_classes: [ Date, Time ], aliases: true) || {}
    controls = Array(manifest["controls"])

    puts "Starter version: #{manifest["starter_version"]}"
    puts "Installed at:    #{manifest["installed_at"]}"
    puts "Controls:        #{controls.size}"
    puts

    controls.group_by { |control| control["status"].to_s }.sort.each do |status, group|
      puts "#{status.upcase} (#{group.size})"
      group.each do |control|
        line = "  #{control["id"].to_s.ljust(12)} #{control["name"]}"
        line += " [owner: #{control["owner"]}]" if control["owner"]
        line += " [reason: #{control["reason"]}]" if control["reason"]
        puts line
      end
      puts
    end
  end

  namespace :flags do
    desc "List feature flags with owner and removal date; highlight expired flags"
    task report: :environment do
      path = Rails.root.join("config/t40/feature-flags.yml")
      abort "No feature flags file at #{path}." unless path.exist?

      config = YAML.safe_load_file(path, permitted_classes: [ Date ]) || {}
      flags = config["flags"] || {}
      expired = T40::Flags.expired_flags.map(&:to_s)

      if flags.empty?
        puts "No feature flags defined."
      else
        flags.each do |key, definition|
          definition ||= {}
          marker = expired.include?(key.to_s) ? " [EXPIRED — REMOVE]" : ""
          puts "#{key}#{marker}"
          puts "  default:    #{definition["default"].inspect}"
          puts "  owner:      #{definition["owner"]}"
          puts "  removal_by: #{definition["removal_by"]}"
          puts "  #{definition["description"]}"
          puts
        end
      end

      puts "#{flags.size} flag(s), #{expired.size} expired."
    end
  end
end
