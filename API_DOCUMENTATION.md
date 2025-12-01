# API Documentation - Luyenkanji API

## Base URL

```
http://localhost:3000/api/v1
```

## Endpoints

### 1. Get All Kanjis (with pagination & filters)

```http
GET /api/v1/kanjis
```

**Query Parameters:**

- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 20)
- `jlpt_level` - Filter by JLPT level (N1, N2, N3, N4, N5)
- `grade` - Filter by grade (1-6)
- `stroke_count` - Filter by stroke count
- `sort` - Sort by: `frequency`, `stroke_count`, or default (character)
- `include` - Include relationships: `kanji_examples`, `textbook_references`

**Example:**

```bash
curl "http://localhost:3000/api/v1/kanjis?jlpt_level=N5&per_page=10&include=kanji_examples"
```

**Response:**

```json
{
  "data": [
    {
      "id": "一",
      "type": "kanji",
      "attributes": {
        "character": "一",
        "hanzi": null,
        "story": null,
        "grade": 1,
        "stroke_count": 1,
        "jlpt_level": "N5",
        "meaning": "one, one radical (no.1)",
        "kunyomi": ["ひと-", "ひと.つ"],
        "onyomi": ["イチ", "イツ"],
        "radical_symbol": "一",
        "radical_meaning": "one",
        "examples_count": 18,
        "component_kanjis": [],
        "compound_kanjis": []
      },
      "relationships": {
        "kanji_examples": { "data": [...] }
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "next_page": 2,
    "prev_page": null,
    "total_pages": 330,
    "total_count": 6603
  }
}
```

---

### 2. Get Single Kanji

```http
GET /api/v1/kanjis/:id
```

**Parameters:**

- `id` - Kanji character (e.g., "一", "人", "日")
- `include` - Include relationships (default: `kanji_examples,textbook_references`)

**Example:**

```bash
curl "http://localhost:3000/api/v1/kanjis/一"
```

**Response:**

```json
{
  "data": {
    "id": "一",
    "type": "kanji",
    "attributes": {
      "character": "一",
      "stroke_count": 1,
      "jlpt_level": "N5",
      "meaning": "one, one radical (no.1)",
      "kunyomi": ["ひと-", "ひと.つ"],
      "onyomi": ["イチ", "イツ"],
      ...
    },
    "relationships": {
      "kanji_examples": {
        "data": [...]
      },
      "textbook_references": {
        "data": [...]
      }
    }
  },
  "included": [
    {
      "id": "1",
      "type": "kanji_example",
      "attributes": {
        "japanese": "一年生（いちねんせい）",
        "meaning_english": "first-year student",
        "audio_mp3": "https://media.kanjialive.com/.../1_06_a.mp3",
        "audio": true
      }
    }
  ]
}
```

---

### 3. Search Kanjis

```http
GET /api/v1/kanjis/search
```

**Query Parameters:**

- `q` - Search query (searches in meaning and character)

**Example:**

```bash
curl "http://localhost:3000/api/v1/kanjis/search?q=one"
curl "http://localhost:3000/api/v1/kanjis/search?q=一"
```

**Response:**

```json
{
  "data": [
    {
      "id": "一",
      "type": "kanji",
      "attributes": {...}
    }
  ]
}
```

---

### 4. Get Kanji Examples

```http
GET /api/v1/kanjis/:kanji_id/examples
```

**Query Parameters:**

- `type` - Filter by example type: `onyomi`, `kunyomi`, `jisho`

**Example:**

```bash
curl "http://localhost:3000/api/v1/kanjis/一/examples"
curl "http://localhost:3000/api/v1/kanjis/一/examples?type=onyomi"
```

**Response:**

```json
{
  "data": [
    {
      "id": "1",
      "type": "kanji_example",
      "attributes": {
        "kanji_id": "一",
        "japanese": "一年生（いちねんせい）",
        "reading": null,
        "meaning_english": "first-year student",
        "audio_opus": "https://media.kanjialive.com/.../1_06_a.opus",
        "audio_aac": "https://media.kanjialive.com/.../1_06_a.aac",
        "audio_ogg": "https://media.kanjialive.com/.../1_06_a.ogg",
        "audio_mp3": "https://media.kanjialive.com/.../1_06_a.mp3",
        "example_type": "onyomi",
        "display_order": 0,
        "audio": true
      }
    }
  ]
}
```

