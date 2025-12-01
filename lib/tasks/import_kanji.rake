# frozen_string_literal: true

namespace :kanji do
  desc "Import kanji data from luyenkanji JSON files"
  task import: :environment do
    require "json"

    # Đường dẫn tới dự án luyenkanji
    LUYENKANJI_PATH = ENV["LUYENKANJI_PATH"] || "/Users/haotruong/Desktop/luyenkanji"

    puts "🚀 Starting import from #{LUYENKANJI_PATH}"

    # 1. Import composition data
    puts "\n📊 Importing composition data..."
    import_compositions

    # 2. Import kanji data
    puts "\n📚 Importing kanji data..."
    import_kanjis

    puts "\n✅ Import completed!"
    print_statistics
  end

  def import_compositions
    composition_file = File.join(ENV["LUYENKANJI_PATH"] || "/Users/haotruong/Desktop/luyenkanji", "data", "composition.json")
    composition = JSON.parse(File.read(composition_file))

    count = 0
    composition.each do |kanji, data|
      # Import 'in' relationships
      data["in"]&.each do |component|
        KanjiComposition.find_or_create_by!(
          kanji_id: kanji,
          related_kanji: component,
          relation_type: "in"
        )
        count += 1
      end

      # Import 'out' relationships
      data["out"]&.each do |compound|
        KanjiComposition.find_or_create_by!(
          kanji_id: kanji,
          related_kanji: compound,
          relation_type: "out"
        )
        count += 1
      end
    end

    puts "   ✓ Imported #{count} composition relationships"
  rescue StandardError => e
    puts "   ✗ Error importing compositions: #{e.message}"
  end

  def import_kanjis
    kanji_dir = File.join(ENV["LUYENKANJI_PATH"] || "/Users/haotruong/Desktop/luyenkanji", "data", "kanji")
    files = Dir.glob(File.join(kanji_dir, "*.json"))

    files.each_with_index do |file, index|
      data = JSON.parse(File.read(file))

      # Skip if not a proper kanji
      next if data["id"].nil? || data["id"].length > 10

      import_kanji(data)

      print "\r   Progress: #{index + 1}/#{files.count}" if (index % 10).zero?
    rescue StandardError => e
      puts "\n   ✗ Error importing #{file}: #{e.message}"
    end

    puts "\n   ✓ Imported #{Kanji.count} kanjis"
  end

  def import_kanji(data)
    jisho = data["jishoData"] || {}
    kanjialive = data["kanjialiveData"] || {}

    # Create or update Kanji
    kanji = Kanji.find_or_initialize_by(character: data["id"])

    kanji.assign_attributes(
      hanzi: data["hanzi"],
      story: data["story"],
      grade: kanjialive["grade"] || kanjialive.dig("references", "grade"),
      stroke_count: jisho["strokeCount"] || kanjialive["kstroke"],
      jlpt_level: jisho["jlptLevel"],
      taught_in: jisho["taughtIn"],
      newspaper_frequency_rank: jisho["newspaperFrequencyRank"]&.to_i,
      meaning: jisho["meaning"],
      kunyomi: jisho["kunyomi"] || [],
      onyomi: jisho["onyomi"] || [],
      radical_symbol: jisho.dig("radical", "symbol"),
      radical_meaning: jisho.dig("radical", "meaning"),
      stroke_order_diagram_uri: jisho["strokeOrderDiagramUri"],
      stroke_order_svg_uri: jisho["strokeOrderSvgUri"],
      stroke_order_gif_uri: jisho["strokeOrderGifUri"],
      jisho_uri: jisho["uri"],
      kodansha_ref: kanjialive.dig("references", "kodansha"),
      classic_nelson_ref: kanjialive.dig("references", "classic_nelson")
    )

    kanji.save!

    # Import examples
    import_examples(kanji, kanjialive, jisho)

    # Import textbook references
    import_textbooks(kanji, kanjialive)
  end

  def import_examples(kanji, kanjialive, jisho)
    # From KanjiAlive
    if kanjialive["examples"]
      kanjialive["examples"].each_with_index do |ex, idx|
        KanjiExample.find_or_create_by!(
          kanji_id: kanji.character,
          japanese: ex["japanese"]
        ) do |example|
          example.meaning_english = ex.dig("meaning", "english")
          example.audio_opus = ex.dig("audio", "opus")
          example.audio_aac = ex.dig("audio", "aac")
          example.audio_ogg = ex.dig("audio", "ogg")
          example.audio_mp3 = ex.dig("audio", "mp3")
          example.example_type = "onyomi"
          example.display_order = idx
        end
      end
    end

    # From Jisho - Onyomi examples
    if jisho["onyomiExamples"]
      jisho["onyomiExamples"].each_with_index do |ex, idx|
        KanjiExample.find_or_create_by!(
          kanji_id: kanji.character,
          japanese: ex["example"]
        ) do |example|
          example.reading = ex["reading"]
          example.meaning_english = ex["meaning"]
          example.example_type = "onyomi"
          example.display_order = idx + 100
        end
      end
    end

    # From Jisho - Kunyomi examples
    if jisho["kunyomiExamples"]
      jisho["kunyomiExamples"].each_with_index do |ex, idx|
        KanjiExample.find_or_create_by!(
          kanji_id: kanji.character,
          japanese: ex["example"]
        ) do |example|
          example.reading = ex["reading"]
          example.meaning_english = ex["meaning"]
          example.example_type = "kunyomi"
          example.display_order = idx + 200
        end
      end
    end
  end

  def import_textbooks(kanji, kanjialive)
    return unless kanjialive["txt_books"]

    kanjialive["txt_books"].each do |ref|
      TextbookReference.find_or_create_by!(
        kanji_id: kanji.character,
        textbook_code: ref["txt_bk"],
        chapter: ref["chapter"]
      )
    end
  end

  def print_statistics
    puts "\n📈 Statistics:"
    puts "   Kanjis: #{Kanji.count}"
    puts "   Examples: #{KanjiExample.count}"
    puts "   Compositions: #{KanjiComposition.count}"
    puts "   Textbook References: #{TextbookReference.count}"
  end
end
