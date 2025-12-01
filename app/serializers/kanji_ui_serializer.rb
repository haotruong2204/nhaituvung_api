# frozen_string_literal: true

# Serializer for UI format - matches the exact structure expected by the frontend
class KanjiUiSerializer
  def initialize kanji
    @kanji = kanji
  end

  def as_json
    {
      id: @kanji.character,
      hanzi: @kanji.hanzi,
      story: @kanji.story,
      jishoData: jisho_data,
      kanjialiveData: kanjialive_data
    }
  end

  private

  def jisho_data
    {
      meaning: @kanji.meaning,
      jlptLevel: @kanji.jlpt_level,
      strokeCount: @kanji.stroke_count,
      kunyomi: @kanji.kunyomi || [],
      onyomi: @kanji.onyomi || [],
      onyomiExamples: onyomi_examples,
      kunyomiExamples: kunyomi_examples,
      radical: {
        symbol: @kanji.radical_symbol,
        meaning: @kanji.radical_meaning
      }
    }
  end

  def kanjialive_data
    {
      examples: kanjialive_examples
    }
  end

  # Examples from KanjiAlive (with audio)
  def kanjialive_examples
    @kanji.kanji_examples
          .where(example_type: "onyomi")
          .where.not(audio_mp3: nil)
          .order(display_order: :asc)
          .limit(10)
          .map do |example|
      {
        japanese: example.japanese,
        meaning: {
          english: example.meaning_english
        },
        audio: {
          opus: example.audio_opus,
          aac: example.audio_aac,
          ogg: example.audio_ogg,
          mp3: example.audio_mp3
        }
      }
    end
  end

  # Onyomi examples from Jisho (no audio)
  def onyomi_examples
    @kanji.kanji_examples
          .where(example_type: "onyomi")
          .where(audio_mp3: nil)
          .order(display_order: :asc)
          .map do |example|
      {
        example: example.japanese,
        reading: example.reading,
        meaning: example.meaning_english
      }
    end
  end

  # Kunyomi examples from Jisho (no audio)
  def kunyomi_examples
    @kanji.kanji_examples
          .where(example_type: "kunyomi")
          .order(display_order: :asc)
          .map do |example|
      {
        example: example.japanese,
        reading: example.reading,
        meaning: example.meaning_english
      }
    end
  end
end
