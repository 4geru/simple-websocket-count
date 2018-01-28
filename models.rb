ActiveRecord::Base.establish_connection('sqlite3:db/development.db')

class Count < ActiveRecord::Base
end

class Game < ActiveRecord::Base
  has_many :stones

  def init
    Stone.create({game_id: self.id, x: 4, y: 4, color: 'black'})
    Stone.create({game_id: self.id, x: 3, y: 3, color: 'black'})
    Stone.create({game_id: self.id, x: 4, y: 3, color: 'white'})
    Stone.create({game_id: self.id, x: 3, y: 4, color: 'white'})
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
end