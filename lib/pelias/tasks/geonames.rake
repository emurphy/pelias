require 'pelias'

namespace :geonames do

  desc "load geonames data to database and redis cache"
  task :prepare => [:load, :cache] do

  end

  task :cache do
    INCREMENTAL = false
    i = 0
    File.open("#{TEMP_PATH}/allCountries.txt").each do |line|
      puts "Inserted #{i}" if (i += 1) % 10_000 == 0
      arr = line.chomp.split("\t")
      geoname_id = arr[0]
      begin
        unless INCREMENTAL && Pelias::REDIS.hget('geoname', geoname_id)
          if Hotels::CLIENT.present?
            count_and_weight = Hotels::CLIENT.count_within geoname_id
            if count_and_weight.present?
                hotel_count = count_and_weight[:count]
                hotel_market_weight = count_and_weight[:market_weight]
              end
            end
            hotel_count = '' if hotel_count.nil?
            hotel_market_weight = '' if hotel_market_weight.nil?
              Pelias::REDIS.hset('geoname', geoname_id, {
                  name: arr[1],
                  population: arr[14].to_i,
                  hotels: hotel_count,
                  hotel_market_weight: hotel_market_weight,
                  alternate_names: Pelias::Geonames.alternate_names(geoname_id)
              }.to_json)
          end
      rescue Redis::BaseConnectionError
        retry
      end
    end
  end

  task :load => :download do
    Pelias::DB.run(File.read('config/data/create_geonames_tables.sql'))

    copy_geonames = """
          copy gn_geoname (geonameid,name,asciiname,alternatenames,latitude,longitude,fclass,fcode,country,cc2,
                            admin1,admin2,admin3,admin4,population,elevation,gtopo30,timezone,moddate)
          from '#{TEMP_PATH}/allCountries.txt' null as '' """
    Pelias::DB.run(copy_geonames)

    copy_alternatenames = """
          copy gn_alternatename (alternatenameid,geonameid,isoLanguage,alternateName,isPreferredName,
                                 isShortName,isColloquial,isHistoric)
          from '#{TEMP_PATH}/alternateNames.txt' null as '' """
    Pelias::DB.run(copy_alternatenames)
  end

  # desc "Add geometry column for use by task quattroshapes:patch_geoname_ids"
  task :add_geometry do
    Pelias::DB.run("SELECT AddGeometryColumn ('public','gn_geoname','geom',4326,'POINT',2)")
    Pelias::DB.run("UPDATE gn_geoname SET geom = ST_PointFromText('POINT(' || longitude || ' ' || latitude || ')', 4326)")
    Pelias::DB.run("CREATE INDEX idx_gn_geoname_geom ON public.gn_geoname USING gist(geom)")
  end

  task :download do
    ['allCountries', 'alternateNames'].each do |name|
      unless File.exist?("#{TEMP_PATH}/#{name}.txt")
        `wget http://download.geonames.org/export/dump/#{name}.zip -P #{TEMP_PATH}`
        `unzip #{TEMP_PATH}/#{name}.zip -d #{TEMP_PATH}`
      end
    end
  end

end
