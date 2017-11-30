require 'bundler/setup'
Bundler.require
require 'sinatra/reloader'
require 'sinatra-websocket'
require 'json'
require './models'


set :server, 'thin'
set :sockets, []
set :counts, []

before do
  if Count.all.size == 0
    Count.create(count: 0)
  end
end

get '/' do
  @count = Count.first.count
  erb :index
end

get '/websocket/count' do
  if request.websocket? then
    request.websocket do |ws|
      ws.onopen do
        c = Count.first
        c.count = c.count + 1
        c.save
        settings.sockets << ws
        puts settings.sockets.index(ws)
        puts ws
        settings.sockets.each do |s| # メッセージを転送
          s.send(Count.first.count.to_s)
        end
      end
      ws.onmessage do |msg|
      end
      ws.onclose do
        c = Count.first
        c.count = c.count - 1
        c.save
        settings.sockets.each do |s| # メッセージを転送
          puts settings.sockets.index(s) if s != ws
          s.send(Count.first.count.to_s)
        end
        settings.sockets.delete(ws)
      end
    end
  end
end