# Test-only routed controllers so request and system specs can drive the
# authentication, tenancy and authorisation guarantees through the full
# middleware stack without the starter shipping demo screens.
#
# The starter deliberately ships no root route (the application owns its own
# home screen), so the specs append one: the authentication concern redirects
# to root_url after sign-in and that helper must resolve.
module T40Spec
  class HomeController < ApplicationController
    def show
      render html: helpers.tag.h1("Home")
    end
  end

  class ProtectedController < ApplicationController
    def show
      render html: helpers.tag.h1("Protected area")
    end
  end

  class WidgetsController < ApplicationController
    def show
      widget = TenantWidget.for_account(Current.account).find(params[:id])
      render json: { id: widget.id, name: widget.name }
    end

    def update
      widget = TenantWidget.for_account(Current.account).find(params[:id])
      widget.update!(name: params[:name])
      head :no_content
    end

    # Deliberately unscoped lookup, simulating a query that forgot for_account:
    # the tenant boundary must still hold at the authorisation layer because
    # authorize! asserts record.account_id against Current.account.
    def export
      widget = TenantWidget.find(params[:id])
      authorize! :can_export_data?, widget
      render json: { exported: widget.id }
    end
  end
end

Rails.application.routes.append do
  root to: "t40_spec/home#show"
  get "/t40_spec/protected", to: "t40_spec/protected#show"
  resources :t40_spec_widgets, controller: "t40_spec/widgets", only: %i[ show update ] do
    member do
      post :export
    end
  end
end

Rails.application.reload_routes!
