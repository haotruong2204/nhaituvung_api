# frozen_string_literal: true

class KanjiExample < ApplicationRecord
  belongs_to :kanji, foreign_key: "kanji_id", primary_key: "character"

  # === VALIDATIONS ===
  validates :kanji_id, presence: true
  validates :japanese, presence: true
  validates :example_type, inclusion: { in: %w[onyomi kunyomi jisho] }

  # === SCOPES ===
  scope :onyomi_examples, -> { where(example_type: "onyomi") }
  scope :kunyomi_examples, -> { where(example_type: "kunyomi") }
  scope :ordered, -> { order(display_order: :asc, id: :asc) }

  # === INSTANCE METHODS ===
  def audio_url format = :mp3
    send("audio_#{format}")
  end

  def audio?
    audio_mp3.present?
  end
end
