class T40::Ui::Base < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::TimeAgoInWords
  include Phlex::Rails::Helpers::DistanceOfTimeInWords

  private
    def flow(title:, id:, intro: nil, &block)
      section(class: "panel", aria_labelledby: id) do
        h1(id: id) { title }
        p { intro } if intro
        yield
      end
    end
end
