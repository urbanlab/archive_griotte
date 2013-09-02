#!/usr/bin/dev ruby
#
#file handler used by Raspéomix scheduler

require 'json'
require 'find'

module Raspeomix

  class ScenarioHandler

    attr_reader :playing_media

    def initialize
      @key_path = "/dev/sda"
      @media_path = "/media/external"
      @scenarios = []
      @index = 0
      #mount key
      if Dir.entries(@media_path).size == 2 then
        %x{sudo mount #{@key_path} #{@media_path}}
      end
      @scenarios = retrieve_scenarios("/home/pi/dev/raspeomix/tests")
      @playing_scenario = choose_default(@scenarios)
      @playing_media = @playing_scenario[:medias][@index]
    end

    def retrieve_scenarios (path)
      paths = []
      scenarios = []
      Find.find(path) do |path|
        paths << path if path =~/.*\.json$/
      end
      paths.each do |path|
        json = File.read(path)
        scenarios << JSON.parse(json, :symbolize_names => true)
      end
      return scenarios
    end

    def choose_default(scenarios)
      default = scenarios[0]
      scenarios.each do |scenario|
        default = scenario if (scenario[:priority] < default[:priority])
      end
      return default
    end

    def load_next_media
      @index = (@index+1)%@playing_scenario[:media_count]
      @playing_media = @playing_scenario[:medias][@index]
    end

    def is_client_active?(client)
      if @playing_media[:type].to_s == client.to_s then
        return true
      else
        return false
      end
    end



  end
end

