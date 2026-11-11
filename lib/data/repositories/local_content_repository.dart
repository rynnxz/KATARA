import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:katara/data/content/content_models.dart';
import 'package:katara/data/content/content_seeder.dart';
import 'package:katara/data/db/app_database.dart';
import 'package:katara/domain/entities/user_progress.dart';
import 'package:katara/domain/repositories/content_repository.dart';

class LocalContentRepository implements ContentRepository {
  LocalContentRepository({required this.db, AssetStringLoader? loadAsset})
    : _loadAsset = loadAsset ?? defaultAssetStringLoader;

  final AppDatabase db;
  final AssetStringLoader _loadAsset;

  GameConfig? _cachedConfig;

  @override
  Future<List<LanguageModel>> getLanguages() async {
    await db.ensureInitialized();
    final rows = await db
        .customSelect('SELECT * FROM languages ORDER BY sort_order ASC')
        .get();
    return rows
        .map(
          (r) => LanguageModel(
            id: r.read<String>('id'),
            name: r.read<String>('name'),
            tagline: r.read<String>('tagline'),
            order: r.read<int>('sort_order'),
          ),
        )
        .toList();
  }

  @override
  Future<List<CourseModel>> getCourses({String? languageId}) async {
    await db.ensureInitialized();
    final rows = languageId != null
        ? await db
              .customSelect(
                'SELECT * FROM courses WHERE language_id = ? ORDER BY status ASC, id ASC',
                variables: [Variable.withString(languageId)],
              )
              .get()
        : await db
              .customSelect('SELECT * FROM courses ORDER BY status ASC, id ASC')
              .get();
    return rows.map(_mapCourse).toList();
  }

  @override
  Future<CourseModel?> getCourse(String courseId) async {
    await db.ensureInitialized();
    final rows = await db
        .customSelect(
          'SELECT * FROM courses WHERE id = ? LIMIT 1',
          variables: [Variable.withString(courseId)],
        )
        .get();
    if (rows.isEmpty) return null;
    return _mapCourse(rows.first);
  }

  CourseModel _mapCourse(QueryRow r) => CourseModel.fromJson(r.data);

  @override
  Future<List<UnitModel>> getUnits(String courseId) async {
    await db.ensureInitialized();
    final unitRows = await db
        .customSelect(
          'SELECT * FROM units WHERE course_id = ? AND deprecated = 0 ORDER BY sort_order ASC',
          variables: [Variable.withString(courseId)],
        )
        .get();

    final lessonRows = await db
        .customSelect(
          'SELECT * FROM lessons WHERE course_id = ? AND deprecated = 0 ORDER BY sort_order ASC',
          variables: [Variable.withString(courseId)],
        )
        .get();

    final itemRows = await db
        .customSelect(
          'SELECT * FROM lesson_items WHERE course_id = ? ORDER BY sort_order ASC',
          variables: [Variable.withString(courseId)],
        )
        .get();

    final itemsByLesson = <String, List<String>>{};
    for (final ir in itemRows) {
      final lid = ir.read<String>('lesson_id');
      itemsByLesson
          .putIfAbsent(lid, () => <String>[])
          .add(ir.read<String>('item_id'));
    }

    final lessonsByUnit = <String, List<LessonModel>>{};
    for (final lr in lessonRows) {
      final lid = lr.read<String>('id');
      final uid = lr.read<String>('unit_id');
      lessonsByUnit
          .putIfAbsent(uid, () => <LessonModel>[])
          .add(
            LessonModel(
              id: lid,
              courseId: lr.read<String>('course_id'),
              unitId: uid,
              order: lr.read<int>('sort_order'),
              kind: lr.read<String>('kind'),
              itemRefs: itemsByLesson[lid] ?? const <String>[],
              xpReward: lr.read<int>('xp_reward'),
            ),
          );
    }

    return unitRows.map((ur) {
      final uid = ur.read<String>('id');
      return UnitModel(
        id: uid,
        courseId: ur.read<String>('course_id'),
        title: ur.read<String>('title'),
        theme: ur.read<String>('theme'),
        order: ur.read<int>('sort_order'),
        level: ur.read<int>('level'),
        lessons: lessonsByUnit[uid] ?? const <LessonModel>[],
      );
    }).toList();
  }

