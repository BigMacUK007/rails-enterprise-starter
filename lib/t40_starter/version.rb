module T40Starter
  class Error < StandardError; end

  VERSION_FILE = File.expand_path("../../VERSION", __dir__)

  # The repo VERSION file is the source of truth. The fallback keeps the
  # installer usable while the file is being introduced.
  VERSION = File.exist?(VERSION_FILE) ? File.read(VERSION_FILE).strip : "2.0.0"

  def self.root
    File.expand_path("../..", __dir__)
  end
end
