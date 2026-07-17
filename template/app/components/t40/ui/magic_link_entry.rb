class T40::Ui::MagicLinkEntry < T40::Ui::Base
  def initialize(email_address:)
    @email_address = email_address
  end

  def view_template
    flow(title: "Check your email", id: "magic-link-title") do
      p do
        plain "We sent a 6-digit code to "
        strong { @email_address }
      end
      form_with(url: session_magic_link_path, class: "form") do |form|
        div(class: "form__group") do
          form.label(:code, "Enter your code")
          form.text_field(:code, required: true, autofocus: true,
            autocomplete: "one-time-code", maxlength: 6, placeholder: "ABC123",
            aria: { describedby: "code-help" })
        end
        form.submit("Verify", class: "btn btn--primary full-width")
      end
      p(id: "code-help", class: "txt-small txt-muted") do
        plain "Didn't get the email? "
        link_to("Try again", new_session_path)
      end
    end
  end
end
