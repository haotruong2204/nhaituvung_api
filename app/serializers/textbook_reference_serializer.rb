# frozen_string_literal: true

class TextbookReferenceSerializer
  include JSONAPI::Serializer

  set_type :textbook_reference

  attributes :kanji_id, :textbook_code, :chapter

  belongs_to :kanji

  # Computed attribute
  attribute :textbook_name, &:textbook_name
end
