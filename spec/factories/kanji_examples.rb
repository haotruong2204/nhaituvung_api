FactoryBot.define do
  factory :kanji_example do
    kanji_id { "MyString" }
    japanese { "MyText" }
    reading { "MyString" }
    meaning_english { "MyText" }
    audio_opus { "MyText" }
    audio_aac { "MyText" }
    audio_ogg { "MyText" }
    audio_mp3 { "MyText" }
    example_type { "MyString" }
    display_order { 1 }
  end
end
