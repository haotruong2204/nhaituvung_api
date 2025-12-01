# Hướng dẫn Setup Database Kanji

## 📋 Tổng quan

Tài liệu này hướng dẫn setup database và import dữ liệu Kanji từ dự án luyenkanji.

## 🗄️ Database Schema

Database gồm 4 bảng chính:

1. **kanjis** - Thông tin Kanji (primary key: `character`)
2. **kanji_examples** - Ví dụ từ vựng + audio
3. **kanji_compositions** - Quan hệ cấu tạo (composition graph)
4. **textbook_references** - Tham chiếu sách giáo khoa

Chi tiết schema xem file: `DATABASE_DESIGN.md` trong dự án luyenkanji

## 🚀 Các bước Setup

### 1. Chạy migrations

```bash
cd /Users/haotruong/Desktop/nhaituvung_api

# Run all migrations
rails db:migrate
```

Migrations sẽ:

- ✅ Thêm các trường mới vào bảng `kanjis`
- ✅ Tạo bảng `kanji_examples`
- ✅ Tạo bảng `kanji_compositions`
- ✅ Tạo bảng `textbook_references`

### 2. Import dữ liệu từ JSON files

```bash
# Import với đường dẫn mặc định (/Users/haotruong/Desktop/luyenkanji)
rails kanji:import

# Hoặc chỉ định đường dẫn khác
LUYENKANJI_PATH=/path/to/luyenkanji rails kanji:import
```

Quá trình import sẽ:

1. Import composition data (~20,000 relationships)
2. Import kanji data (~2,500 kanjis)
3. Import examples (~25,000 examples)
4. Import textbook references (~15,000 references)

**Thời gian ước tính:** 5-10 phút

### 3. Kiểm tra dữ liệu

```bash
# Vào Rails console
rails console

# Kiểm tra số lượng records
Kanji.count                  # => ~2,500
KanjiExample.count           # => ~25,000
KanjiComposition.count       # => ~20,000
TextbookReference.count      # => ~15,000

# Test một vài queries
kanji = Kanji.find("一")
kanji.meaning                # => "one, one radical (no.1)"
kanji.kunyomi                # => ["ひと-", "ひと.つ"]
kanji.onyomi                 # => ["イチ", "イツ"]
kanji.kanji_examples.count   # => ~9

# Test compositions
kanji.component_kanjis       # => ["一"] (các thành phần tạo nên kanji này)
kanji.compound_kanjis        # => [...] (các kanji sử dụng kanji này)

# Test examples
kanji.kanji_examples.first.japanese          # => "一年生（いちねんせい）"
kanji.kanji_examples.first.meaning_english   # => "first-year student"
kanji.kanji_examples.first.audio?        # => true
```

## 📊 Cấu trúc Models

### Kanji Model

```ruby
# Associations
kanji.kanji_examples         # has_many
kanji.textbook_references    # has_many
kanji.in_compositions        # has_many (thành phần tạo nên kanji)
kanji.out_compositions       # has_many (kanji sử dụng kanji này)

# Methods
kanji.component_kanjis       # Array các kanji thành phần
kanji.compound_kanjis        # Array các kanji sử dụng kanji này

# Scopes
Kanji.by_jlpt("N5")
Kanji.by_grade(1)
Kanji.by_stroke_count(1)
Kanji.ordered_by_frequency
```

### KanjiExample Model

```ruby
# Associations
example.kanji                # belongs_to

# Methods
example.audio_url(:mp3)      # Lấy URL audio theo format
example.audio?           # Check có audio không

# Scopes
KanjiExample.onyomi_examples
KanjiExample.kunyomi_examples
KanjiExample.ordered
```

### KanjiComposition Model

```ruby
# Associations
composition.kanji            # belongs_to

# Scopes
KanjiComposition.inbound     # relation_type = "in"
KanjiComposition.outbound    # relation_type = "out"
```

### TextbookReference Model

```ruby
# Associations
reference.kanji              # belongs_to

# Methods
reference.textbook_name      # Convert code -> tên sách

# Scopes
TextbookReference.by_textbook("txtGenki")
TextbookReference.by_chapter("3")
TextbookReference.ordered
```

## 🎯 Ví dụ Queries hữu ích

```ruby
# 1. Lấy tất cả Kanji JLPT N5
Kanji.by_jlpt("N5")

# 2. Lấy Kanji theo số nét
Kanji.by_stroke_count(1)

# 3. Lấy Kanji phổ biến nhất (theo báo chí)
Kanji.ordered_by_frequency.limit(10)

# 4. Lấy tất cả ví dụ của một Kanji
Kanji.find("一").kanji_examples.ordered

# 5. Lấy Kanji trong sách Genki Chapter 3
TextbookReference.by_textbook("txtGenki")
                 .by_chapter("3")
                 .includes(:kanji)
                 .map(&:kanji)

# 6. Lấy composition graph của một Kanji
kanji = Kanji.find("林")
kanji.in_compositions   # => [{"木", "in"}, {"木", "in"}]
kanji.out_compositions  # => [{"森", "out"}]

# 7. Search kanji theo meaning
Kanji.where("meaning LIKE ?", "%one%")
```

## 🔧 Troubleshooting

### Lỗi Foreign Key

Nếu gặp lỗi foreign key khi chạy migrations:

```bash
# Xóa các bảng cũ trước (nếu cần)
rails db:drop
rails db:create
rails db:migrate
```

### Lỗi Import

Nếu import bị lỗi:

```bash
# Xóa dữ liệu và import lại
rails db:reset
rails kanji:import
```

### Kiểm tra Primary Key

Bảng `kanjis` phải dùng `character` làm primary key:

```ruby
# Rails console
Kanji.primary_key  # => "character"

# Test
Kanji.find("一")   # Phải work
```

## 📚 Tài liệu thêm

- **DATABASE_DESIGN.md** (trong luyenkanji) - Chi tiết thiết kế database
- **CLAUDE.md** (trong luyenkanji) - Project overview

## ✅ Checklist Setup

- [ ] Đã chạy `rails db:migrate` thành công
- [ ] Đã chạy `rails kanji:import` thành công
- [ ] `Kanji.count` ≈ 2,500
- [ ] `KanjiExample.count` ≈ 25,000
- [ ] `KanjiComposition.count` ≈ 20,000
- [ ] `TextbookReference.count` ≈ 15,000
- [ ] `Kanji.find("一")` trả về dữ liệu đúng
- [ ] Associations hoạt động (test `kanji.kanji_examples`)

## 🎉 Xong!

Sau khi hoàn thành các bước trên, database đã sẵn sàng để phục vụ API!
