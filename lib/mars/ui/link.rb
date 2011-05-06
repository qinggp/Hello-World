class Mars::UI::Link < Mars::UI::Element
  attr_reader :url

  def initialize(name, options = {})
    super
    check_requirement_options(:url)
    @url = options[:url]
  end

  private
  def display_template(view, options={})
    view.link_to(view.t(name), url)
  end
end
