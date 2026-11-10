# KATARA Multi-Dialect, Offline-First, Firebase Sync & Modular Download Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand the existing KATARA Flutter application into a multi-dialect Melayu learning platform (Melayu Deli bundled in APK; Melayu Langkat and Melayu Palembang as separate downloadable ZIP modules for GitHub Releases) with research-backed linguistic datasets, SQLite v2 migration, optional Google Sign-In & Firestore event-ledger sync on project `katara-melayu`, high-contrast WCAG AA tactile UI per dialect, interactive dialect comparison, and an offline-capable About & References screen.

**Architecture:** Local-First Single Source of Truth using `drift` (`AppDatabase` migrated from `schemaVersion: 1` to `2`). Only `ms-deli` is bundled inside `assets/content/ms-deli/` to keep the APK lightweight; `ms-langkat` and `ms-palembang` are compiled by `tool/build_modules.dart` into standalone release archives (`dist/releases/v1.1.0/module_langkat.zip` and `module_palembang.zip`) with `module_catalog.json` and SHA-256 verification, installed atomically into `<appDocDir>/modules/<courseId>/` by `ModuleManagerService`, while `SyncEngine` synchronizes local SQLite progress to Cloud Firestore (`katara-melayu`) using idempotent `xp_events` and per-entity conflict resolution.

**Tech Stack:** Flutter (Dart 3), `flutter_riverpod`, `go_router`, `drift` / `sqlite3_flutter_libs`, `crypto`, `archive`, `http`, `url_launcher`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`, `just_audio`, `flutter_local_notifications`.

**Spec:** `docs/superpowers/specs/2026-11-11-katara-multi-dialect-design.md` (and foundational rules in `docs/KATARA_SPEC.md`).

## Global Constraints

- **Do not rebuild from scratch:** Preserve all existing features, routes, and user progress from Phases 0–6.
- **Read-only `konten/`:** Never modify any file inside `konten/`. Store research datasets in `melayu-deli-dataset/`, `melayu-langkat-dataset/`, and `melayu-palembang-dataset/`.
- **Lightweight APK:** Only `ms-deli` is bundled in `pubspec.yaml` `assets:`. Downloadable dialect ZIPs (`module_langkat.zip`, `module_palembang.zip`) live in `dist/releases/v1.1.0/` for GitHub Releases (`https://github.com/rynnxz/KATARA/releases/download/v1.1.0/...`) and must never be added to `pubspec.yaml` assets.
- **Zero fabricated linguistic data:** Every vocabulary item, phrase, sentence, dialogue, quiz item, and cultural note must trace to real academic/lexicographical sources with `confidence` (`high`|`medium`|`low`) and `verification_status` (`verified`|`needs_review`|`disputed`|`rejected`). Never include `rejected` entries in production learning modules.
- **Strict WCAG AA+ High Contrast (antislop DURING mode):** Normal text contrast ratio >= 4.5:1 (target >= 7.0:1 for primary/secondary body text so bright backgrounds never have washed-out grey text); large text >= 3.0:1; non-text boundaries >= 3.0:1. Pair every status indicator with an icon and text label. No em dashes (`—`) in UI copy (R-02).
- **Guest Mode First:** Core learning, quizzes, XP, streak, dictionary, and offline downloaded modules must never require login.

## Review Focus

1. **Path Traversal or Corrupted ZIP during Module Extraction:** A ZIP archive containing `../` or absolute paths, a truncated download with mismatched SHA-256, or a missing required JSON file (`metadata.json`, `vocabulary.json`, etc.) must be rejected before touching `<appDocDir>/modules/<courseId>/`, leaving any previously installed version intact.
2. **Progress Preservation on Module Uninstallation or Logout:** Deleting a downloaded dialect module (`ms-langkat` or `ms-palembang`) or signing out of Google must remove only the module's content files/rows (or auth session) while keeping `course_progress`, `word_mastery`, `xp_events`, and `streak_history` intact.
3. **Idempotent Multi-Device XP & Progress Conflict Resolution:** Syncing the same `xp_events` ledger entry twice or merging progress from two offline devices must never double-count XP or overwrite higher lesson stars/mastery with lower values.
4. **SQLite Migration (`v1 -> v2`) on Existing User Databases:** Upgrading an existing `schemaVersion: 1` database populated with `ms-deli` progress must preserve all `user_stats`, `course_progress`, and `word_mastery` rows without throwing SQL column errors.
5. **Contrast on Dialect-Themed & Bright Surfaces:** Rendering badges, subtitles, disabled states, or `CourseTheme` headers (Amber `#F5B700`, Emerald `#1E7F5C`, Maroon `#8B1E24`) on light cream (`#FFF9EC` / `#F6EEDC`) or dark surfaces must never produce grey-on-bright text below 4.5:1 contrast.

