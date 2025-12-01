# frozen_string_literal: true

class KanjiExampleSerializer
  include JSONAPI::Serializer

  set_type :kanji_example

  attributes :kanji_id,
             :japanese,
             :reading,
             :meaning_english,
             :audio_opus,
             :audio_aac,
             :audio_ogg,
             :audio_mp3,
             :example_type,
             :display_order

  belongs_to :kanji

  # Computed attribute
  attribute :audio, &:audio?
end
