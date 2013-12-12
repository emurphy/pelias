require 'pelias'
require 'open-uri'

# going to restrict to US for now
RESTRICT_COUNTRY = 'US'

namespace :geonames do

  task :reindex do
    results = Pelias::ES_CLIENT.search(index: 'pelias',
      type: 'geoname', scroll: '5m', fields: 'id',
      body: { query: { match_all: {} }, sort: '_id' })
      results['hits']['hits'].each do |h|
        Pelias::Geoname.find(h['_id']).reindex
      end
    begin
      results = Pelias::ES_CLIENT.scroll(scroll: '5m',
        scroll_id: results['_scroll_id'])
      results['hits']['hits'].each do |h|
        Pelias::Geoname.find(h['_id']).reindex
      end
    end while results['hits']['hits'].count > 0
  end

  task :download do
    url = 'http://download.geonames.org/export/dump/allCountries.zip'
    puts "downloading #{url}"
    open('data/geonames/allCountries.zip', 'wb') do |file|
      file << open(url).read
    end
    Zip::File::open("data/geonames/allCountries.zip") do |zip|
      zip.each do |entry|
        unzipped_file = "data/geonames/#{entry.name}"
        FileUtils.rm(unzipped_file, :force => true)
        puts "extracting #{unzipped_file}"
        entry.extract(unzipped_file)
      end
    end
  end

  task :populate do
    File.open('data/geonames/allCountries.txt') do |fp|
      fp.each_slice(50) do |lines|
        bulk = []
        lines.each do |line|
          arr = line.chomp.split("\t")
          next unless arr[8] == RESTRICT_COUNTRY
          bulk << {
            :id => arr[0],
            :name => arr[1],
            :alternate_names => arr[3].split(','),
            :center_point => [arr[5].to_f, arr[4].to_f],
            :center_shape => {
              type: 'Point',
              coordinates: [arr[5].to_f, arr[4].to_f]
            },
            :feature_class => arr[6],
            :feature_code => arr[7],
            :country_code => arr[8],
            :admin1_code => arr[10],
            :admin2_code => arr[11],
            :admin3_code => arr[12],
            :admin4_code => arr[13],
            :population => arr[14],
            :elevation => arr[15]
          }
        end
        Pelias::Geoname.delay.create(bulk) unless bulk.empty?
      end
    end
  end

end