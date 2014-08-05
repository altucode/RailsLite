require 'uri'

module Phase5
  class Params
    # use your initialize to merge params from
    # 1. query string
    # 2. post body
    # 3. route params
    def initialize(req, route_params = {})
      @params = route_params.dup
      parse_www_encoded_form(req.body.to_s)
      parse_www_encoded_form(req.query_string.to_s)
    end

    def [](key)
      @params[key.to_s]
    end

    def to_s
      @params.to_json.to_s
    end

    class AttributeNotFoundError < ArgumentError; end;

    private
    # this should return deeply nested hash
    # argument format
    # user[address][street]=main&user[address][zip]=89436
    # should return
    # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
    def parse_www_encoded_form(www_encoded_form)
      URI::decode_www_form(www_encoded_form).each do |pair|
        keys = parse_key(pair[0])
        tmp = @params
        keys[0...-1].each do |key|
          tmp = tmp[key] ||= Hash.new
        end
        tmp[keys.last] = pair[1]
      end
    end

    # this should return an array
    # user[address][street] should return ['user', 'address', 'street']
    def parse_key(key)
      splits = key.split(/\]\[|\[|\]/)
    end
  end
end
