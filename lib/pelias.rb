require 'debugger'
require 'elasticsearch'
require 'rgeo-geojson'
require 'rgeo-shapefile'
require 'pg'
require 'rspec'
require 'zip'
require 'sidekiq'
require 'sinatra'

require 'pelias/server/server'

module Pelias

  autoload :VERSION, 'pelias/version'

  autoload :Address, 'pelias/address'
  autoload :Admin2, 'pelias/admin2'
  autoload :Base, 'pelias/base'
  autoload :Geoname, 'pelias/geoname'
  autoload :LocalAdmin, 'pelias/local_admin'
  autoload :Locality, 'pelias/locality'
  autoload :Neighborhood, 'pelias/neighborhood'
  autoload :Poi, 'pelias/poi'
  autoload :Street, 'pelias/street'

  autoload :Search, 'pelias/search'

  env = ENV['RAILS_ENV'] || 'development'

  # elasticsearch configuration
  es_config = YAML::load(File.open('config/elasticsearch.yml'))[env]
  transport = Elasticsearch::Transport::Transport::HTTP::Faraday.new(hosts: es_config['hosts']) do |faraday|
    faraday.adapter Faraday.default_adapter
    faraday.options[:timeout] = es_config['timeout'] || 1200
  end

  # put together an elasticsearch client
  ES_CLIENT = Elasticsearch::Client.new(transport: transport, reload_on_failure: true, retry_on_failure: true, randomize_hosts: true)
  INDEX = 'pelias'

  # postgres
  pg_config = YAML::load(File.open('config/postgres.yml'))[env]
  PG_CLIENT = PG.connect(pg_config)

  # sidekiq
  redis_config = YAML::load(File.open('config/redis.yml'))[env]
  redis_url = "redis://#{redis_config['host']}:#{redis_config['port']}/12"
  redis_namespace = redis_config['namespace']
  Sidekiq.configure_server do |config|
    config.redis = { :url => redis_url, :namespace => redis_namespace }
  end
  Sidekiq.configure_client do |config|
    config.redis = { :url => redis_url, :namespace => redis_namespace }
  end

end
