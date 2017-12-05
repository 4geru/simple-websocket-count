require 'bundler/setup'
Bundler.require
require 'sinatra/reloader'
require 'sinatra-websocket'
require 'json'

require './models'


set :server, 'thin'
set :sockets, []

before do
  Count.create(count: 0) if Count.all.size == 0
  Game.create(turn: 'black') if Game.all.size == 0
end

get '/' do
  @turn = Game.first.turn
  @count = Count.first.count
  erb :index
end

get '/websocket/count' do
  if request.websocket? then
    request.websocket do |ws|
      ws.onopen do # 接続を開始した時
        settings.sockets << ws # socketsリストに追加
        c = Count.first # count の数を増やす
        c.count += 1
        c.save
        settings.sockets.each do |s| # 全体へメッセージを転送
          c = Count.first
          s.send({type: 'count', count: c.count}.to_json.to_s)
        end
      end
      ws.onmessage do |msg| # メッセージを受け取った時
        puts 'メッセージを受け取ったよ！'
        data = JSON.parse(msg)
        case data['type']
        when 'open', 'close' # 送られたデータが open or close データだったら
          settings.sockets.each do |s| # 全体へメッセージを転送
            c = Count.first
            s.send({type: 'count', count: c.count}.to_json.to_s)
          end
        when 'board' # 送られたデータが board データだったら
          turn  = data['turn'] == 'black' ? 'white' : 'black'
          puts data
          settings.sockets.each do |s| # メッセージを転送
            s.send({type: 'board', turn: turn, pos: data['pos']}.to_json.to_s)
          end
        end
      end
      ws.onclose do # メッセージを終了する時
        c = Count.first # count の数を減らす
        c.count -= 1
        c.save
        settings.sockets.each do |s| # 全体へメッセージを転送
          c = Count.first
          s.send({type: 'count', count: c.count}.to_json.to_s)
        end
        settings.sockets.delete(ws) # socketsリストから削除
      end
    end
  end
end