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
  @turn = Game.first.turn
  @count = Count.first.count
  erb :index
end

def send_count
  settings.sockets.each do |s| # メッセージを転送
    c = Count.first
    s.send({type: 'count', count: c.count}.to_json.to_s)
  end
end

get '/websocket/count' do
  if request.websocket? then
    request.websocket do |ws|
      ws.onopen do
        settings.sockets << ws
        c = Count.first
        c.count += 1
        c.save
        send_count # 全体へ転送
      end
      ws.onmessage do |msg|
        puts 'get msg'
        data = JSON.parse(msg)
        case data['type']
        when 'open', 'close'
          send_count
        when 'board'
        end
      end
      ws.onclose do        
        c = Count.first
        c.count -= - 1
        c.save
        send_count # 全体へ転送
        settings.sockets.delete(ws)
      end
    end
  end
end