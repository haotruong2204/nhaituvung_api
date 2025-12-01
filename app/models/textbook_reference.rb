# frozen_string_literal: true

class TextbookReference < ApplicationRecord
  belongs_to :kanji, foreign_key: "kanji_id", primary_key: "character"

  # === VALIDATIONS ===
  validates :kanji_id, presence: true
  validates :textbook_code, presence: true

  # === SCOPES ===
  scope :by_textbook, ->(code) { where(textbook_code: code) }
  scope :by_chapter, ->(chapter) { where(chapter: chapter) }
  scope :ordered, -> { order(textbook_code: :asc, chapter: :asc) }

  # === CONSTANTS ===
  TEXTBOOK_NAMES = {
    "lesson" => "CIJ Lessons",
    "txtBasicKanji" => "Basic Kanji Book",
    "txtGenki" => "Genki",
    "txtAP" => "AP Japanese",
    "mosr" => "Remembering the Kanji",
    "cijr" => "CIJ Revised"
  }.freeze

  def textbook_name
    TEXTBOOK_NAMES[textbook_code] || textbook_code
  end
end
