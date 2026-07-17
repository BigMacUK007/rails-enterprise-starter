require "open3"

module T40Starter
  # Runs commands with a sanitised environment so Bundler settings from the
  # starter checkout (or any parent directory) do not leak into the target
  # application.
  module Shell
    CLEAN_ENV = {
      "BUNDLE_GEMFILE" => nil,
      "BUNDLE_PATH" => nil,
      "BUNDLE_APP_CONFIG" => nil,
      "BUNDLE_BIN_PATH" => nil,
      "BUNDLER_VERSION" => nil,
      "RUBYOPT" => nil,
      "RUBYLIB" => nil
    }.freeze

    module_function

    # Runs a command and returns { status:, success:, output:, duration: }.
    # When `stream:` is an IO, output is echoed there as it arrives.
    def run(*command, chdir:, stream: nil)
      started = monotonic_now
      output = +""
      process_status = nil
      Open3.popen2e(CLEAN_ENV, *command, chdir: chdir) do |stdin, stdout_and_stderr, wait_thread|
        stdin.close
        stdout_and_stderr.each_line do |line|
          output << line
          stream&.print(line)
        end
        process_status = wait_thread.value
      end
      {
        status: process_status.exitstatus,
        success: process_status.success?,
        output: output,
        duration: (monotonic_now - started).round(2)
      }
    rescue Errno::ENOENT, Errno::EACCES => error
      {
        status: 127,
        success: false,
        output: "#{error.message}\n",
        duration: (monotonic_now - started).round(2)
      }
    end

    def monotonic_now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
