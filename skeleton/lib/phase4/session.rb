require 'json'
require 'webrick'

module Phase4
  class Session
    # find the cookie for this app
    # deserialize the cookie into a hash
    def initialize(req)
      @values = {}
      req.cookies.each do |cookie|
        if cookie.name == '_rails_lite_app'
          @values = JSON.parse(cookie.value)
          return
        end
      end
    end

    def [](key)
      @values[key]
    end

    def []=(key, val)
      @values[key] = val
    end

    # serialize the hash into json and save in a cookie
    # add to the responses cookies
    def store_session(res)
      res.cookies << WEBrick::Cookie.new('_rails_lite_app', JSON.generate(@values))
    end
  end
end
