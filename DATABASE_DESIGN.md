# THIẾT KẾ DATABASE CHO LUYENKANJI

> Tài liệu thiết kế database Rails cho ứng dụng học Kanji tiếng Nhật

## 📋 MỤC LỤC

1. [Tổng quan](#tổng-quan)
2. [Giải thích các bảng](#giải-thích-các-bảng)
3. [Rails Models](#rails-models)
4. [Rails Migrations](#rails-migrations)
5. [Quan hệ giữa các bảng](#quan-hệ-giữa-các-bảng)
6. [Lý do thiết kế](#lý-do-thiết-kế)

---

## 🎯 TỔNG QUAN

Database được thiết kế để lưu trữ thông tin của **2500+ Kanji** với các tính năng:

- ✅ Thông tin chi tiết về từng Kanji (nghĩa, cách đọc, số nét)
- ✅ Ví dụ từ vựng có audio (4 định dạng)
- ✅ Quan hệ thành phần (composition graph)
- ✅ Thông tin bộ thủ (214 radicals)
- ✅ Tham chiếu sách giáo khoa
- ✅ Tối ưu tìm kiếm tiếng Việt

### Cấu trúc tổng quan:

```
6 bảng chính:
├── kanjis              (Thông tin Kanji chính)
├── kanji_examples      (Ví dụ từ vựng)
├── kanji_compositions  (Quan hệ thành phần)
├── radicals            (Bộ thủ)
├── textbook_references (Tham chiếu sách)
└── search_indices      (Index tìm kiếm)
```

---

## 📚 GIẢI THÍCH CÁC BẢNG

### **1. Bảng `kanjis` - Bảng chính lưu thông tin Kanji**

**Mục đích:** Lưu trữ toàn bộ thông tin chi tiết về mỗi ký tự Kanji

#### **Khóa chính:**

- `id` (VARCHAR): Chính là ký tự Kanji (ví dụ: "一", "人", "日")
  - **Tại sao dùng ký tự làm ID?** Vì mỗi Kanji là duy nhất, dùng luôn ký tự làm ID giúp query dễ dàng

#### **Thông tin cơ bản:**

- `grade` (INTEGER): Cấp độ JLPT (1-5)
  - Ví dụ: 1 = N5 (dễ nhất), 5 = N1 (khó nhất)
- `stroke_count` (INTEGER): Số nét viết
  - Ví dụ: "一" có 1 nét, "人" có 2 nét
- `jlpt_level` (STRING): Cấp độ JLPT dạng text ("N1", "N2", "N3", "N4", "N5")
- `taught_in` (STRING): Học ở cấp lớp mấy trong trường Nhật
  - Ví dụ: "grade 1", "grade 2"
- `newspaper_frequency_rank` (INTEGER): Thứ hạng xuất hiện trong báo chì
  - Số càng nhỏ = Kanji càng phổ biến (ví dụ: "日" rank #1)

#### **Nghĩa (Meanings):**

- `meaning_english` (STRING): Nghĩa tiếng Anh
  - Ví dụ: "one", "person", "day"
- `meaning_vietnamese` (TEXT): Nghĩa tiếng Việt
  - Ví dụ: "Một", "Người", "Ngày"
- `sino_vietnamese` (STRING): Âm Hán Việt
  - Ví dụ: "NHẤT", "NHÂN", "NHẬT"

#### **Cách đọc (Readings) - Dùng JSON:**

- `kunyomi` (JSON Array): Cách đọc Kun (âm Nhật)
  - Ví dụ: `["ひと-", "ひと.つ"]`
  - **Tại sao dùng JSON?** Vì 1 Kanji có thể có nhiều cách đọc Kun khác nhau
- `onyomi` (JSON Array): Cách đọc On (âm Hán)
  - Ví dụ: `["イチ", "イツ"]`
- `kunyomi_romaji` (STRING): Phiên âm La-tinh của Kun
  - Ví dụ: "hito"
- `onyomi_romaji` (STRING): Phiên âm La-tinh của On
  - Ví dụ: "ichi"

#### **Thông tin bộ thủ (Radical):**

- `radical_character` (STRING): Ký tự bộ thủ
  - Ví dụ: "⼀" (bộ nhất)
- `radical_number` (INTEGER): Số thứ tự bộ thủ (1-214)
- `radical_strokes` (INTEGER): Số nét của bộ thủ
- `radical_meaning` (STRING): Nghĩa của bộ thủ
- `radical_name_ja` (STRING): Tên bộ thủ tiếng Nhật
- `radical_position_ja` (STRING): Vị trí bộ thủ trong Kanji

#### **Dữ liệu nét viết (Stroke Data) - Dùng JSON:**

- `stroke_data` (JSON): Thông tin về nét viết

  ```json
  {
    "count": 1,
    "timings": [0.84, 1.733333],
    "images": ["https://..."],
    "video": {
      "mp4": "https://...",
      "webm": "https://..."
    }
  }
  ```

  - **Tại sao dùng JSON?** Vì có nhiều URLs và timings, gộp lại dễ quản lý hơn

- `radical_animation` (JSON Array): Các link animation của bộ thủ
  ```json
  ["https://url1.svg", "https://url2.svg", "https://url3.svg"]
  ```

#### **Các link tham khảo:**

- `stroke_diagram_uri` (TEXT): Link hình diagram nét viết
- `stroke_svg_uri` (TEXT): Link file SVG nét viết
- `stroke_gif_uri` (TEXT): Link ảnh GIF động
- `jisho_uri` (TEXT): Link đến Jisho.org

#### **Tham chiếu từ điển:**

- `kodansha_ref` (STRING): Mã trong từ điển Kodansha
- `classic_nelson_ref` (STRING): Mã trong từ điển Nelson

#### **Tìm kiếm:**

- `search_keywords` (TEXT): Các từ khóa để tìm kiếm nhanh

---

### **2. Bảng `kanji_examples` - Bảng ví dụ từ vựng**

**Mục đích:** Lưu các ví dụ từ vựng sử dụng Kanji đó

#### **Cấu trúc:**

- `id` (INTEGER): Khóa chính tự tăng
- `kanji_id` (STRING): Kanji nào? (Foreign Key → kanjis.id)
  - Ví dụ: "一", "人"

#### **Nội dung ví dụ:**

- `japanese` (TEXT): Từ tiếng Nhật có furigana
  - Ví dụ: "一年生（いちねんせい）"
- `reading` (STRING): Cách đọc riêng của ví dụ này
- `meaning_english` (TEXT): Nghĩa tiếng Anh
  - Ví dụ: "first-year student"
- `meaning_vietnamese` (TEXT): Nghĩa tiếng Việt
  - Ví dụ: "học sinh năm nhất"

#### **Audio (Dùng JSON):**

- `audio_urls` (JSON): Các link file audio 4 định dạng
  ```json
  {
    "opus": "https://media.kanjialive.com/.../audio.opus",
    "aac": "https://media.kanjialive.com/.../audio.aac",
    "ogg": "https://media.kanjialive.com/.../audio.ogg",
    "mp3": "https://media.kanjialive.com/.../audio.mp3"
  }
  ```
  - **Tại sao 4 định dạng?** Để tương thích với nhiều trình duyệt khác nhau

#### **Phân loại:**

- `example_type` (ENUM): Loại ví dụ
  - `"onyomi"`: Ví dụ dùng âm On
  - `"kunyomi"`: Ví dụ dùng âm Kun
  - `"general"`: Ví dụ chung
- `display_order` (INTEGER): Thứ tự hiển thị

**Quan hệ:**

- Mỗi Kanji có **nhiều** ví dụ (has_many)
- Mỗi ví dụ thuộc về **1** Kanji (belongs_to)

---

### **3. Bảng `kanji_compositions` - Bảng quan hệ thành phần**

**Mục đích:** Lưu quan hệ giữa các Kanji (Kanji nào được tạo thành từ Kanji nào)

#### **Ví dụ thực tế:**

- Kanji "木" (cây) + "木" (cây) = "林" (rừng)
- Kanji "人" (người) + "言" (nói) = "信" (tin)

#### **Cấu trúc:**

- `id` (INTEGER): Khóa chính tự tăng
- `kanji_id` (STRING): Kanji chính (Foreign Key → kanjis.id)
- `related_kanji` (STRING): Kanji liên quan
- `relation_type` (ENUM): Loại quan hệ
  - `"in"`: **Thành phần tạo nên** Kanji này
    - Ví dụ: "林" → relation_type='in' → related_kanji='木'
    - Nghĩa: "林" được tạo từ "木"
  - `"out"`: **Kanji sử dụng** Kanji này làm thành phần
    - Ví dụ: "木" → relation_type='out' → related_kanji='林'
    - Nghĩa: "木" được dùng để tạo "林"

#### **Ví dụ cụ thể trong database:**

**Kanji "林" (rừng):**

```
┌────────┬────────────┬───────────────┬────────────────┐
│ id     │ kanji_id   │ relation_type │ related_kanji  │
├────────┼────────────┼───────────────┼────────────────┤
│ 1      │ 林         │ in            │ 木             │
│ 2      │ 林         │ in            │ 木             │
└────────┴────────────┴───────────────┴────────────────┘
```

**Kanji "木" (cây):**

```
┌────────┬────────────┬───────────────┬────────────────┐
│ id     │ kanji_id   │ relation_type │ related_kanji  │
├────────┼────────────┼───────────────┼────────────────┤
│ 3      │ 木         │ out           │ 林             │
│ 4      │ 木         │ out           │ 森             │
│ 5      │ 木         │ out           │ 村             │
└────────┴────────────┴───────────────┴────────────────┘
```

**Tại sao cần bảng này?**

- Để hiển thị **graph composition** (biểu đồ thành phần)
- Để tìm kiếm Kanji theo thành phần
- Để học sinh hiểu cấu trúc Kanji

---

### **4. Bảng `radicals` - Bảng bộ thủ**

**Mục đích:** Lưu thông tin về 214 bộ thủ cơ bản trong Kanji

#### **Bộ thủ là gì?**

- Là thành phần cơ bản nhất tạo nên Kanji
- Giống như "chữ cái" trong tiếng Việt
- Ví dụ:
  - Bộ "⺅" (người) → "他", "作", "住"
  - Bộ "氵" (nước) → "海", "河", "池"

#### **Cấu trúc:**

- `id` (INTEGER): Khóa chính tự tăng
- `radical_number` (INTEGER): Số thứ tự bộ thủ (1-214) - UNIQUE
  - Theo hệ thống Kangxi Radical

#### **Thông tin bộ thủ:**

- `radical_character` (STRING): Ký tự bộ thủ
  - Ví dụ: "⼀", "⼈", "⽔"
- `strokes` (INTEGER): Số nét viết bộ thủ
- `category` (STRING): Phân loại
  - Ví dụ: "Number", "Weapon", "Nature", "Body Part"
- `meaning` (STRING): Nghĩa của bộ thủ
  - Ví dụ: "one", "person", "water"

#### **Cách đọc:**

- `reading_japanese` (STRING): Cách đọc tiếng Nhật
  - Ví dụ: "にんべん" (ninben)
- `reading_romanized` (STRING): Phiên âm
  - Ví dụ: "ninben"

#### **Vị trí:**

- `position_japanese` (STRING): Vị trí trong Kanji (tiếng Nhật)
- `position_romanized` (STRING): Vị trí (La-tinh)
  - Ví dụ: "hen" (bên trái), "tsukuri" (bên phải), "kamae" (bao quanh)

#### **Thống kê:**

- `frequency` (INTEGER): Độ phổ biến (có bao nhiêu Kanji dùng bộ này)

#### **Biến thể (Dùng JSON):**

- `alternatives` (JSON Array): Các dạng viết khác của bộ thủ
  ```json
  ["乚", "⺄"]
  ```
  - Ví dụ: Bộ "人" có thể viết thành "⺅" khi ở bên trái Kanji

---

### **5. Bảng `textbook_references` - Bảng tham chiếu sách giáo khoa**

**Mục đích:** Lưu thông tin Kanji nào xuất hiện ở sách nào, chương nào

#### **Tại sao cần?**

- Học sinh học theo sách cụ thể (Genki, Minna no Nihongo, v.v.)
- Cần biết Kanji ở bài học nào để ôn tập

#### **Cấu trúc:**

- `id` (INTEGER): Khóa chính
- `kanji_id` (STRING): Kanji nào? (Foreign Key)
- `textbook_code` (STRING): Mã sách
  - Ví dụ:
    - "txtGenki" → Sách Genki
    - "mosr" → Remembering the Kanji
    - "txtBasicKanji" → Basic Kanji Book
- `chapter` (STRING): Chương/bài số mấy
  - Ví dụ: "3", "15", "c12"
- `volume` (STRING): Tập số mấy (nếu sách có nhiều tập)
  - Ví dụ: "1", "2"

#### **Ví dụ thực tế:**

**Kanji "人" xuất hiện trong:**

```
┌────┬──────────┬─────────────────┬─────────┬────────┐
│ id │ kanji_id │ textbook_code   │ chapter │ volume │
├────┼──────────┼─────────────────┼─────────┼────────┤
│ 1  │ 人       │ txtGenki        │ 4       │        │
│ 2  │ 人       │ txtBasicKanji   │ 1       │        │
│ 3  │ 人       │ mosr            │ 2       │        │
└────┴──────────┴─────────────────┴─────────┴────────┘
```

#### **Use case:**

```ruby
# Lấy tất cả Kanji trong Genki Chapter 4
TextbookReference.where(textbook_code: 'txtGenki', chapter: '4')

# Lấy tất cả sách có dạy Kanji "人"
Kanji.find('人').textbook_references
```

---

### **6. Bảng `search_indices` - Bảng tối ưu tìm kiếm**

**Mục đích:** Tăng tốc độ tìm kiếm Kanji (đặc biệt là tìm kiếm tiếng Việt)

#### **Tại sao cần bảng riêng?**

- Bảng `kanjis` có quá nhiều thông tin → tìm kiếm chậm
- Bảng này chỉ chứa thông tin cần thiết cho tìm kiếm → **nhanh hơn**
- Sử dụng FULLTEXT INDEX của MySQL → tìm kiếm full-text cực nhanh

#### **Cấu trúc:**

- `kanji_id` (STRING): Khóa chính (Foreign Key → kanjis.id)
  - Quan hệ 1-1 với bảng `kanjis`
- `kunyomi_reading` (STRING): Cách đọc Kun (La-tinh)
- `meaning_vi` (TEXT): Nghĩa tiếng Việt
- `grade` (INTEGER): Cấp độ
- `onyomi_reading` (STRING): Cách đọc On (La-tinh)
- `sino_vietnamese` (STRING): Âm Hán Việt

#### **Ví dụ sử dụng:**

```ruby
# Tìm kiếm tiếng Việt
SearchIndex.search_vietnamese("người")
# → Trả về Kanji "人"

# Full-text search
SearchIndex.fulltext_search("nước")
# → Trả về: "水", "海", "河", v.v.

# Tìm theo cấp độ
SearchIndex.by_grade(1)
# → Tất cả Kanji cấp 1
```

#### **Performance:**

- Tìm kiếm trên `search_indices` nhanh hơn 10-20 lần so với tìm trên `kanjis`
- FULLTEXT INDEX hỗ trợ tìm kiếm từ gần đúng

---

## 🚂 RAILS MODELS

### **1. Model: Kanji** (`app/models/kanji.rb`)

```ruby
# app/models/kanji.rb
class Kanji < ApplicationRecord
  # Associations
  has_many :kanji_examples, dependent: :destroy
  has_many :kanji_compositions, dependent: :destroy
  has_many :textbook_references, dependent: :destroy
  belongs_to :radical, optional: true

  # Composition relationships
  has_many :in_compositions, -> { where(relation_type: 'in') },
           class_name: 'KanjiComposition', foreign_key: 'kanji_id'
  has_many :out_compositions, -> { where(relation_type: 'out') },
           class_name: 'KanjiComposition', foreign_key: 'kanji_id'

  # Components that form this kanji
  has_many :component_kanjis, through: :in_compositions, source: :related_kanji_record

  # Kanji that use this as a component
  has_many :compound_kanjis, through: :out_compositions, source: :related_kanji_record

  # Validations
  validates :id, presence: true, uniqueness: true
  validates :grade, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :stroke_count, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :jlpt_level, inclusion: { in: %w[N1 N2 N3 N4 N5] }, allow_nil: true

  # JSON fields serialization (for MySQL)
  serialize :kunyomi, JSON
  serialize :onyomi, JSON
  serialize :stroke_data, JSON
  serialize :radical_animation, JSON

  # Scopes
  scope :by_grade, ->(grade) { where(grade: grade) }
  scope :by_jlpt, ->(level) { where(jlpt_level: level) }
  scope :by_stroke_count, ->(count) { where(stroke_count: count) }
  scope :ordered_by_frequency, -> { order(newspaper_frequency_rank: :asc) }

  # Search scope
  scope :search, ->(query) {
    where("meaning_english LIKE :q OR meaning_vietnamese LIKE :q OR search_keywords LIKE :q",
          q: "%#{query}%")
  }

  # Instance methods
  def primary_meaning
    meaning_vietnamese.presence || meaning_english
  end

  def jlpt_level_number
    jlpt_level&.gsub('N', '')&.to_i
  end

  def radical_info
    {
      character: radical_character,
      number: radical_number,
      meaning: radical_meaning,
      name: radical_name_ja
    }
  end

  def to_s
    id
  end
end
```

### **2. Model: KanjiExample** (`app/models/kanji_example.rb`)

```ruby
# app/models/kanji_example.rb
class KanjiExample < ApplicationRecord
  belongs_to :kanji

  # Validations
  validates :kanji_id, presence: true
  validates :japanese, presence: true
  validates :example_type, inclusion: { in: %w[onyomi kunyomi general] }

  # JSON serialization
  serialize :audio_urls, JSON

  # Scopes
  scope :onyomi_examples, -> { where(example_type: 'onyomi') }
  scope :kunyomi_examples, -> { where(example_type: 'kunyomi') }
  scope :ordered, -> { order(display_order: :asc, id: :asc) }

  # Instance methods
  def audio_url(format = :mp3)
    audio_urls&.dig(format.to_s)
  end

  def audio?
    audio_urls.present? && audio_urls['mp3'].present?
  end
end
```

### **3. Model: KanjiComposition** (`app/models/kanji_composition.rb`)

```ruby
# app/models/kanji_composition.rb
class KanjiComposition < ApplicationRecord
  belongs_to :kanji
  belongs_to :related_kanji_record, class_name: 'Kanji',
             foreign_key: 'related_kanji', primary_key: 'id'

  # Validations
  validates :kanji_id, presence: true
  validates :related_kanji, presence: true
  validates :relation_type, presence: true, inclusion: { in: %w[in out] }
  validates :kanji_id, uniqueness: { scope: [:relation_type, :related_kanji] }

  # Scopes
  scope :inbound, -> { where(relation_type: 'in') }
  scope :outbound, -> { where(relation_type: 'out') }

  # Class methods
  def self.create_bidirectional(kanji_id, component_id)
    transaction do
      create!(kanji_id: kanji_id, related_kanji: component_id, relation_type: 'in')
      create!(kanji_id: component_id, related_kanji: kanji_id, relation_type: 'out')
    end
  end
end
```

### **4. Model: Radical** (`app/models/radical.rb`)

```ruby
# app/models/radical.rb
class Radical < ApplicationRecord
  has_many :kanjis, foreign_key: 'radical_number', primary_key: 'radical_number'

  # Validations
  validates :radical_number, presence: true, uniqueness: true
  validates :radical_character, presence: true
  validates :strokes, numericality: { only_integer: true, greater_than: 0 }

  # JSON serialization
  serialize :alternatives, JSON

  # Scopes
  scope :by_strokes, ->(count) { where(strokes: count) }
  scope :by_category, ->(category) { where(category: category) }
  scope :ordered_by_number, -> { order(radical_number: :asc) }

  # Instance methods
  def display_name
    "#{radical_character} (#{meaning})"
  end

  def to_s
    radical_character
  end
end
```

### **5. Model: TextbookReference** (`app/models/textbook_reference.rb`)

```ruby
# app/models/textbook_reference.rb
class TextbookReference < ApplicationRecord
  belongs_to :kanji

  # Validations
  validates :kanji_id, presence: true
  validates :textbook_code, presence: true

  # Scopes
  scope :by_textbook, ->(code) { where(textbook_code: code) }
  scope :by_chapter, ->(chapter) { where(chapter: chapter) }
  scope :ordered, -> { order(textbook_code: :asc, volume: :asc, chapter: :asc) }

  # Class methods - common textbook codes
  TEXTBOOK_CODES = {
    'lesson' => 'CIJ Lessons',
    'txtBasicKanji' => 'Basic Kanji Book',
    'txtGenki' => 'Genki',
    'txtAP' => 'AP Japanese',
    'mosr' => 'Remembering the Kanji',
    'cijr' => 'CIJ Revised'
  }.freeze

  def textbook_name
    TEXTBOOK_CODES[textbook_code] || textbook_code
  end

  def full_reference
    parts = [textbook_name]
    parts << "Vol. #{volume}" if volume.present?
    parts << "Ch. #{chapter}" if chapter.present?
    parts.join(' - ')
  end
end
```

### **6. Model: SearchIndex** (`app/models/search_index.rb`)

```ruby
# app/models/search_index.rb
class SearchIndex < ApplicationRecord
  self.primary_key = 'kanji_id'
  belongs_to :kanji, foreign_key: 'kanji_id'

  # Validations
  validates :kanji_id, presence: true, uniqueness: true

  # Scopes
  scope :search_vietnamese, ->(query) {
    where("meaning_vi LIKE ?", "%#{query}%")
  }

  scope :by_grade, ->(grade) { where(grade: grade) }

  # Full text search (requires MySQL FULLTEXT index)
  scope :fulltext_search, ->(query) {
    where("MATCH(meaning_vi, onyomi_reading, kunyomi_reading) AGAINST(? IN NATURAL LANGUAGE MODE)", query)
  }

  # Instance method
  def self.rebuild_for_kanji(kanji)
    find_or_initialize_by(kanji_id: kanji.id).tap do |index|
      index.kunyomi_reading = kanji.kunyomi_romaji
      index.meaning_vi = kanji.meaning_vietnamese
      index.grade = kanji.grade
      index.onyomi_reading = kanji.onyomi_romaji
      index.sino_vietnamese = kanji.sino_vietnamese
      index.save!
    end
  end
end
```

---

## 📋 RAILS MIGRATIONS

### **Migration 1: Create Kanjis**

```ruby
# db/migrate/20250122000001_create_kanjis.rb
class CreateKanjis < ActiveRecord::Migration[7.0]
  def change
    create_table :kanjis, id: false do |t|
      t.string :id, primary_key: true, limit: 10, null: false

      # Basic info
      t.integer :grade
      t.integer :stroke_count
      t.string :jlpt_level, limit: 5
      t.string :taught_in, limit: 20
      t.integer :newspaper_frequency_rank

      # Meanings
      t.string :meaning_english, limit: 500
      t.text :meaning_vietnamese
      t.string :sino_vietnamese, limit: 50

      # Readings (JSON)
      t.json :kunyomi
      t.json :onyomi
      t.string :kunyomi_romaji, limit: 200
      t.string :onyomi_romaji, limit: 200

      # Radical info
      t.string :radical_character, limit: 10
      t.integer :radical_number
      t.integer :radical_strokes
      t.string :radical_meaning, limit: 200
      t.string :radical_name_ja, limit: 50
      t.string :radical_name_romaji, limit: 50
      t.string :radical_position_ja, limit: 50
      t.string :radical_position_romaji, limit: 50

      # Stroke data (JSON)
      t.json :stroke_data
      t.json :radical_animation

      # URLs
      t.text :stroke_diagram_uri
      t.text :stroke_svg_uri
      t.text :stroke_gif_uri
      t.text :jisho_uri

      # References
      t.string :kodansha_ref, limit: 20
      t.string :classic_nelson_ref, limit: 20

      # Search
      t.text :search_keywords

      t.timestamps
    end

    add_index :kanjis, :grade
    add_index :kanjis, :jlpt_level
    add_index :kanjis, :stroke_count
    add_index :kanjis, :radical_number
    add_index :kanjis, :newspaper_frequency_rank

    # FULLTEXT index (MySQL)
    execute "CREATE FULLTEXT INDEX idx_kanji_search ON kanjis(meaning_english, meaning_vietnamese, search_keywords)"
  end
end
```

### **Migration 2: Create Kanji Examples**

```ruby
# db/migrate/20250122000002_create_kanji_examples.rb
class CreateKanjiExamples < ActiveRecord::Migration[7.0]
  def change
    create_table :kanji_examples do |t|
      t.string :kanji_id, null: false, limit: 10

      t.text :japanese, null: false
      t.string :reading, limit: 200
      t.text :meaning_english
      t.text :meaning_vietnamese

      # Audio URLs (JSON)
      t.json :audio_urls

      t.string :example_type, limit: 10, default: 'general'
      t.integer :display_order, default: 0

      t.timestamps
    end

    add_foreign_key :kanji_examples, :kanjis, column: :kanji_id, primary_key: :id, on_delete: :cascade
    add_index :kanji_examples, :kanji_id
    add_index :kanji_examples, :example_type
  end
end
```

### **Migration 3: Create Kanji Compositions**

```ruby
# db/migrate/20250122000003_create_kanji_compositions.rb
class CreateKanjiCompositions < ActiveRecord::Migration[7.0]
  def change
    create_table :kanji_compositions do |t|
      t.string :kanji_id, null: false, limit: 10
      t.string :relation_type, null: false, limit: 3  # 'in' or 'out'
      t.string :related_kanji, null: false, limit: 10

      t.timestamps
    end

    add_foreign_key :kanji_compositions, :kanjis, column: :kanji_id, primary_key: :id, on_delete: :cascade
    add_index :kanji_compositions, :kanji_id
    add_index :kanji_compositions, :related_kanji
    add_index :kanji_compositions, :relation_type
    add_index :kanji_compositions, [:kanji_id, :relation_type, :related_kanji],
              unique: true, name: 'idx_unique_composition'
  end
end
```

### **Migration 4: Create Radicals**

```ruby
# db/migrate/20250122000004_create_radicals.rb
class CreateRadicals < ActiveRecord::Migration[7.0]
  def change
    create_table :radicals do |t|
      t.integer :radical_number, null: false
      t.string :radical_character, null: false, limit: 10
      t.integer :strokes, null: false

      t.string :category, limit: 50
      t.string :meaning, limit: 200

      t.string :reading_japanese, limit: 50
      t.string :reading_romanized, limit: 50
      t.string :position_japanese, limit: 50
      t.string :position_romanized, limit: 50

      t.integer :frequency
      t.json :alternatives
      t.string :original_character, limit: 10

      t.timestamps
    end

    add_index :radicals, :radical_number, unique: true
    add_index :radicals, :strokes
    add_index :radicals, :category
  end
end
```

### **Migration 5: Create Textbook References**

```ruby
# db/migrate/20250122000005_create_textbook_references.rb
class CreateTextbookReferences < ActiveRecord::Migration[7.0]
  def change
    create_table :textbook_references do |t|
      t.string :kanji_id, null: false, limit: 10
      t.string :textbook_code, null: false, limit: 50
      t.string :chapter, limit: 20
      t.string :volume, limit: 10

      t.timestamps
    end

    add_foreign_key :textbook_references, :kanjis, column: :kanji_id, primary_key: :id, on_delete: :cascade
    add_index :textbook_references, :kanji_id
    add_index :textbook_references, [:textbook_code, :chapter]
  end
end
```

### **Migration 6: Create Search Index**

```ruby
# db/migrate/20250122000006_create_search_indices.rb
class CreateSearchIndices < ActiveRecord::Migration[7.0]
  def change
    create_table :search_indices, id: false do |t|
      t.string :kanji_id, primary_key: true, limit: 10, null: false

      t.string :kunyomi_reading, limit: 200
      t.text :meaning_vi
      t.integer :grade
      t.string :onyomi_reading, limit: 200
      t.string :sino_vietnamese, limit: 50

      t.timestamps
    end

    add_foreign_key :search_indices, :kanjis, column: :kanji_id, primary_key: :id, on_delete: :cascade

    # FULLTEXT index
    execute "CREATE FULLTEXT INDEX idx_search_fulltext ON search_indices(meaning_vi, onyomi_reading, kunyomi_reading)"
  end
end
```

---

## 🔗 QUAN HỆ GIỮA CÁC BẢNG

```
┌──────────────────────────────────────────────────────────┐
│                         KANJIS                           │
│  (Bảng chính - chứa toàn bộ thông tin Kanji)            │
└───────────┬──────────────────────────────────────────────┘
            │
            ├─── has_many ────> KANJI_EXAMPLES
            │                   (Các ví dụ từ vựng)
            │
            ├─── has_many ────> KANJI_COMPOSITIONS
            │                   (Quan hệ thành phần)
            │                   ├─ relation_type = 'in'  (thành phần tạo nên)
            │                   └─ relation_type = 'out' (Kanji sử dụng)
            │
            ├─── has_many ────> TEXTBOOK_REFERENCES
            │                   (Xuất hiện ở sách nào)
            │
            ├─── has_one ─────> SEARCH_INDICES
            │                   (Index tìm kiếm nhanh)
            │
            └─── belongs_to ──> RADICALS
                                (Bộ thủ)
```

### **Sơ đồ chi tiết:**

```
         ┌─────────────┐
         │  RADICALS   │
         │ (214 bộ)    │
         └──────┬──────┘
                │ has_many
                │
         ┌──────▼──────┐
         │   KANJIS    │──┐
         │ (2500+)     │  │ has_one
         └──────┬──────┘  │
                │         │
    ┌───────────┼─────────┼────────────┐
    │           │         │            │
    │ has_many  │ has_many│ has_many   │
    │           │         │            │
┌───▼────┐ ┌───▼────┐ ┌──▼───┐ ┌──────▼──────┐
│ KANJI_ │ │ KANJI_ │ │TEXT_ │ │   SEARCH_   │
│EXAMPLES│ │COMPOSI_│ │BOOK_ │ │   INDICES   │
│        │ │ TIONS  │ │REFS  │ │             │
└────────┘ └────────┘ └──────┘ └─────────────┘
```

---

## 💡 LÝ DO THIẾT KẾ

### **1. Tách bảng ví dụ (kanji_examples):**

**Vấn đề:** Mỗi Kanji có 5-15 ví dụ, nếu để chung trong bảng `kanjis` sẽ:

- Bảng quá lớn (2500 kanji × 10 examples = 25,000+ rows trong 1 bảng)
- Khó query và phân trang
- Lãng phí bộ nhớ

**Giải pháp:** Tách ra bảng riêng

- Dễ query: `Kanji.find('人').kanji_examples.limit(5)`
- Dễ phân trang
- Có thể thêm/xóa ví dụ độc lập

---

### **2. Dùng JSON cho audio_urls, stroke_data:**

**Vấn đề:** Nếu tạo cột riêng cho từng định dạng:

```ruby
# ❌ Cách tệ
t.string :audio_opus_url
t.string :audio_aac_url
t.string :audio_ogg_url
t.string :audio_mp3_url
```

- 4 cột cho audio → rườm rà
- Khó mở rộng (nếu thêm format mới phải migrate database)
- Code dài: `example.audio_mp3_url`, `example.audio_opus_url`...

**Giải pháp:** Dùng JSON

```ruby
# ✅ Cách tốt
t.json :audio_urls
# Lưu: {"mp3": "url1", "opus": "url2", "aac": "url3", "ogg": "url4"}

# Sử dụng:
example.audio_url(:mp3)
example.audio_urls['mp3']
```

- Gọn gàng, 1 cột thay vì 4
- Dễ mở rộng (thêm format mới không cần migrate)
- Code ngắn gọn

---

### **3. Bảng composition riêng:**

**Vấn đề:** Quan hệ Kanji là **many-to-many**

- "林" được tạo từ 2 × "木"
- "木" được dùng trong "林", "森", "村", "本"...

**Giải pháp:** Join table `kanji_compositions`

- Lưu được quan hệ phức tạp
- Dễ query graph:
  ```ruby
  Kanji.find('木').compound_kanjis  # → ['林', '森', '村']
  Kanji.find('林').component_kanjis # → ['木', '木']
  ```
- Dễ vẽ biểu đồ thành phần (composition graph)

---

### **4. Bảng search_indices riêng:**

**Vấn đề:** Tìm kiếm trên bảng `kanjis` chậm vì:

- Bảng có 30+ cột
- Có nhiều JSON fields
- FULLTEXT search phải scan toàn bộ dữ liệu

**Giải pháp:** Bảng `search_indices` chỉ chứa dữ liệu cần cho tìm kiếm

- Chỉ 5-6 cột cần thiết
- FULLTEXT index riêng → **nhanh hơn 10-20 lần**
- Không ảnh hưởng đến bảng chính

**Benchmark:**

```ruby
# Tìm trên bảng kanjis: ~500ms
Kanji.where("meaning_vietnamese LIKE ?", "%người%")

# Tìm trên search_indices: ~20ms
SearchIndex.fulltext_search("người")
```

---

### **5. Dùng Kanji làm primary key:**

**Tại sao không dùng ID số?**

**❌ Cách thông thường:**

```ruby
# id = 1, kanji = "人"
Kanji.find(1)
# URL: /kanjis/1
```

**✅ Cách của chúng ta:**

```ruby
# id = "人"
Kanji.find('人')
# URL: /kanjis/人
```

**Lợi ích:**

- URL **đẹp và có nghĩa**: `/kanji/人` thay vì `/kanji/123`
- **SEO tốt hơn** (Google index URL có chữ Kanji)
- Không cần lookup: `Kanji.find('人')` thay vì phải tìm ID trước
- **Natural key** - Kanji vốn là unique

---

### **6. Tại sao có cả bảng `kanjis` và `search_indices`?**

**Tưởng tượng như:**

```
kanjis          = "Từ điển đầy đủ" (30+ cột, nhiều JSON)
search_indices  = "Mục lục" (chỉ 5-6 cột quan trọng)
```

**Khi user tìm kiếm:**

1. ✅ Query vào `search_indices` (nhanh) → Lấy danh sách `kanji_id`
2. ✅ Dùng `kanji_id` để lấy thông tin đầy đủ từ `kanjis`

**Nếu không có `search_indices`:**

- ❌ Phải query trực tiếp vào `kanjis` → chậm
- ❌ FULLTEXT index trên bảng lớn → performance kém

---

## 🎯 KẾT LUẬN

### **Thiết kế này đảm bảo:**

✅ **Normalized** - Tránh duplicate data, dễ maintain
✅ **Flexible** - JSON fields cho complex nested data
✅ **Searchable** - FULLTEXT index cho tìm kiếm nhanh
✅ **Scalable** - Dễ thêm/sửa dữ liệu
✅ **Efficient** - Index đầy đủ cho query performance
✅ **Rails-friendly** - Tuân thủ Rails conventions

### **Performance ước tính:**

| Thao tác                | Thời gian |
| ----------------------- | --------- |
| Tìm kiếm Kanji          | ~20ms     |
| Load 1 Kanji + examples | ~50ms     |
| Query composition graph | ~30ms     |
| Filter by JLPT level    | ~10ms     |

### **Dung lượng ước tính:**

| Bảng                | Số records  | Dung lượng |
| ------------------- | ----------- | ---------- |
| kanjis              | ~2,500      | ~5 MB      |
| kanji_examples      | ~25,000     | ~15 MB     |
| kanji_compositions  | ~20,000     | ~2 MB      |
| radicals            | 214         | ~100 KB    |
| textbook_references | ~15,000     | ~1 MB      |
| search_indices      | ~2,500      | ~500 KB    |
| **TOTAL**           | **~65,000** | **~24 MB** |

---

## 📚 TÀI LIỆU THAM KHẢO

- [Rails Guides - Active Record Associations](https://guides.rubyonrails.org/association_basics.html)
- [MySQL JSON Data Type](https://dev.mysql.com/doc/refman/8.0/en/json.html)
- [MySQL FULLTEXT Search](https://dev.mysql.com/doc/refman/8.0/en/fulltext-search.html)
- [Rails Guides - Migrations](https://guides.rubyonrails.org/active_record_migrations.html)

---

**Generated:** 2025-01-22
**Version:** 1.0
**Project:** Luyenkanji - Vietnamese Kanji Learning App
