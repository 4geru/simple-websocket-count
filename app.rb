require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'sinatra-websocket'
require 'json'
require './models'
require './src/login'

enable :sessions


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
  GameUser.create({user_id: session[:user], game_id: game.id})
  redirect "/room/#{game.id}"
end

post '/join_room' do
  user = User.find(session[:user])
  GameUser.create({
    user_id: session[:user],
    game_id: params['room_id']
    })
  settings.sockets[params['room_id']].each do |s| # メッセージを転送
    s.send({type: 'join', name: user.name}.to_json.to_s)
  end
  redirect "/room/#{params['room_id']}"
end

get '/room/:id' do
  @board_size = 7
  @title = "Room No.#{params[:id]}"
  @count = Count.first.count
  @room = Game.find(params[:id])
  @turn = @room.turn
  @stones = @room.stones
  @users = GameUser.where({:game => params[:id]})
  erb :room
end

get '/websocket/:id' do |path|
  if request.websocket? then
    request.websocket do |ws|
      ws.onopen do # 接続を開始した時
        settings.sockets[path] ||= []
        settings.sockets[path] << ws # socketsリストに追加
      end
      ws.onmessage do |msg| # メッセージを受け取った時
        puts 'メッセージを受け取ったよ！'
        data = JSON.parse(msg)
        puts data
        case data['type']
        when 'board' # 送られたデータが board データだったら
          game = Game.find(path)
          pos = data['pos']
          Stone.create({game_id: path, x: pos[1], y: pos[0], color: game.turn})
          settings.sockets[path].each do |s| # メッセージを転送
            s.send({type: 'board', turn: data['turn'], pos: data['pos']}.to_json.to_s)
          end
        when 'turn' # 送られたデータが board データだったら
          game = Game.find(path)
          game.turn = game.turn == 'black' ? 'white' : 'black'
          settings.sockets[path].each do |s| # メッセージを転送
            s.send({type: 'turn', turn: game.turn}.to_json.to_s)
          end
          game.save
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