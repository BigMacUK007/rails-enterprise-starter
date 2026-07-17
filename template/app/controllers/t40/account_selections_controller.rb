class T40::AccountSelectionsController < ApplicationController
  layout "public"

  def show
    @memberships = Current.identity.users.active.includes(:account).order("accounts.name")
    redirect_to root_url if @memberships.one?
    render T40::Ui::AccountSelection.new(memberships: @memberships) unless performed?
  end

  def update
    membership = Current.identity.users.active.find_by(account_id: params.expect(:account_id))
    raise Authorization::Denied, "No active membership for that account" unless membership

    session[:account_id] = membership.account_id
    Current.account = membership.account
    redirect_to session.delete(:return_to_after_account_selection) || root_url
  end
end
