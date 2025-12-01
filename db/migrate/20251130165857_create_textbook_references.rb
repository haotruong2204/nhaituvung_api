class CreateTextbookReferences < ActiveRecord::Migration[8.0]
  def change
    create_table :textbook_references do |t|
      t.string :kanji_id, null: false, limit: 10
      t.string :textbook_code, null: false, limit: 50
      t.string :chapter, limit: 20

      t.timestamps
    end

    add_foreign_key :textbook_references, :kanjis,
                    column: :kanji_id, primary_key: :character,
                    on_delete: :cascade
    add_index :textbook_references, :kanji_id
    add_index :textbook_references, [ :textbook_code, :chapter ]
  end
end
