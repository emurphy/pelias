require 'hotels/client'

hotels_config = YAML::load(File.open('config/hotels.yml'))
Hotels::CLIENT = Hotels::Client.new
Hotels::CLIENT.url = hotels_config['url']
Hotels::CLIENT.username = hotels_config['username'] if hotels_config['username']
Hotels::CLIENT.password = hotels_config['password'] if hotels_config['password']