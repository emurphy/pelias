require 'hotels/client'

Hotels::CLIENT = Hotels::Client.new
Hotels::CLIENT.url = "http://localhost:3000"
