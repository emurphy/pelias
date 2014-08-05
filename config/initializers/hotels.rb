require 'hotels/client'

hotels_config = YAML::load(File.open('config/hotels.yml'))
Hotels::CLIENT = Hotels::Client.new
Hotels::CLIENT.url = hotels_config['url']
