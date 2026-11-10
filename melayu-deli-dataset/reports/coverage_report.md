# Laporan Cakupan Dataset (Dataset Coverage Report)

**Tanggal Laporan:** 10 November 2026

---

## 1. Cakupan Terhadap Draf Konten Aplikasi KATARA (`linguanusa_konten_draf_v0.1.json`)

| Komponen Draf Awal KATARA | Jumlah di Draf v0.1 | Tercakup di Dataset Baru | Penambahan / Pengayaan Baru |
|---|---:|---:|---|
| Kosakata (`words` `w001`–`w067`) | 67 | **67 (100%)** | +148 entri baru (total 215 raw / 210 curated), dilengkapi IPA, Jawi, varian ejaan, dan kalimat contoh. |
| Frasa (`phrases` `p001`–`p010`) | 10 | **10 (100%)** | +30 ungkapan baru (total 40 ungkapan harian & adat). |
| Kalimat (`sentences` `s001`–`s010`) | 10 | **10 (100%)** | +30 kalimat & percakapan baru (total 40 kalimat beranotasi tata bahasa). |
| Dialog (`dialogues` `d001`–`d002`) | 2 | **2 (100%)** | Diperluas menjadi 7 skenario dialog multi-giliran (`dialogue_exchange`). |
| Artikel Budaya (`art01`–`art03`) | 3 (teks `null`) | **3 (100%)** | Seluruh teks yang semula `null` kini berisi ringkasan dan deskripsi ilmiah lengkap. |
| Kartu Koleksi (`c01`–`c05`) | 5 (fakta `null`) | **5 (100%)** | Seluruh deskripsi sejarah & filosofi budaya telah dilengkapi + 9 topik budaya baru. |

---

## 2. Distribusi Kosakata Berdasarkan Kelas Kata (*Part of Speech*)

| Kelas Kata (`part_of_speech`) | Jumlah Entri |
|---|---:|
| `noun` | 94 |
| `verb` | 29 |
| `numeral` | 14 |
| `adjective` | 30 |
| `pronoun` | 24 |
| `adverb` | 12 |
| `particle` | 5 |
| `preposition` | 2 |
| `conjunction` | 2 |
| `interjection` | 3 |

---

## 3. Distribusi Kosakata Berdasarkan Kategori Semantis (`category`)

| Kategori Semantis | Jumlah Entri |
|---|---:|
| `greetings_and_address` | 6 |
| `numbers_and_quantifiers` | 17 |
| `kinship_and_family` | 31 |
| `food_and_culinary` | 23 |
| `question_words` | 7 |
| `daily_activities` | 17 |
| `time_and_calendar` | 10 |
| `market_and_livelihood` | 8 |
| `household_and_objects` | 18 |
| `emotions_and_states` | 24 |
| `pronouns_and_deixis` | 17 |
| `culture_and_customs` | 12 |
| `nature_and_environment` | 3 |
| `particles_and_connectors` | 22 |

---

## 4. Distribusi Kosakata Berdasarkan Konteks Penggunaan (`usage_context`)

| Konteks Penggunaan | Jumlah Entri |
|---|---:|
| `neutral` | 118 |
| `formal` | 10 |
| `informal` | 55 |
| `cultural` | 32 |

---

## 5. Distribusi Ungkapan Sehari-hari (`expressions`)

| Kategori Ungkapan | Jumlah Entri |
|---|---:|
| `greeting` | 5 |
| `polite_formal` | 6 |
| `gratitude` | 2 |
| `apology` | 3 |
| `questioning` | 6 |
| `socializing` | 4 |
| `requesting_help` | 3 |
| `agreement_refusal` | 4 |
| `emotion` | 4 |
| `informal_slang` | 3 |

---

## 6. Distribusi Kalimat & Contoh Percakapan (`sentences`)

### Berdasarkan Jenis Kalimat (`sentence_type`)
| Jenis Kalimat | Jumlah Entri |
|---|---:|
| `interrogative` | 6 |
| `declarative_simple` | 13 |
| `short_phrase` | 4 |
| `imperative` | 7 |
| `conversational` | 5 |
| `negative` | 5 |

### Berdasarkan Ranah Sosial (`context_domain`)
| Ranah Konteks | Jumlah Entri |
|---|---:|
| `community` | 19 |
| `family` | 21 |
