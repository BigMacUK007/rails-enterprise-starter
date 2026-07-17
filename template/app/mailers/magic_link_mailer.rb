class MagicLinkMailer < ApplicationMailer
  def sign_in_instructions(magic_link)
    @magic_link = magic_link
    @code = magic_link.code

    mail to: magic_link.identity.email_address, subject: "Your sign-in code"
  end
end
