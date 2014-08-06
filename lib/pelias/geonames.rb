module Pelias
  class Geonames

    def self.alternate_names(gn_id)
      gn_alt_names = DB[:gn_alternatename].select(:alternatename).where(geonameid: gn_id, isolanguage: ['en', 'iata'])
      gn_alt_names.map { |r| r[:alternatename] }
    end
  end
end