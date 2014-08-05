module UrlHelper

  def method_missing(m, *args, &block)
    if m.to_s =~ /^([a-z]+_)+path|url$/
      parts = m.to_s.split('_')
      id_str = "/#{args[0].respond_to?(:id) ? args[0].id : args[0]}"
      url = "/#{parts[-2]}"
      url.pluralize! if parts.length > 2
      url.concat(id_str).concat(parts[0...-2].join('/'))
    else
      super
    end
  end


end

class String
  def pluralize!
    self.concat('e') if self.last == 's'
    self.concat('s')
  end
end