require "rails_helper"

RSpec.describe "T40 observability" do
  FakeErrorAdapter = Struct.new(:events) do
    def capture(event) = events << event
  end

  after { T40::ErrorReporter.reset! }

  it "redacts structured and string-form secrets" do
    expect(T40::LogRedactor.redact(password: "secret", nested: { token: "abc", safe: "yes" }))
      .to eq(password: "[FILTERED]", nested: { token: "[FILTERED]", safe: "yes" })
    expect(T40::LogRedactor.redact("token=abc Bearer xyz safe=yes"))
      .to eq("token=[FILTERED] Bearer [FILTERED] safe=yes")
  end

  it "preserves release, tenant and correlation fields in structured logs without secrets" do
    account = create(:account)
    output = Current.set(account: account, request_id: "req-42") do
      T40JsonLogFormatter.new.call("INFO", Time.current, "spec", "token=secret operation=export")
    end
    payload = JSON.parse(output)

    expect(payload).to include("request_id" => "req-42", "account_id" => account.id, "release" => T40JsonLogFormatter::RELEASE)
    expect(payload["message"]).to eq("token=[FILTERED] operation=export")
  end

  it "delivers a redacted exception event to a replaceable adapter" do
    adapter = FakeErrorAdapter.new([])
    T40::ErrorReporter.adapter = adapter
    account = create(:account)

    Current.set(account: account, request_id: "req-error") do
      T40::ErrorReporter.capture(StandardError.new("token=top-secret"), context: { password: "hidden", operation: "sync" })
    end

    event = adapter.events.fetch(0)
    expect(event.message).to eq("token=[FILTERED]")
    expect(event.context).to include(account_id: account.id, request_id: "req-error", password: "[FILTERED]", operation: "sync")
  end
end
