require 'hashie/mash'

module Pelias

  module Suggestion

    extend self

    def rebuild_suggestions_for_admin0(e)
      rebuild_suggestions_for_admin1(e)
    end

    def rebuild_suggestions_for_admin1(e)
      {
        input: [],
        output: e.name,
        weight: 1
      }
    end

    def rebuild_suggestions_for_admin2(e)
      {
        input:  [],
        output: [e.name, e.admin1_abbr || e.admin1_name].compact.join(', '),
        weight: 1
      }
    end

    def rebuild_suggestions_for_local_admin(e)
      {
        input: [],
        output: [e.name, e.admin1_abbr || e.admin1_name].compact.join(', '),
        weight: 1
      }
    end

    def rebuild_suggestions_for_locality(e)
      boost = weight(e)
      outputs = [e.name]
      if e.admin0_abbr == "US"
        state_abbr = e.admin1_abbr
        state = e.admin1_name
        inputs = [e.name, state_abbr, state]
        outputs << state_abbr || state
      else
        country = e.admin0_name
        inputs = [e.name, e.admin0_abbr, country]
        outputs << country
      end
      inputs = inputs + e.alternate_names if e.alternate_names
      {
        input: inputs,
        output: outputs.compact.join(', '),
        weight: boost < 1 ? 1 : boost
      }
    end

    def rebuild_suggestions_for_neighborhood(e)
      adn = e.locality_name || e.local_admin_name || e.admin2_name
      inputs = [e.name, e.admin1_abbr, e.admin1_name, e.locality_name, e.local_admin_name, e.admin2_name]
      {
        input: inputs,
        output: [e.name, adn, e.admin1_abbr || e.admin1_name].compact.join(', '),
        weight: adn ? 10 : 0
      }
    end

    def rebuild_suggestions_for_address(e)
      adn = e.local_admin_name || e.locality_name || e.neighborhood_name || e.admin2_name
      inputs = [e.name, e.local_admin_name, e.locality_name, e.neighborhood_name, e.admin2_name]
      {
        input: inputs,
        output: [e.name, adn, e.admin1_abbr || e.admin1_name].compact.join(', '),
        weight: adn ? 10 : 0
      }
    end

    def rebuild_suggestions_for_street(e)
      adn = e.local_admin_name || e.locality_name || e.neighborhood_name || e.admin2_name
      inputs = [e.name, e.local_admin_name, e.locality_name, e.neighborhood_name, e.admin2_name]
      {
        input: inputs,
        output: [e.name, adn, e.admin1_abbr || e.admin1_name].join(', '),
        weight: adn ? 8 : 0
      }
    end

    def rebuild_suggestions_for_poi(e)
      inputs = [e.name, e.address_name, e.street_name, e.local_admin_name, e.locality_name, e.neighborhood_name, e.admin2_name, e.admin1_name, e.admin1_abbr]
      {
        input: inputs,
        output: [e.name, e.address_name, e.local_admin_name || e.locality_name, e.admin1_abbr || e.admin1_name].compact.join(', '),
        weight: e.locality_name || e.local_admin_name ? 6 : 0
      }
    end

    def weight(entry)
      weight_by_hotels entry
    end

    def weight_by_hotels(entry)
      if entry.hotel_market_weight
        entry.hotel_market_weight.to_i / 10
      else
        if entry.gn_id
          weight_by_population entry
        else
          1
        end
      end
    end

    def weight_by_population(entry)
      entry.population.to_i / 100_000
    end
  end

end
