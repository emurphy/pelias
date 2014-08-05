require 'curb'

module Hotels
  class Client

    attr_accessor :url, :username, :password

    def count_within(geoname_id)
      path = "/hotels/count.json?gn_id=#{geoname_id}"
      request_url = "#{url}#{path}"
      begin
        if username.present? && password.present?
          http = Curl::Easy.new(request_url)
          http.http_auth_types = :basic
          http.username = username
          http.password = password
          http.perform
        else
          http = Curl.get(request_url)
        end
        if (http.response_code == 200)
          #puts "#{request_url} responded with #{http.body_str}"
          MultiJson.load(http.body_str)
        else
          puts "response #{http.response_code} for #{path} with body #{http.body_str}"
          nil
        end
      rescue Curl::Err::CurlError => e
        puts "CurlError #{e} getting hotels, trace: #{e.backtrace}"
        nil
      end
    end
  end
end