  @override
  Future<UnitModel?> getUnit(String unitId) async {
    await db.ensureInitialized();
    final unitRows = await db
        .customSelect(
          'SELECT * FROM units WHERE id = ? LIMIT 1',
          variables: [Variable.withString(unitId)],
        )
        .get();
    if (unitRows.isEmpty) return null;
    final courseId = unitRows.first.read<String>('course_id');
    final allUnits = await getUnits(courseId);
    for (final u in allUnits) {
      if (u.id == unitId) return u;
    }
    return null;
  }

  @override
  Future<LessonModel?> getLesson(String lessonId) async {
    await db.ensureInitialized();
    final lr = await db
        .customSelect(
          'SELECT * FROM lessons WHERE id = ? LIMIT 1',
          variables: [Variable.withString(lessonId)],
        )
        .get();
    if (lr.isEmpty) return null;
    final row = lr.first;
    final itemRows = await db
        .customSelect(
          'SELECT item_id FROM lesson_items WHERE lesson_id = ? ORDER BY sort_order ASC',
          variables: [Variable.withString(lessonId)],
        )
        .get();

    return LessonModel(
      id: row.read<String>('id'),
      courseId: row.read<String>('course_id'),
      unitId: row.read<String>('unit_id'),
      order: row.read<int>('sort_order'),
      kind: row.read<String>('kind'),
      itemRefs: itemRows.map((r) => r.read<String>('item_id')).toList(),
      xpReward: row.read<int>('xp_reward'),
    );
  }

