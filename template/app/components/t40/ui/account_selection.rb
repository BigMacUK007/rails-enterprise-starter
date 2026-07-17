class T40::Ui::AccountSelection < T40::Ui::Base
  def initialize(memberships:)
    @memberships = memberships
  end

  def view_template
    flow(title: "Choose an account", id: "account-selection-title",
      intro: "Select the organisation you want to work in.") do
      ul(class: "card-list") do
        @memberships.each do |membership|
          li do
            button_to(membership.account.name, account_selection_path,
              method: :patch, params: { account_id: membership.account_id }, class: "button")
          end
        end
      end
    end
  end
end
