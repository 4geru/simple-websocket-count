ActiveRecord::Base.establish_connection('sqlite3:db/development.db')

class Count < ActiveRecord::Base
end

class Game < ActiveRecord::Base
end
