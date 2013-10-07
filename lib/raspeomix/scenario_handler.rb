#!/usr/bin/dev ruby
#
#reads and interprets .json scenarios for Raspéomix
#TODO : handle scenario steps IDs

require 'json'
require 'find'

module Raspeomix

  #Class ScenarioHandler mounts key, finds scenarios, chooses one and interprets it
  #
  class ScenarioHandler

    attr_reader :current_step

    def initialize(scenario_path)
      @key_path = "/dev/sda"
      @media_path = "/media/external"
      @scenarios = []
      @index = 0
      @loopindex = 0
      #list all available scenarios in @scenarios
      @scenarios = retrieve_scenarios(scenario_path) #quickfix, a changer
      @playing_scenario = choose_default(@scenarios)

      #get first step in the .json file
      @current_step = @playing_scenario[:steps][@index]

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

    #returns next step of the .json scenario
    #
    def go_to_next_step
      #check if current step has to be played several times
      if (@current_step[:loop]>@loopindex)
        @loopindex += 1
      else
        @index = (@index+1)%(@playing_scenario[:steps].size)
        @loopindex = 0
      end
      @current_step = @playing_scenario[:steps][@index]
    end

    #returns an array of conditions needed to go on to next step
    #
    def next_step_conditions
      conditions = []
      case @current_step[:step]
      when "read_media"
        conditions << {:expected_client => @current_step[:mediatype], :condition => "stopped"}
      when "pause_reading"
        conditions << {:expected_client => @current_step[:mediatype], :condition => "stopped"}
      when "wait_for_event"
        conditions << {:expected_client => "#{@current_step[:path]}", :condition => check_event}
      end
      return conditions
    end

    def check_event
      return [@current_step[:value], @current_step[:threshold]]
    end



    def is_client_active?(client)
      if @current_step[:mediatype].to_s == client.to_s then
        return true
      else
        return false
      end
    end

  end
end