---

### 5. Get Textbook References for Kanji

```http
GET /api/v1/kanjis/:kanji_id/textbooks
```

**Example:**

```bash
curl "http://localhost:3000/api/v1/kanjis/一/textbooks"
```

**Response:**

```json
{
  "data": [
    {
      "id": "1",
      "type": "textbook_reference",
      "attributes": {
        "kanji_id": "一",
        "textbook_code": "txtGenki",
        "chapter": "3",
        "textbook_name": "Genki"
      }
    }
  ]
}
```

---

### 6. Get Kanjis by Textbook

```http
GET /api/v1/textbooks/:textbook_code/kanjis
```

**Query Parameters:**

- `chapter` - Filter by chapter (optional)

**Example:**

```bash
curl "http://localhost:3000/api/v1/textbooks/txtGenki/kanjis"
curl "http://localhost:3000/api/v1/textbooks/txtGenki/kanjis?chapter=3"
```

**Textbook Codes:**

- `lesson` - CIJ Lessons
- `txtBasicKanji` - Basic Kanji Book
- `txtGenki` - Genki
- `txtAP` - AP Japanese
- `mosr` - Remembering the Kanji
- `cijr` - CIJ Revised

**Response:**

```json
{
  "data": [
    {
      "id": "1",
      "type": "textbook_reference",
      "attributes": {
        "kanji_id": "一",
        "textbook_code": "txtGenki",
        "chapter": "3",
        "textbook_name": "Genki"
      },
      "relationships": {
        "kanji": {
          "data": {
            "id": "一",
            "type": "kanji"
          }
        }
      }
    }
  ],
  "included": [
    {
      "id": "一",
      "type": "kanji",
      "attributes": {...}
    }
  ]
}
```

---

## JSON:API Format

This API follows the [JSON:API specification](https://jsonapi.org/).

### Key Features:

1. **Consistent Structure:**

   - All responses have a `data` key
   - Pagination info in `meta`
   - Related resources in `included`

2. **Relationships:**

   - Use `include` parameter to load related resources
   - Related resources appear in `included` array

3. **Sparse Fieldsets:**

   - Use `fields[kanji]=character,meaning,kunyomi` to select specific fields

4. **Error Format:**

```json
{
  "error": "Kanji not found"
}
```

---

## Example Use Cases

### 1. Get all N5 Kanji sorted by frequency

```bash
curl "http://localhost:3000/api/v1/kanjis?jlpt_level=N5&sort=frequency&per_page=50"
```

### 2. Get Kanji details with examples and textbooks

```bash
curl "http://localhost:3000/api/v1/kanjis/一?include=kanji_examples,textbook_references"
```

### 3. Get all Kanji in Genki Chapter 3

```bash
curl "http://localhost:3000/api/v1/textbooks/txtGenki/kanjis?chapter=3&include=kanji"
```

### 4. Search for kanjis with meaning containing "person"

```bash
curl "http://localhost:3000/api/v1/kanjis/search?q=person"
```

### 5. Get onyomi examples for a kanji

```bash
curl "http://localhost:3000/api/v1/kanjis/一/examples?type=onyomi"
```

---

## Rate Limiting

Currently no rate limiting is implemented. Consider adding `rack-attack` gem for production.

---

## CORS

CORS is enabled via the `rack-cors` gem. Configure in `config/initializers/cors.rb` if needed.

---

## Testing the API

### Using curl:

```bash
# Test health check
curl http://localhost:3000/up

# Test kanji endpoint
curl http://localhost:3000/api/v1/kanjis/一

# Test with pretty print
curl -s http://localhost:3000/api/v1/kanjis/一 | jq
```

### Using HTTPie:

```bash
http http://localhost:3000/api/v1/kanjis/一
```

### Using Postman:

Import the endpoints and test interactively.

---

## Data Statistics

- **Kanjis**: 6,603
- **Examples**: 32,343
- **Textbook References**: 6,226
- **Compositions**: TBD (needs fix)

---

**Last Updated:** 2025-11-30
**Version:** 1.0