  @override
  Future<List<WordModel>> getWords(
    String courseId, {
    String? category,
    String? query,
  }) async {
    await db.ensureInitialized();
    final rows = await db
        .customSelect(
          'SELECT * FROM words WHERE course_id = ? AND deprecated = 0 ORDER BY id ASC',
          variables: [Variable.withString(courseId)],
        )
        .get();

    var list = rows.map((r) => WordModel.fromJson(r.data)).toList();

    if (category != null && category.isNotEmpty && category != 'semua') {
      list = list.where((w) => w.category == category).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list
          .where(
            (w) =>
                w.deli.toLowerCase().contains(q) ||
                w.indonesia.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  @override
  Future<List<PhraseModel>> getPhrases(String courseId) async {
    await db.ensureInitialized();
    final rows = await db
        .customSelect(
          'SELECT * FROM phrases WHERE course_id = ? AND deprecated = 0 ORDER BY id ASC',
          variables: [Variable.withString(courseId)],
        )
        .get();
    return rows
        .map(
          (r) => PhraseModel(
            id: r.read<String>('id'),
            courseId: r.read<String>('course_id'),
            deli: r.read<String>('deli'),
            indonesia: r.read<String>('indonesia'),
            jawi: r.readNullable<String>('jawi'),
            level: r.read<int>('level'),
            unitId: r.read<String>('unit_id'),
            audioPath: r.readNullable<String>('audio_path'),
            culturalNote: r.readNullable<String>('cultural_note'),
            validationStatus: r.read<String>('validation_status'),
            deprecated: r.read<int>('deprecated') == 1,
          ),
        )
        .toList();
  }

  @override
  Future<List<SentenceModel>> getSentences(String courseId) async {
    await db.ensureInitialized();
    final rows = await db
        .customSelect(
          'SELECT * FROM sentences WHERE course_id = ? AND deprecated = 0 ORDER BY id ASC',
          variables: [Variable.withString(courseId)],
        )
        .get();
    return rows.map((r) => SentenceModel.fromJson(r.data)).toList();
  }

  @override
  Future<List<DialogueModel>> getDialogues(String courseId) async {
    await db.ensureInitialized();
    final dRows = await db
        .customSelect(
          'SELECT * FROM dialogues WHERE course_id = ? AND deprecated = 0 ORDER BY id ASC',
          variables: [Variable.withString(courseId)],
        )
        .get();
    final lRows = await db
        .customSelect(
          'SELECT * FROM dialogue_lines WHERE course_id = ? ORDER BY line_order ASC',
          variables: [Variable.withString(courseId)],
        )
        .get();

    final linesByDialogue = <String, List<DialogueLineModel>>{};
    for (final lr in lRows) {
      final did = lr.read<String>('dialogue_id');
      linesByDialogue
          .putIfAbsent(did, () => <DialogueLineModel>[])
          .add(DialogueLineModel.fromJson(lr.data));
    }

    return dRows.map((dr) {
      final did = dr.read<String>('id');
      return DialogueModel.fromJson(
        dr.data,
        linesByDialogue[did] ?? const <DialogueLineModel>[],
      );
    }).toList();
  }

  @override
  Future<List<JawiLetterModel>> getLetters(String courseId) async {
    await db.ensureInitialized();
    final rows = await db
        .customSelect(
          'SELECT * FROM letters WHERE course_id = ? AND deprecated = 0 ORDER BY id ASC',
          variables: [Variable.withString(courseId)],
        )
        .get();
    return rows.map((r) => JawiLetterModel.fromJson(r.data)).toList();
  }

  @override
  Future<List<ArticleModel>> getArticles(String courseId) async {
    await db.ensureInitialized();
    final rows = await db
        .customSelect(
          'SELECT * FROM articles WHERE course_id = ? AND deprecated = 0 ORDER BY id ASC',
          variables: [Variable.withString(courseId)],
        )
        .get();
    return rows.map((r) => ArticleModel.fromJson(r.data)).toList();
  }

  @override
  Future<ArticleModel?> getArticle(String articleId) async {
    await db.ensureInitialized();
    final rows = await db
        .customSelect(
          'SELECT * FROM articles WHERE id = ? LIMIT 1',
          variables: [Variable.withString(articleId)],
        )
        .get();
    if (rows.isEmpty) return null;
    return ArticleModel.fromJson(rows.first.data);
  }

  @override
  Future<List<CollectionCardModel>> getCollectionCards(String courseId) async {
    await db.ensureInitialized();
    final rows = await db
        .customSelect(
          'SELECT * FROM collection_cards WHERE course_id = ? AND deprecated = 0 ORDER BY id ASC',
          variables: [Variable.withString(courseId)],
        )
        .get();
    return rows.map((r) => CollectionCardModel.fromJson(r.data)).toList();
  }

  @override
  Future<List<QuizBankItemModel>> getQuizBank(
    String courseId, {
    String? lessonId,
    bool includeUnverified = false,
  }) async {
    await db.ensureInitialized();
    final rows = lessonId != null
        ? await db
              .customSelect(
                'SELECT * FROM quiz_bank WHERE course_id = ? AND lesson_id = ? AND deprecated = 0 ORDER BY id ASC',
                variables: [
                  Variable.withString(courseId),
                  Variable.withString(lessonId),
                ],
              )
              .get()
        : await db
              .customSelect(
                'SELECT * FROM quiz_bank WHERE course_id = ? AND deprecated = 0 ORDER BY id ASC',
                variables: [Variable.withString(courseId)],
              )
              .get();

    final items = rows.map((r) => QuizBankItemModel.fromJson(r.data)).toList();
    if (includeUnverified) return items;
    // Bagian 5.5 poin 4 & Bagian 14: saring soal needs_verification di mode normal.
    return items.where((q) => !q.needsVerification).toList();
  }

  @override
  Future<GameConfig> getGameConfig() async {
    if (_cachedConfig != null) return _cachedConfig!;
    try {
      final raw = await _loadAsset('assets/content/game_config.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _cachedConfig = GameConfig.fromJson(json);
      return _cachedConfig!;
    } catch (_) {
      _cachedConfig = const GameConfig();
      return _cachedConfig!;
    }
  }

  @override
  Future<List<AchievementModel>> getAchievements({
    Set<String> unlockedIds = const {},
  }) async {
    try {
      final raw = await _loadAsset('assets/content/achievements.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final list = (json['achievements'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      final now = DateTime.now();
      return list
          .map(
            (item) => AchievementModel.fromJson(
              item,
              unlockedAt: unlockedIds.contains(item['id']) ? now : null,
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<DialectReferenceModel>> getDialectReferences([
    String? courseId,
  ]) async {
    await db.ensureInitialized();
    final rows = courseId != null
        ? await db
              .customSelect(
                'SELECT * FROM dialect_references WHERE course_id = ? ORDER BY id ASC',
                variables: [Variable.withString(courseId)],
              )
              .get()
        : await db
              .customSelect(
                'SELECT * FROM dialect_references ORDER BY course_id ASC, id ASC',
              )
              .get();
    return rows.map((r) => DialectReferenceModel.fromJson(r.data)).toList();
  }

  @override
  Future<List<InstalledModuleModel>> getInstalledModules() async {
    await db.ensureInitialized();
    final rows = await db
        .customSelect(
          'SELECT * FROM installed_modules ORDER BY is_bundled DESC, course_id ASC',
        )
        .get();
    return rows.map((r) => InstalledModuleModel.fromJson(r.data)).toList();
  }

  @override
  Future<List<DialectComparisonRowModel>> getDialectComparisonRows({
    String? query,
  }) async {
    await db.ensureInitialized();
    const curatedComparisons = <DialectComparisonRowModel>[
      DialectComparisonRowModel(
        conceptId: 'cmp_01',
        indonesianTerm: 'apa',
        category: 'Kata Tanya',
        deliTerm: 'ape',
        deliPronunciation: '[apə]',
        langkatTerm: 'ape',
        langkatPronunciation: '[apə]',
        palembangTerm: 'apo (Sari-sari) / napi (Bebaso)',
        palembangPronunciation: '[apɔ] / [napi]',
        linguisticNote: 'Melayu Deli & Langkat melemahkan /-a/ akhir menjadi pepet [-ə], sedangkan Palembang membulatkannya menjadi [-ɔ].',
      ),
      DialectComparisonRowModel(
        conceptId: 'cmp_02',
        indonesianTerm: 'di mana / ke mana',
        category: 'Kata Tanya',
        deliTerm: 'di mane / ke mane',
        deliPronunciation: '[di manə]',
        langkatTerm: 'di mane / ke mane',
        langkatPronunciation: '[di manə]',
        palembangTerm: 'di mano (Sari-sari) / di pundi (Bebaso)',
        palembangPronunciation: '[di manɔ] / [di pundi]',
        linguisticNote: 'Dalam ragam Bebaso Palembang, kata tanya tempat menggunakan leksikon khusus "pundi".',
      ),
      DialectComparisonRowModel(
        conceptId: 'cmp_03',
        indonesianTerm: 'mengapa / kenapa',
        category: 'Kata Tanya',
        deliTerm: 'mengape / ngape',
        deliPronunciation: '[ŋapə]',
        langkatTerm: 'mengape / ngape',
        langkatPronunciation: '[ŋapə]',
        palembangTerm: 'ngapo / mengapo',
        palembangPronunciation: '[ŋapɔ]',
        linguisticNote: 'Peluluhan suku awal me- menghasilkan bentuk ringkas ngape (Deli/Langkat) dan ngapo (Palembang).',
      ),
      DialectComparisonRowModel(
        conceptId: 'cmp_04',
        indonesianTerm: 'bagaimana',
        category: 'Kata Tanya',
        deliTerm: 'macam mane / cemane',
        deliPronunciation: '[tʃəmanə]',
        langkatTerm: 'macam mane / camne',
        langkatPronunciation: '[tʃamnə]',
        palembangTerm: 'cakmano / makmano',
        palembangPronunciation: '[tʃaʔmanɔ]',
        linguisticNote: 'Dibentuk dari gabungan kata "macam/cak" (seperti) + "mana" (mane/mano).',
      ),
      DialectComparisonRowModel(
        conceptId: 'cmp_05',
        indonesianTerm: 'saya / aku',
        category: 'Pronomina',
        deliTerm: 'saye (santun) / aku / awak',
        deliPronunciation: '[sayə] / [aku]',
        langkatTerm: 'saye (santun) / aku / awak',
        langkatPronunciation: '[sayə] / [aku]',
        palembangTerm: 'kulo (Bebaso) / aku / kami (Sari-sari)',
        palembangPronunciation: '[kulɔ] / [aku]',
        linguisticNote: 'Palembang membedakan pronomina secara tegas antara tingkat tutur Alus (kulo) dan Sari-sari (aku/kami).',
      ),
      DialectComparisonRowModel(
        conceptId: 'cmp_06',
        indonesianTerm: 'kamu / Anda',
        category: 'Pronomina',
        deliTerm: 'awak / kau / engkau',
        deliPronunciation: '[awaʔ]',
        langkatTerm: 'awak / kau',
        langkatPronunciation: '[awaʔ]',
        palembangTerm: 'niko (Bebaso) / kau / awak (Sari-sari)',
        palembangPronunciation: '[nikɔ] / [kau]',
        linguisticNote: 'Kata "awak" di Sumatera Timur dan Sumatera Selatan dipakai luas sebagai sapaan sebaya yang akrab.',
      ),
      DialectComparisonRowModel(
        conceptId: 'cmp_07',
        indonesianTerm: 'kita semua',
        category: 'Pronomina',
        deliTerm: 'kite semue',
        deliPronunciation: '[kitə səmuə]',
        langkatTerm: 'kite semue',
        langkatPronunciation: '[kitə səmuə]',
        palembangTerm: 'kito galo',
        palembangPronunciation: '[kitɔ galɔ]',
        linguisticNote: 'Kuantor "galo" (semua) merupakan ciri leksikal khas Melayu Palembang ("Wong Kito Galo").',
      ),
      DialectComparisonRowModel(
        conceptId: 'cmp_08',
        indonesianTerm: 'tidak / tidak ada',
        category: 'Partikel & Ingkar',
        deliTerm: 'tak / tak ade',
        deliPronunciation: '[taʔ adə]',
        langkatTerm: 'tak / tak ade',
        langkatPronunciation: '[taʔ adə]',
        palembangTerm: 'dak / katek (Sari-sari), nedo (Bebaso)',
        palembangPronunciation: '[daʔ] / [kateʔ]',
        linguisticNote: 'Kontraksi "katek" (tidak ada) di Palembang berpadanan dengan "tak ade / takde" di Deli dan Langkat.',
      ),
      DialectComparisonRowModel(
        conceptId: 'cmp_09',
        indonesianTerm: 'sangat / sekali',
        category: 'Partikel & Penguat',
        deliTerm: 'kali / betul',
        deliPronunciation: '[kali]',
        langkatTerm: 'kali / betul',
        langkatPronunciation: '[kali] / [bətol]',
        palembangTerm: 'nian',
        palembangPronunciation: '[nian]',
        linguisticNote: '"Sedap kali" (Deli/Langkat) berpadanan langsung dengan "Lemak nian" (Palembang).',
      ),
      DialectComparisonRowModel(
        conceptId: 'cmp_10',
        indonesianTerm: 'saja',
        category: 'Partikel & Penguat',
        deliTerm: 'aje / saje',
        deliPronunciation: '[adʒə]',
        langkatTerm: 'aje / je',
        langkatPronunciation: '[adʒə]',
        palembangTerm: 'bae (Sari-sari) / kemawon (Bebaso)',
        palembangPronunciation: '[bae] / [kəmawɔn]',
        linguisticNote: 'Partikel pembatas "aje" di pesisir Sumatera Utara berkorespondensi dengan "bae" di Sumatera Selatan.',
      ),
      DialectComparisonRowModel(
        conceptId: 'cmp_11',
        indonesianTerm: 'air',
        category: 'Alam & Sungai',
        deliTerm: 'air / aye',
        deliPronunciation: '[aye]',
        langkatTerm: 'air / aye',
        langkatPronunciation: '[aye]',
        palembangTerm: 'banyu',
        palembangPronunciation: '[baɲu]',
        linguisticNote: 'Melayu Palembang menyerap dan melestarikan leksikon "banyu" untuk segala jenis air.',
      ),
      DialectComparisonRowModel(
        conceptId: 'cmp_12',
        indonesianTerm: 'pasar tradisional',
        category: 'Ruang Sosial',
        deliTerm: 'pajak / pekan',
        deliPronunciation: '[padʒaʔ] / [pəkan]',
        langkatTerm: 'pekan / pajak',
        langkatPronunciation: '[pəkan]',
        palembangTerm: 'pasar / kalangan',
        palembangPronunciation: '[pasaɾ] / [kalaŋan]',
        linguisticNote: 'Di Medan/Deli populer istilah "pajak" dan "pekan", di Langkat "pekan", sedangkan di Palembang "pasar" atau "kalangan".',
      ),
      DialectComparisonRowModel(
        conceptId: 'cmp_13',
        indonesianTerm: 'melihat / menjenguk',
        category: 'Tindakan Harian',
        deliTerm: 'tengok / menengok',
        deliPronunciation: '[teŋoʔ]',
        langkatTerm: 'tengok / menengok',
        langkatPronunciation: '[teŋoʔ]',
        palembangTerm: 'jingok / nyingok (Sari-sari), ningali (Bebaso)',
        palembangPronunciation: '[ɲiŋɔʔ] / [niŋali]',
        linguisticNote: 'Bentuk verba persepsi visual "tengok" (Deli/Langkat) berkorespondensi dengan "jingok/nyingok" (Palembang).',
      ),
      DialectComparisonRowModel(
        conceptId: 'cmp_14',
        indonesianTerm: 'mengobrol / berbincang',
        category: 'Tindakan Harian',
        deliTerm: 'berbual / cakap-cakap',
        deliPronunciation: '[bərbual]',
        langkatTerm: 'berbual / bercakap',
        langkatPronunciation: '[bərbual]',
        palembangTerm: 'begesah / bekotek',
        palembangPronunciation: '[bəgəsah]',
        linguisticNote: '"Berbual" di Sumatera Timur berarti mengobrol santai; di Palembang digunakan "begesah" (berkisah).',
      ),
      DialectComparisonRowModel(
        conceptId: 'cmp_15',
        indonesianTerm: 'enak / lezat',
        category: 'Kuliner & Rasa',
        deliTerm: 'sedap / lemak',
        deliPronunciation: '[sədap] / [ləmaʔ]',
        langkatTerm: 'sedap / lemak',
        langkatPronunciation: '[sədap]',
        palembangTerm: 'lemak',
        palembangPronunciation: '[ləmaʔ]',
        linguisticNote: 'Kata "lemak" dalam rumpun Melayu berarti gurih/lezat; di Palembang menjadi kata sifat utama untuk "enak".',
      ),
      DialectComparisonRowModel(
        conceptId: 'cmp_16',
        indonesianTerm: 'indah / cantik / bagus',
        category: 'Sifat & Apresiasi',
        deliTerm: 'elok / cantik',
        deliPronunciation: '[eloʔ]',
        langkatTerm: 'elok / molek',
        langkatPronunciation: '[eloʔ]',
        palembangTerm: 'cindo (cantik) / belagak (gagah)',
        palembangPronunciation: '[tʃindɔ] / [bəlagaʔ]',
        linguisticNote: 'Hati-hati: "elok" di Deli/Langkat berarti bagus, sedangkan "melok" di Palembang berarti "ikut"!',
      ),
      DialectComparisonRowModel(
        conceptId: 'cmp_17',
        indonesianTerm: 'kakek & nenek',
        category: 'Kekerabatan',
        deliTerm: 'Atok & Andung / Wan',
        deliPronunciation: '[atoʔ] & [andoŋ]',
        langkatTerm: 'Atok & Andung',
        langkatPronunciation: '[atoʔ] & [andoŋ]',
        palembangTerm: 'Yayi & Nyai',
        palembangPronunciation: '[yayi] & [ɲai]',
        linguisticNote: 'Sapaan Atok-Andung menjadi ciri khas Melayu Sumatera Timur, sedangkan Yayi-Nyai khas Palembang.',
      ),
      DialectComparisonRowModel(
        conceptId: 'cmp_18',
        indonesianTerm: 'rumah kediaman',
        category: 'Arsitektur & Adat',
        deliTerm: 'rumah / teratak (merendah)',
        deliPronunciation: '[təɾataʔ]',
        langkatTerm: 'rumah panggung / teratak',
        langkatPronunciation: '[təɾataʔ]',
        palembangTerm: 'rumah / bari (Sari-sari), rompok (Bebaso)',
        palembangPronunciation: '[ɾɔmpɔʔ]',
        linguisticNote: 'Dalam bertutur santun, Melayu Deli/Langkat menyebut rumah sendiri "teratak", sedangkan Palembang menggunakan "rompok".',
      ),
    ];

    if (query == null || query.trim().isEmpty) {
      return curatedComparisons;
    }
    final q = query.trim().toLowerCase();
    return curatedComparisons
        .where(
          (row) =>
              row.indonesianTerm.toLowerCase().contains(q) ||
              row.deliTerm.toLowerCase().contains(q) ||
              row.langkatTerm.toLowerCase().contains(q) ||
              row.palembangTerm.toLowerCase().contains(q) ||
              row.category.toLowerCase().contains(q),
        )
        .toList();
  }
}
