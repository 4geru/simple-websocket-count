ActiveRecord::Base.establish_connection('sqlite3:db/development.db')

class Count < ActiveRecord::Base
end

class Game < ActiveRecord::Base
  has_many :stones
  has_many :users, through: :game_users
  has_many :game_users
  accepts_nested_attributes_for :game_users
  def init
    Stone.create({game_id: self.id, x: 4, y: 4, color: 'black'})
    Stone.create({game_id: self.id, x: 3, y: 3, color: 'black'})
    Stone.create({game_id: self.id, x: 4, y: 3, color: 'white'})
    Stone.create({game_id: self.id, x: 3, y: 4, color: 'white'})
  end

  def countColor
    black  = self.stones.where({color: 'black'}).count
    white = self.stones.where({color: 'white'}).count
    {:black => black, :white => white}
  end

  def joinUser(user_id)
    self.game_users.first.user_id == user_id || 
    self.game_users.second.nil? ? true : room.game_users.second.user_id == user_id
  end
end

class Stone < ActiveRecord::Base
  belongs_to :game
end

class User < ActiveRecord::Base
  has_secure_password
  validates :name,
    presence: true
  validates :password,
    length: {in: 5..10}
  has_many :games, through: :game_users
  has_many :game_users
end

class GameUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :game
end