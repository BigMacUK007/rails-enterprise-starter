require "rails_helper"

RSpec.describe "Passwordless sign in", type: :system do
  let(:identity) { create(:identity, email_address: "person@example.com") }

  it "signs in with an emailed code and returns to the original destination" do
    identity

    visit "/t40_spec/protected"
    expect(page).to have_content("Sign in")

    fill_in "email_address", with: "person@example.com"
    click_button "Send sign-in code"

    expect(page).to have_content("Check your email")
    fill_in "code", with: MagicLink.last.code
    click_button "Verify"

    expect(page).to have_content("Protected area")
  end

  it "passes the generated structural accessibility audit on representative states" do
    identity
    visit "/session/new"
    expect(T40::Accessibility.audit(page.html)).to be_empty

    fill_in "email_address", with: identity.email_address
    click_button "Send sign-in code"
    expect(T40::Accessibility.audit(page.html)).to be_empty
  end

  it "signs out" do
    sign_in_through_browser

    page.driver.submit :delete, "/session", {}

    expect(page).to have_content("Sign in")
    visit "/t40_spec/protected"
    expect(page).to have_content("Sign in")
  end

  it "cannot resume after server-side session revocation" do
    sign_in_through_browser
    visit "/t40_spec/protected"
    expect(page).to have_content("Protected area")

    Session.revoke_all_for(identity)

    visit "/t40_spec/protected"
    expect(page).to have_content("Sign in")
  end

  def sign_in_through_browser
    visit "/session/new"
    fill_in "email_address", with: identity.email_address
    click_button "Send sign-in code"
    fill_in "code", with: identity.magic_links.order(:id).last.code
    click_button "Verify"
    expect(page).to have_content("Home")
  end
end
