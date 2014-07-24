require 'pelias'

namespace :geonames do

  task :prepare => :download do
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

  task :download do
    ['allCountries', 'alternateNames'].each do |name|
      unless File.exist?("#{TEMP_PATH}/#{name}.txt")
        `wget http://download.geonames.org/export/dump/#{name}.zip -P #{TEMP_PATH}`
        `unzip #{TEMP_PATH}/#{name}.zip -d #{TEMP_PATH}`
      end
    end
  end

end
