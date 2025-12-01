class CreateKanjis < ActiveRecord::Migration[8.0]
  def change
    create_table :kanjis do |t|
      t.string :character, limit: 10, null: false
      t.string :sino_vietnamese, limit: 50
      t.string :jlpt_level, limit: 5
      t.integer :stroke_count
      t.json :kunyomi
      t.json :onyomi
      t.string :radical_character, limit: 10

      t.timestamps
    end

    add_index :kanjis, :character, unique: true
    add_index :kanjis, :jlpt_level
    add_index :kanjis, :stroke_count
  end
end