---

### Task 1: Phase 1 Audit Report & SQLite Schema Migration (`v1 -> v2`)

**Files:**
- Create: `docs/reports/initial_project_audit.md`
- Modify: `pubspec.yaml`
- Modify: `lib/data/db/app_database.dart`
- Modify: `lib/data/content/content_models.dart`
- Modify: `lib/domain/entities/user_progress.dart`
- Test: `test/database_migration_v2_test.dart`

**Interfaces:**
- Consumes: Existing `AppDatabase` (`schemaVersion == 1`) in `lib/data/db/app_database.dart`.
- Produces:
  - `AppDatabase` with `schemaVersion => 2` and `MigrationStrategy.onUpgrade` adding tables `installed_modules`, `dialect_references`, `xp_events`, `streak_history`, `sync_queue`, `user_profiles`, plus new provenance/module/sync columns on `words`, `courses`, `user_stats`, `course_progress`, and `word_mastery`.
  - Models `InstalledModuleModel`, `DialectReferenceModel`, `XpEventModel`, `SyncQueueItemModel`, `SyncStatusSummary` in `lib/data/content/content_models.dart` and `lib/domain/entities/user_progress.dart`.

- [ ] **Step 1: Write `docs/reports/initial_project_audit.md` documenting existing framework, folder structure, DB v1 tables, Riverpod providers, routes, UI components, and `ms-deli` dataset baseline.**
- [ ] **Step 2: Add required packages (`archive`, `http`, `url_launcher`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`) to `pubspec.yaml` and run `flutter pub get`.**
- [ ] **Step 3: Write failing migration & v2 schema test in `test/database_migration_v2_test.dart` (verifies `schemaVersion == 2`, creation of `installed_modules`, `dialect_references`, `xp_events`, `streak_history`, `sync_queue`, `user_profiles`, and non-destructive upgrade from v1 SQL state).**
- [ ] **Step 4: Run `flutter test test/database_migration_v2_test.dart` and confirm it fails against `schemaVersion == 1`.**
- [ ] **Step 5: Implement `schemaVersion => 2`, `_createV2TablesAndColumns()`, and `onUpgrade` in `lib/data/db/app_database.dart`, plus the new model classes in `lib/data/content/content_models.dart` and `lib/domain/entities/user_progress.dart`.**
- [ ] **Step 6: Run `flutter test test/database_migration_v2_test.dart` and verify PASS.**

---

### Task 2: Linguistic Research, Provenance Datasets, & Research Reports (Deli, Langkat, Palembang)

**Files:**
- Modify: `melayu-deli-dataset/raw/vocabulary.json`
- Modify: `melayu-deli-dataset/raw/sentences.json`
- Modify: `melayu-deli-dataset/raw/quiz_additions.json` (or `curated/melayu_deli_master.json`)
- Create: `melayu-langkat-dataset/references/sources.json`
- Create: `melayu-langkat-dataset/raw/langkat_research_corpus.json`
- Create: `melayu-langkat-dataset/curated/melayu_langkat_master.json`
- Create: `melayu-palembang-dataset/references/sources.json`
- Create: `melayu-palembang-dataset/raw/palembang_research_corpus.json`
- Create: `melayu-palembang-dataset/curated/melayu_palembang_master.json`
- Create: `docs/reports/research_report_deli.md`
- Create: `docs/reports/research_report_langkat.md`
- Create: `docs/reports/research_report_palembang.md`
- Test: `test/linguistic_dataset_integrity_test.dart`

**Interfaces:**
- Consumes: Existing `melayu-deli-dataset/` schemas and `konten/linguanusa_konten_draf_v0.1.json` (read-only).
- Produces:
  - Verified production-ready curated master datasets for `melayu_deli` (`ms-deli`), `melayu_langkat` (`ms-langkat`: Stabat, Tanjung Pura, Secanggang, Pangkalan Brandan), and `melayu_palembang` (`ms-palembang`: Palembang Ilir/Ulu, *Sari-sari* & *Bebaso* registers) with >= 300 vocabulary entries, >= 100 example sentences (standalone + lexical examples), >= 15 lessons across >= 10 categories, >= 10 conversations, >= 100 quiz questions, and >= 5 documented academic/dictionary sources per dialect, with >= 70% `verified` status and zero `rejected` entries in curated/production outputs.
  - Research reports `docs/reports/research_report_deli.md`, `docs/reports/research_report_langkat.md`, and `docs/reports/research_report_palembang.md`.

- [ ] **Step 1: Write failing dataset integrity and provenance test in `test/linguistic_dataset_integrity_test.dart` (checks no duplicate IDs, all entries have `dialect_id`, valid `confidence` and `verification_status`, zero `rejected` entries in curated sets, valid source citations with real URLs, regional tagging for Langkat/Palembang, and target counts).**
- [ ] **Step 2: Run `flutter test test/linguistic_dataset_integrity_test.dart` to verify it fails before datasets are built.**
- [ ] **Step 3: Expand `melayu-deli-dataset/` and generate `melayu-langkat-dataset/` and `melayu-palembang-dataset/` from documented lexicographical & academic sources, separating `raw/` (which retains `needs_review`, `disputed`, `rejected`) from `curated/`.**
- [ ] **Step 4: Generate `docs/reports/research_report_deli.md`, `docs/reports/research_report_langkat.md`, and `docs/reports/research_report_palembang.md` with exact audited statistics.**
- [ ] **Step 5: Run `flutter test test/linguistic_dataset_integrity_test.dart` and verify PASS.**

---

### Task 3: Bundled Content Compiler (`ms-deli`) & Standalone ZIP Module Builder (`module_langkat.zip`, `module_palembang.zip`)

**Files:**
- Modify: `tool/build_content.dart`
- Create: `tool/build_modules.dart`
- Modify: `assets/content/courses.json`
- Modify: `assets/content/credits.json`
- Create: `assets/content/module_catalog.json`
- Create: `dist/releases/v1.1.0/module_langkat.zip`
- Create: `dist/releases/v1.1.0/module_palembang.zip`
- Create: `dist/releases/v1.1.0/module_catalog.json`
- Test: `test/module_archive_builder_test.dart`

**Interfaces:**
- Consumes: `melayu-deli-dataset/curated/melayu_deli_master.json`, `melayu-langkat-dataset/curated/melayu_langkat_master.json`, `melayu-palembang-dataset/curated/melayu_palembang_master.json`.
- Produces:
  - Updated bundled `assets/content/ms-deli/**` (`is_bundled: true`).
  - Standalone ZIP packages `dist/releases/v1.1.0/module_langkat.zip` and `dist/releases/v1.1.0/module_palembang.zip` (outside APK assets) containing `metadata.json`, `lessons.json`, `vocabulary.json`, `phrases.json`, `sentences.json`, `quizzes.json`, `conversations.json`, `references.json`, `articles.json`, `collection_cards.json`, `audio/`, `images/`.
  - `assets/content/module_catalog.json` and `dist/releases/v1.1.0/module_catalog.json` with real byte sizes, real SHA-256 hashes, and GitHub Release download URLs (`https://github.com/rynnxz/KATARA/releases/download/v1.1.0/module_<dialect>.zip`).

- [ ] **Step 1: Write failing test `test/module_archive_builder_test.dart` that checks `module_catalog.json`, verifies `module_langkat.zip` and `module_palembang.zip` exist in `dist/releases/v1.1.0/`, verifies their SHA-256 matches `module_catalog.json`, and ensures `pubspec.yaml` does not bundle `dist/` into the APK.**
- [ ] **Step 2: Run `flutter test test/module_archive_builder_test.dart` to confirm failure.**
- [ ] **Step 3: Update `tool/build_content.dart` and create `tool/build_modules.dart`; run both tools to generate `assets/content/ms-deli/**`, `assets/content/courses.json`, `assets/content/module_catalog.json`, and `dist/releases/v1.1.0/*.zip`.**
- [ ] **Step 4: Run `flutter test test/module_archive_builder_test.dart` and verify PASS.**

---

### Task 4: Downloadable Dialect Module Manager & Directory Seeder

**Files:**
- Modify: `lib/data/content/content_seeder.dart`
- Create: `lib/services/module_download_service.dart`
- Modify: `lib/domain/repositories/content_repository.dart`
- Modify: `lib/data/repositories/local_content_repository.dart`
- Test: `test/module_download_service_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `ContentSeeder`, `assets/content/module_catalog.json`, and ZIP bytes from HTTP or local release archive fallback.
- Produces:
  - `ContentSeeder.seedCourseFromDirectory({required String courseId, required Directory directory, required int version, required String sha256, required int sizeBytes})` and `ContentSeeder.uninstallCourseContent(String courseId)` (which removes course content rows while preserving `course_progress`, `word_mastery`, `xp_events`, and `xp_log`).
  - `ModuleDownloadService` supporting `fetchCatalog()`, `installModule(String courseId, {void Function(double progress)? onProgress})`, `updateModule(String courseId, ...)`, `deleteModule(String courseId)`, `getStorageInfo()`, with strict SHA-256 validation, path-traversal-safe ZIP extraction (`..` / absolute path rejection), and atomic staging directory swap.

- [ ] **Step 1: Write failing tests in `test/module_download_service_test.dart` covering: (a) successful ZIP install + SQLite seeding for `ms-langkat` and `ms-palembang`, (b) rejection of corrupted SHA-256 ZIP, (c) rejection of ZIP with `../evil.txt` path traversal, (d) module deletion preserving `course_progress` and `word_mastery` in SQLite.**
- [ ] **Step 2: Run `flutter test test/module_download_service_test.dart` to confirm failure.**
- [ ] **Step 3: Implement `seedCourseFromDirectory` and `uninstallCourseContent` in `lib/data/content/content_seeder.dart`, `ModuleDownloadService` in `lib/services/module_download_service.dart`, and dialect reference/comparison queries in `LocalContentRepository`.**
- [ ] **Step 4: Run `flutter test test/module_download_service_test.dart` and verify PASS.**

---

### Task 5: High-Contrast WCAG AA Design System Upgrade & Dialect Visual Identities

**Files:**
- Modify: `lib/app/theme/katara_colors.dart`
- Modify: `lib/app/theme/katara_theme.dart`
- Modify: `lib/app/widgets/k_card.dart`
- Modify: `lib/app/widgets/k_button.dart`
- Modify: `lib/app/widgets/k_chip.dart`
- Modify: `lib/app/widgets/pattern_background.dart`
- Modify: `test/design_system_test.dart`

**Interfaces:**
- Consumes: `KataraPalette`, `CourseTheme`, `KataraTheme`.
- Produces:
  - High-contrast tokens in `KataraPalette.light` (`ink: #221910`, `inkMuted: #4A3E2D` -> contrast > 7.4:1 on `#FFF9EC` and `#F6EEDC`, eliminating grey-on-bright text) and `KataraPalette.dark` (`ink: #F8F1E3`, `inkMuted: #D8CCB8` -> contrast > 9.5:1 on `#15110C` and `#211B14`).
  - `DialectVisualIdentity` for `ms-deli` (Amber/Warm Gold `#F5B700`, badge surface `#FFF3C4`, badge ink `#221910`), `ms-langkat` (Emerald/Mint `#1E7F5C`, badge surface `#DDF5EA`, badge ink `#0F291E`), and `ms-palembang` (Maroon/Coral `#8B1E24`, badge surface `#FADBD8`, badge ink `#2C1012`).
  - Tactile 3D `KCard` with 20px border radius, 2px border, 4px bottom lip shadow, and natural pressed state offset (`2px`), plus `DialectOrnamentPainter` cultural micro-illustrations (Pucuk Rebung Deli, Payung/Tanjak Langkat, Songket/Ampera Palembang).

- [ ] **Step 1: Update `test/design_system_test.dart` with strict contrast assertions (>= 4.5:1 for all text pairings including `inkMuted` on `bg`, `surface`, `surfaceAlt`, and dialect badge surfaces in both light and dark themes, plus >= 3.0:1 non-text border contrast).**
- [ ] **Step 2: Run `flutter test test/design_system_test.dart` to see which new assertions fail.**
- [ ] **Step 3: Upgrade `lib/app/theme/katara_colors.dart`, `lib/app/theme/katara_theme.dart` (explicit `onSurfaceVariant`, `snackBarTheme`, `navigationBarTheme`, `inputDecorationTheme`, `dialogTheme`, `bottomSheetTheme`), `lib/app/widgets/k_card.dart`, `lib/app/widgets/k_chip.dart`, and `lib/app/widgets/pattern_background.dart`.**
- [ ] **Step 4: Run `flutter test test/design_system_test.dart` and verify PASS.**

---

### Task 6: Firebase Project Configuration (`katara-melayu`), Google Sign-In, & Offline-First Sync Engine

**Files:**
- Create: `firebase.json`
- Create: `.firebaserc`
- Create: `firestore.rules`
- Create: `android/app/google-services.json`
- Create: `lib/services/firebase_sync_service.dart`
- Modify: `lib/domain/repositories/progress_repository.dart`
- Modify: `lib/data/repositories/local_progress_repository.dart`
- Modify: `lib/app/providers.dart`
- Test: `test/sync_conflict_resolution_test.dart`

**Interfaces:**
- Consumes: `AppDatabase` (`xp_events`, `streak_history`, `sync_queue`, `user_profiles`, `course_progress`, `word_mastery`, `achievements_unlocked`), Firebase project `katara-melayu`.
- Produces:
  - `ConflictResolver` (pure Dart, deterministic testable class) implementing per-entity merge rules:
    - XP: idempotent union of `xp_events` by `event_id` (never blind `max(xp)`).
    - Lesson completion: per-lesson merge (`max(stars)`, `max(bestScore)`).
    - Word mastery: per-item merge by latest `updated_at` and cumulative counts.
    - Streak: recomputed from union of validated activity dates in `streak_history`.
    - Profile/Settings: latest `revision` & `updated_at`.
    - Achievements: set union by `achievement_id`.
  - `FirebaseSyncService` handling optional Google Sign-In, Guest mode preservation, account linking, background queue flushing with exponential backoff, and emitting `SyncState` (`synced`, `syncing`, `offline`, `failed`, `pending`).
  - Audited `firestore.rules` (authored via `firestore-rules-author` subagent per environment rules).

- [ ] **Step 1: Register/fetch Android app `id.katara.app` in Firebase project `katara-melayu` via Firebase MCP/CLI and write `android/app/google-services.json`, `.firebaserc`, and `firebase.json`.**
- [ ] **Step 2: Delegate `firestore.rules` authoring to the mandatory `firestore-rules-author` subagent so users can only access `users/{uid}/**` and read public metadata.**
- [ ] **Step 3: Write failing unit tests in `test/sync_conflict_resolution_test.dart` testing idempotent XP ledger merge across two concurrent devices, lesson star merge, mastery timestamp merge, achievement union, streak date union, exponential backoff calculation, and guest-to-Google account merge without data loss.**
- [ ] **Step 4: Run `flutter test test/sync_conflict_resolution_test.dart` to confirm failure.**
- [ ] **Step 5: Implement `ConflictResolver` and `FirebaseSyncService` in `lib/services/firebase_sync_service.dart` and wire `xp_events` / `streak_history` / `sync_queue` recording into `LocalProgressRepository`.**
- [ ] **Step 6: Run `flutter test test/sync_conflict_resolution_test.dart` and verify PASS.**

---

### Task 7: Interactive Learning Experiences, Dialect Comparison, Module Manager UI, & About/References Screen

**Files:**
- Modify: `lib/features/region_picker/region_picker_screen.dart`
- Create: `lib/features/dialect_comparison/dialect_comparison_screen.dart`
- Create: `lib/features/practice/conversation_practice_screen.dart`
- Create: `lib/features/practice/pronunciation_guide_screen.dart`
- Modify: `lib/features/practice/practice_screen.dart`
- Modify: `lib/features/dictionary/dictionary_screen.dart`
- Modify: `lib/features/profile/profile_screen.dart`
- Modify: `lib/features/settings/about_screen.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `lib/features/path_map/learn_map_screen.dart`
- Modify: `lib/app/router.dart`
- Test: `test/multi_dialect_ui_test.dart`

**Interfaces:**
- Consumes: `ModuleDownloadService`, `FirebaseSyncService`, `ContentRepository`, `ProgressRepository`, `DialectVisualIdentity`.
- Produces:
  - Upgraded `RegionPickerScreen` (`/region`) showing bundled `Melayu Deli` and downloadable `Melayu Langkat` & `Melayu Palembang` with download progress bar, SHA-256 verification badge, storage usage, Update/Delete module actions, and local ZIP import fallback.
  - `DialectComparisonScreen` (`/dialect-comparison`) displaying verified side-by-side table & cards (`Indonesia | Melayu Deli | Melayu Langkat | Melayu Palembang`) with regional notes, IPA pronunciation, and source badges.
  - `ConversationPracticeScreen` (`/practice/conversation`) & `PronunciationGuideScreen` (`/practice/pronunciation`), plus Daily Challenge and Vocabulary Flashcards in `PracticeScreen`.
  - Upgraded `ProfileScreen` & `SettingsScreen` with optional Google Sign-In card, `SyncStatusBadge` (`Synced`, `Syncing`, `Offline`, `Sync failed`, `Pending changes`), Dialect Mastery breakdown, and Weekly Activity chart/calendar.
  - Comprehensive `AboutScreen` (`/about` — **Tentang & Referensi**) with 5 offline-accessible sections: (A) About the Application, (B) Language Data Sources per dialect with clickable URLs, (C) Content Attribution, (D) Research Methodology, and (E) Data Limitations.

- [ ] **Step 1: Write widget tests in `test/multi_dialect_ui_test.dart` verifying: (a) Region Picker displays Deli (bundled), Langkat (downloadable/installed), and Palembang (downloadable/installed) with install/delete controls, (b) Dialect Comparison renders verified 4-column comparison data, (c) About & References screen renders all 5 sections and dialect source filters offline.**
- [ ] **Step 2: Run `flutter test test/multi_dialect_ui_test.dart` to confirm failure.**
- [ ] **Step 3: Implement `DialectComparisonScreen`, `ConversationPracticeScreen`, `PronunciationGuideScreen`, and upgrade `RegionPickerScreen`, `PracticeScreen`, `DictionaryScreen`, `ProfileScreen`, `SettingsScreen`, `AboutScreen`, `LearnMapScreen`, and `appRouterProvider`.**
- [ ] **Step 4: Run `flutter test test/multi_dialect_ui_test.dart` and verify PASS.**

---

### Task 8: Final Verification, Performance & QA Measurement, Documentation, and Release Build

**Files:**
- Create: `docs/MODULE_STRUCTURE.md`
- Create: `docs/INSTALLATION_AND_CONFIG.md`
- Create: `docs/DEPLOYMENT_AND_RELEASES.md`
- Create: `docs/reports/qa_and_performance_report.md`
- Modify: `docs/PROGRESS.md`
- Modify: `docs/DECISIONS.md`

**Interfaces:**
- Consumes: All completed tasks (Tasks 1–7).
- Produces:
  - Full test suite passing (`flutter analyze` 0 issues, `flutter test` 100% green).
  - Release APK built (`build/app/outputs/flutter-apk/app-release.apk`) and copied to `dist/releases/v1.1.0/katara-v1.1.0-release.apk` alongside `module_langkat.zip`, `module_palembang.zip`, and `module_catalog.json`.
  - Measured performance and QA report in `docs/reports/qa_and_performance_report.md` (APK size, module ZIP sizes, seeding/startup time, SQLite DB size, sync payload size, contrast audit results, and functional/offline test matrix).
  - Git remote configured to `https://github.com/rynnxz/KATARA.git`.

- [ ] **Step 1: Run `flutter analyze` and `flutter test` across the entire repository and fix any warnings or regressions.**
- [ ] **Step 2: Build release APK (`flutter build apk --release`), measure APK size, module ZIP sizes (`module_langkat.zip`, `module_palembang.zip`), SQLite seeding time, and sync payload size.**
- [ ] **Step 3: Write `docs/MODULE_STRUCTURE.md`, `docs/INSTALLATION_AND_CONFIG.md`, `docs/DEPLOYMENT_AND_RELEASES.md`, and `docs/reports/qa_and_performance_report.md`, and update `docs/PROGRESS.md` & `docs/DECISIONS.md`.**
- [ ] **Step 4: Configure `git remote add origin https://github.com/rynnxz/KATARA.git` (or `set-url`) and commit all changes cleanly.**
