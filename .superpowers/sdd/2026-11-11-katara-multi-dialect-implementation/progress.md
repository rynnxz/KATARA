# SDD ledger — plan: docs/superpowers/plans/2026-11-11-katara-multi-dialect-implementation.md
Pre-flight:
- Task 1 -> Task 4: `AppDatabase` (`schemaVersion: 2`) & `InstalledModuleModel` / `DialectReferenceModel` produced in Task 1 match what `ContentSeeder` and `ModuleDownloadService` consume in Task 4.
- Task 2 -> Task 3: Curated datasets (`melayu_deli_master.json`, `melayu_langkat_master.json`, `melayu_palembang_master.json`) produced in Task 2 match what `tool/build_content.dart` and `tool/build_modules.dart` consume in Task 3.
- Task 1 -> Task 6: `xp_events`, `streak_history`, `sync_queue`, `user_profiles`, and sync models produced in Task 1 match what `FirebaseSyncService` and `ConflictResolver` consume in Task 6.
- Task 4, 5, 6 -> Task 7: `ModuleDownloadService`, `DialectVisualIdentity`, and `FirebaseSyncService` match UI screen consumers in Task 7.

Task 1: complete (tests: `flutter test test/database_migration_v2_test.dart` -> 3/3 passed)
Task 2: complete (tests: `flutter test test/linguistic_dataset_integrity_test.dart` -> 5/5 passed)
Task 3: complete (tests: `flutter test test/module_archive_builder_test.dart` -> 3/3 passed)
Task 4: complete (tests: `flutter test test/module_download_service_test.dart` -> 3/3 passed)
Task 5: complete (tests: `flutter test test/design_system_test.dart` -> 9/9 passed)
Task 6: complete (tests: `flutter test test/sync_conflict_resolution_test.dart` -> 3/3 passed)
Task 7: complete (tests: `flutter test test/multi_dialect_ui_test.dart` -> 4/4 passed)
Task 8: complete (tests: `dart analyze lib test tool` -> 0 issues; `flutter test` -> 46/46 passed; `flutter build apk --release` -> exit 0, copied to `dist/releases/v1.1.0/katara-v1.1.0-release.apk`)


