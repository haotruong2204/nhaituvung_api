# frozen_string_literal: true

class KanjiCompositionSerializer
  include JSONAPI::Serializer

  set_type :kanji_composition

  attributes :kanji_id, :related_kanji, :relation_type

  belongs_to :kanji
end
