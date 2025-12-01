# frozen_string_literal: true

class Kanji < ApplicationRecord
  self.primary_key = "character"

  # === ASSOCIATIONS ===
  has_many :kanji_examples, foreign_key: "kanji_id", dependent: :destroy
  has_many :textbook_references, foreign_key: "kanji_id", dependent: :destroy

  # Compositions
  has_many :in_compositions, -> { where(relation_type: "in") }, class_name: "KanjiComposition", foreign_key: "kanji_id"
  has_many :out_compositions, -> { where(relation_type: "out") },
           class_name: "KanjiComposition", foreign_key: "kanji_id"

  # === VALIDATIONS ===
  validates :character, presence: true, uniqueness: true
  validates :stroke_count, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :jlpt_level, inclusion: { in: %w[N1 N2 N3 N4 N5] }, allow_nil: true

  # === JSON COLUMNS ===
  # Note: kunyomi and onyomi are already JSON type in database
  # No need to serialize in Rails 8

  # === SCOPES ===
  scope :by_jlpt, ->(level) { where(jlpt_level: level) }
  scope :by_grade, ->(grade) { where(grade: grade) }
  scope :by_stroke_count, ->(count) { where(stroke_count: count) }
  scope :ordered_by_frequency, -> { order(newspaper_frequency_rank: :asc) }

  # === INSTANCE METHODS ===
  def to_param
    character
  end

  def to_s
    character
  end

  # Lấy các Kanji thành phần
  def component_kanjis
    in_compositions.pluck(:related_kanji)
  end

  # Lấy các Kanji sử dụng kanji này
  def compound_kanjis
    out_compositions.pluck(:related_kanji)
  end
end
