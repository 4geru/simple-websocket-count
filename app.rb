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
  User.create({name: 'なし'}) if User.all.size == 0
end

get '/' do
  @title = "Home"
  @rooms = Game.all
  erb :index
end

get '/joined/:user_id' do
  @title = "User Prifile"
  @user = User.find(params[:user_id])
  @rooms = GameUser.where({user_id: params[:user_id]}).map{|gu| gu.game }
  erb :index
end

post '/create_room' do
  game = Game.create({:turn => 'white', :status => 'waiting'})
  game.init
  GameUser.create({user_id: session[:user], game_id: game.id})
  redirect "/room/#{game.id}"
end

get '/room/:id' do
  @board_size = 7
  @title = "Room No.#{params[:id]}"
  @room = Game.find(params[:id])
  @turn_name = @room.turn
  @stones = @room.stones
  @users = GameUser.where({:game => params[:id]})
  user_idx = @room.turn == 'white' ? 0 : 1
  @user_id = GameUser.where({:game => params[:id]})[user_idx].user.id
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
          stone = Stone.find_or_initialize_by({game_id: path, x: pos[1], y: pos[0]})
          stone.update({game_id: path, x: pos[1], y: pos[0], color: game.turn})
          settings.sockets[path].each do |s| # メッセージを転送
            s.send({type: 'board', turn: data['turn'], pos: data['pos']}.to_json.to_s)
          end
        when 'turn' # 送られたデータが board データだったら
          game = Game.find(path)
          game.turn = game.turn == 'black' ? 'white' : 'black'
          game.pass_count = 0
          user = GameUser.where({:game => game.id})[(game.stones.count + 1) % 2].user

          settings.sockets[path].each do |s| # メッセージを転送
            s.send({type: 'turn', turn: game.turn, user_id: user.id}.to_json.to_s)
          end
          game.save
        when 'join'
          user = User.find(data['user_id'])
          GameUser.create({
            user_id: data['user_id'],
            game_id: data['room_id']
            })
          Game.find(path).update({status: 'doing'})

          settings.sockets[path].each do |s| # メッセージを転送
            puts s
            s.send({type: 'join', name: user.name, id: user.id}.to_json.to_s)
          end
        when 'pass'
          game = Game.find(path)
          game.pass_count += 1
          if(game.pass_count >= 2)
            game.status = 'finished'
            settings.sockets[path].each do |s| # メッセージを転送
              count_color = game.countColor
              winner = (count_color[:white] > count_color[:black] ? game.game_users.first : game.game_users.second)
              s.send({type: 'finished', winner: winner.user.name }.to_json.to_s)
            end            
          else
            game.turn = game.turn == 'black' ? 'white' : 'black'
            user = GameUser.where({:game => game.id})[(game.stones.count + 1) % 2].user
            settings.sockets[path].each do |s| # メッセージを転送
              s.send({type: 'turn', turn: game.turn, user_id: user.id}.to_json.to_s)
            end
          end
          game.save
        end
      end
      ws.onclose do # メッセージを終了する時
        puts path
        puts Game.last
        game = Game.find(path)
        white = game.game_users.first.user_id
        black = game.game_users.second ? game.game_users.second.user_id : nil
        puts black, white
        if game.status == 'waiting' # 黒が来ずログアウトした
          puts 'waiting'
          game.update({status: 'finished', turn: 'black'})
          user = User.first
          GameUser.create({user_id: user.id, game_id: game.id })
          settings.sockets[path].each do |s| # メッセージを転送
            s.send({type: 'finished', winner: user.name }.to_json.to_s)
          end
        elsif  black.nil? or # 2人目のユーザーが対戦していない
            session[:user].nil? or # 未ログイン
            (white != session[:user] and black != session[:user]) or # 対決ユーザー
            game['status'] == 'finished' # すでに終了している
          settings.sockets[path].delete(ws) # socketsリストから削除
        else
          if white == session[:user]
            game.update({status: 'finished', turn: 'black'})
          elsif black == session[:user]
            game.update({status: 'finished', turn: 'white'})
          end
          settings.sockets[path].delete(ws) # socketsリストから削除
          puts 'send message'
          winner = (game.turn == 'white' ? game.game_users.first : game.game_users.second)
          settings.sockets[path].each do |s| # メッセージを転送
            s.send({type: 'finished', winner: winner.user.name }.to_json.to_s)
          end
        end
      end
    end
  end
end