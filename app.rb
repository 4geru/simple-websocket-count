require 'bundler/setup'
Bundler.require
require 'sinatra/reloader'
require 'sinatra-websocket'
require 'json'

require './models'


set :server, 'thin'
set :sockets, {}

before do
  Count.create(count: 0) if Count.all.size == 0
  Game.create(turn: 'black') if Game.all.size == 0
end

get '/' do
  @title = "Home"
  @rooms = Game.all
  erb :index
end

post '/create_room' do
  game = Game.create({:turn => 'white'})
  game.init
  redirect "/room/#{game.id}"
end

get '/room/:id' do
  @board_size = 7
  @title = "Room No.#{params[:id]}"
  @count = Count.first.count
  @room = Game.find(params[:id])
  @turn = @room.turn
  @stones = @room.stones
  erb :room
end

get '/websocket/count/:id' do |path|
  if request.websocket? then
    request.websocket do |ws|
      ws.onopen do # 接続を開始した時
        settings.sockets[path] ||= []
        settings.sockets[path] << ws # socketsリストに追加
      end
      ws.onmessage do |msg| # メッセージを受け取った時
        puts 'メッセージを受け取ったよ！'
        data = JSON.parse(msg)
        case data['type']
        when 'board' # 送られたデータが board データだったら
          # game = Game.find(path)
          # puts "y is #{data['pos'][0]}"
          # puts "x is #{data['pos'][1]}"
          pos = data['pos']
          data['turn'] = data['turn'] == 'black' ? 'white' : 'black'

          # Stone.create({game_id: path, x: pos[1], y: pos[0], color: game.turn})
          settings.sockets[path].each do |s| # メッセージを転送
            s.send({type: 'board', turn: data['turn'], pos: data['pos']}.to_json.to_s)
          end
          # game.turn  = game.turn == 'black' ? 'white' : 'black'
          # game.save
        end
      end
      ws.onclose do # メッセージを終了する時
        puts 'onclose'
        puts path
        settings.sockets[path].delete(ws) # socketsリストから削除
      end
    end
  end
end