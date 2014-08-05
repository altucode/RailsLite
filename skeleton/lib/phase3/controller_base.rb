require_relative '../phase2/controller_base'
require 'active_support/core_ext'
require 'erb'

module Phase3
  class ControllerBase < Phase2::ControllerBase
    # use ERB and binding to evaluate templates
    # pass the rendered html to render_content
    def render(template_name)
      doc = File.read(
        "views/#{self.class.name.underscore}/#{template_name.to_s}.html.erb")
      erb = ERB.new(doc)
      self.render_content(erb.result(self.get_binding), 'text/html')
    end
  end
end
