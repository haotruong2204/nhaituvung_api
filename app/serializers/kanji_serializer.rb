# frozen_string_literal: true

class KanjiSerializer
  include JSONAPI::Serializer

  set_type :kanji
  set_id :character

  attributes :character,
             :hanzi,
             :story,
             :grade,
             :stroke_count,
             :jlpt_level,
             :taught_in,
             :newspaper_frequency_rank,
             :meaning,
             :kunyomi,
             :onyomi,
             :radical_symbol,
             :radical_meaning,
             :stroke_order_diagram_uri,
             :stroke_order_svg_uri,
             :stroke_order_gif_uri,
             :jisho_uri,
             :kodansha_ref,
             :classic_nelson_ref

  has_many :kanji_examples
  has_many :textbook_references

  # Optional: Add computed attributes
  attribute :examples_count do |kanji|
    kanji.kanji_examples.count
  end

  attribute :component_kanjis, &:component_kanjis

  attribute :compound_kanjis, &:compound_kanjis
end
