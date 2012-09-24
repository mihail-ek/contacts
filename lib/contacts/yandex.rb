require 'csv'

class Contacts
  class Yandex < Base
    LOGIN_URL = "https://passport.yandex.ru/passport?mode=auth&from=mail"
    ADDRESS_BOOK_URL = "http://mail.yandex.ru/neo2/handlers/abook-export.jsx?lang=ru&tp=0"
    POST_URL = "http://mail.yandex.ru"

    attr_accessor :cookies

    def real_connect
      postdata = "mode=auth&from=passport&display=page&login=%s&passwd=%s" % [
        CGI.escape(login),
        CGI.escape(password)
      ]
      data, resp, self.cookies, forward = post(LOGIN_URL, postdata, '')
      if data.index('action="https://passport.yandex.ru/passport?mode=auth"')
        raise AuthenticationError, "Username and password do not match"
      elsif (self.cookies == "" or data == "") and forward == ""
        raise ConnectionError, PROTOCOL_ERROR
      end
      while forward
        data, resp, self.cookies, forward = get(forward, self.cookies)
      end
    end

    def contacts
      postdata = ""
      data, resp, cookies, forward = get(ADDRESS_BOOK_URL, self.cookies)
      @contacts = []
      parse_array = CSV.parse(data)
      parse_array.delete_at 0
      parse_array.each do |row|
        @contacts << [row[0], row[6]]
      end
      @contacts
    end

    def skip_gzip?
      true
    end

    private
    def login_token_link(data)
      data.match(/url=(.+)\">/)[1]
    end

    def domain_param(login)
      login.include?('@') ?
          login.match(/.+@(.+)/)[1] :
          'yandex.ru'
    end
  end
  TYPES[:yandex] = Yandex
end