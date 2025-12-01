class CreateKanjiExamples < ActiveRecord::Migration[8.0]
  def change
    create_table :kanji_examples do |t|
      t.string :kanji_id, null: false, limit: 10
      t.text :japanese, null: false
      t.string :reading, limit: 200
      t.text :meaning_english
      t.text :audio_opus
      t.text :audio_aac
      t.text :audio_ogg
      t.text :audio_mp3
      t.string :example_type, limit: 10, default: 'jisho'
      t.integer :display_order, default: 0

      t.timestamps
    end

    add_foreign_key :kanji_examples, :kanjis,
                    column: :kanji_id, primary_key: :character,
                    on_delete: :cascade
    add_index :kanji_examples, :kanji_id
    add_index :kanji_examples, :example_type
  end
end
