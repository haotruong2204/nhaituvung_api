class CreateKanjiCompositions < ActiveRecord::Migration[8.0]
  def change
    create_table :kanji_compositions do |t|
      t.string :kanji_id, null: false, limit: 10
      t.string :related_kanji, null: false, limit: 10
      t.string :relation_type, null: false, limit: 3  # 'in' or 'out'

      t.timestamps
    end

    add_foreign_key :kanji_compositions, :kanjis,
                    column: :kanji_id, primary_key: :character,
                    on_delete: :cascade
    add_index :kanji_compositions, :kanji_id
    add_index :kanji_compositions, :related_kanji
    add_index :kanji_compositions, :relation_type
    add_index :kanji_compositions, [ :kanji_id, :relation_type, :related_kanji ],
              unique: true, name: "idx_unique_composition"
  end
end
