require 'sinatra/base'

module Ntxt
  class Server

    attr_reader :file

    attr_reader :port

    def initialize(filename, port=8080)
      @filename = filename
      @port = port
    end

    def file
      File.new(@filename).read
    end

    def start
      Sinatra::Base.class_exec(self) do |svr|
        set :port, svr.port

        get '/file', :provides => ['text'] do
          svr.file
        end

        get '/' do
          svr.file
        end

        start!
      end
    end
  end
end