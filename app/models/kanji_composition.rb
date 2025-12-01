# frozen_string_literal: true

class KanjiComposition < ApplicationRecord
  belongs_to :kanji, foreign_key: "kanji_id", primary_key: "character"

  # === VALIDATIONS ===
  validates :kanji_id, presence: true
  validates :related_kanji, presence: true
  validates :relation_type, presence: true, inclusion: { in: %w[in out] }
  validates :kanji_id, uniqueness: { scope: [:relation_type, :related_kanji] }

  # === SCOPES ===
  scope :inbound, -> { where(relation_type: "in") }
  scope :outbound, -> { where(relation_type: "out") }
end
