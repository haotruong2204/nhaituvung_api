# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_11_30_165857) do
  create_table "kanji_compositions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "kanji_id", limit: 10, null: false
    t.string "related_kanji", limit: 10, null: false
    t.string "relation_type", limit: 3, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kanji_id", "relation_type", "related_kanji"], name: "idx_unique_composition", unique: true
    t.index ["kanji_id"], name: "index_kanji_compositions_on_kanji_id"
    t.index ["related_kanji"], name: "index_kanji_compositions_on_related_kanji"
    t.index ["relation_type"], name: "index_kanji_compositions_on_relation_type"
  end

  create_table "kanji_examples", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "kanji_id", limit: 10, null: false
    t.text "japanese", null: false
    t.string "reading", limit: 200
    t.text "meaning_english"
    t.text "audio_opus"
    t.text "audio_aac"
    t.text "audio_ogg"
    t.text "audio_mp3"
    t.string "example_type", limit: 10, default: "jisho"
    t.integer "display_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["example_type"], name: "index_kanji_examples_on_example_type"
    t.index ["kanji_id"], name: "index_kanji_examples_on_kanji_id"
  end

  create_table "kanjis", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "character", limit: 10, null: false
    t.string "sino_vietnamese", limit: 50
    t.string "jlpt_level", limit: 5
    t.integer "stroke_count"
    t.json "kunyomi"
    t.json "onyomi"
    t.string "radical_character", limit: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "hanzi", limit: 100
    t.text "story"
    t.integer "grade"
    t.string "taught_in", limit: 20
    t.integer "newspaper_frequency_rank"
    t.text "meaning"
    t.string "radical_symbol", limit: 10
    t.text "radical_meaning"
    t.text "stroke_order_diagram_uri"
    t.text "stroke_order_svg_uri"
    t.text "stroke_order_gif_uri"
    t.text "jisho_uri"
    t.string "kodansha_ref", limit: 20
    t.string "classic_nelson_ref", limit: 20
    t.index ["character"], name: "index_kanjis_on_character", unique: true
    t.index ["grade"], name: "index_kanjis_on_grade"
    t.index ["jlpt_level"], name: "index_kanjis_on_jlpt_level"
    t.index ["newspaper_frequency_rank"], name: "index_kanjis_on_newspaper_frequency_rank"
    t.index ["stroke_count"], name: "index_kanjis_on_stroke_count"
  end

  create_table "textbook_references", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "kanji_id", limit: 10, null: false
    t.string "textbook_code", limit: 50, null: false
    t.string "chapter", limit: 20
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kanji_id"], name: "index_textbook_references_on_kanji_id"
    t.index ["textbook_code", "chapter"], name: "index_textbook_references_on_textbook_code_and_chapter"
  end

  add_foreign_key "kanji_compositions", "kanjis", primary_key: "character", on_delete: :cascade
  add_foreign_key "kanji_examples", "kanjis", primary_key: "character", on_delete: :cascade
  add_foreign_key "textbook_references", "kanjis", primary_key: "character", on_delete: :cascade
end
