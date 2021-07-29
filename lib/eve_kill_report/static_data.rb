require 'down'

require 'byebug'

module EVEKillReport
  class StaticData
    MAP_URL = 'https://www.fuzzwork.co.uk/dump/latest/mapDenormalize.csv'
    TYPES_URL = 'https://www.fuzzwork.co.uk/dump/latest/invTypes.csv'

    attr_reader :dir, :logger, :map, :types

    def initialize(options = {})
      @dir = options[:dir]
      @logger = options[:logger]
    end

    def download
      unless File.exist?(map_path)
        logger.debug "Downloading map data from #{MAP_URL}"
        Down.download(MAP_URL, destination: map_path)
        logger.info "Downloaded map data from #{MAP_URL} to #{map_path}"
      end

      unless File.exist?(types_path)
        logger.debug "Downloading type data from #{TYPES_URL}"
        Down.download(TYPES_URL, destination: types_path)
        logger.info "Downloaded type data from #{TYPES_URL} to #{types_path}"
      end
    end

    def parse
      logger.debug("Loading map data from #{map_path}")
      @map = CSV.table(map_path)
      logger.info("Loaded map data from #{map_path}")

      logger.debug("Loading type data from #{types_path}")
      @types = CSV.table(types_path)
      logger.info("Loaded type data from #{types_path}")
    end

    def region(id)
      if regions.key?(id)
        return regions[id]
      end

      regions[id] = location(id)
    end

    def constellation(id)
      if constellations.key?(id)
        return constellations[id]
      end

      constellations[id] = location(id)
    end

    def solar_system(id)
      if solar_systems.key?(id)
        return solar_systems[id]
      end

      solar_systems[id] = location(id)
    end

    def type(id)
      if types_cache.key?(id)
        return types_cache[id]
      end

      types_cache[id] = types.find { |type| type[:typeid] == id }.to_h
    end

    private

    def map_path
      File.join(dir, 'map.csv')
    end

    def types_path
      File.join(dir, 'types.csv')
    end

    def location(id)
      map.find { |location| location[:itemid] == id }.to_h
    end

    def types_cache
      @types_cache ||= {}
    end

    def constellations
      @constellations ||= {}
    end

    def regions
      @regions ||= {}
    end

    def solar_systems
      @solar_systems ||= {}
    end
  end
end
