class CreateGames < ActiveRecord::Migration[5.1]
  def change
    create_table :games do |t|
      t.string :turn   # black or white
      t.string :status # waiting, doing, finished
      t.integer :pass_count
      t.timestamps null: false
    end
  end
end
