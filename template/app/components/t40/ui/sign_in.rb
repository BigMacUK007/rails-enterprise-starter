class T40::Ui::SignIn < T40::Ui::Base
  def view_template
    flow(title: "Sign in", id: "sign-in-title") do
      form_with(url: session_path, class: "form") do |form|
        div(class: "form__group") do
          form.label(:email_address, "Email address")
          form.email_field(:email_address, required: true, autofocus: true,
            autocomplete: "email", placeholder: "you@example.com")
        end
        form.submit("Send sign-in code", class: "btn btn--primary full-width")
      end
    end
  end
end
