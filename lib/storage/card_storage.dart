part of '../main.dart';


class CardStorage {
  static List<CardData> cards = [];
  static List<KeywordData> keywords = [];
  static bool includeMultiplayer = true;
  static Set<String> favoriteCardIds = {};

  /// 앱 최초 실행 또는 DB 로드
  static Future<void> loadCards() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 즐겨찾기 ID 목록 독립 로드
    final favList = prefs.getStringList('user_favorite_card_ids') ?? [];
    favoriteCardIds = favList.toSet();

    // 2. 로컬 저장소 확인
    final String? dataString = prefs.getString('saved_card_database');
    final String? kwString = prefs.getString('saved_keyword_database');

    // 카드와 키워드는 별도 저장되므로 한쪽이 없어도 다른 쪽을 초기화하지 않음.
    if (dataString != null) {
      final List<dynamic> jsonList = jsonDecode(dataString);
      cards = jsonList.map((e) => CardData.fromJson(e)).toList();
    } else {
      await _loadDefaultCards();
      await saveCards();
    }

    if (kwString != null) {
      final List<dynamic> kwList = jsonDecode(kwString);
      keywords = kwList.map((e) => KeywordData.fromJson(e)).toList();
    } else {
      await _loadDefaultKeywords();
      await saveKeywords();
    }

    // 즐겨찾기 상태 동기화
    _syncFavorites();
  }

  /// 에셋의 기본 default_database.json으로 초기화
  static Future<void> resetToDefaultDatabase() async {
    try {
      await _loadDefaultCards();
      await _loadDefaultKeywords();

      _syncFavorites();
      await saveCards();
      await saveKeywords();
    } catch (e) {
      debugPrint('기본 DB 로드 실패: $e');
    }
  }

  static Future<void> _loadDefaultCards() async {
    final jsonString =
        await rootBundle.loadString('assets/data/default_database.json');
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is Map && decoded['cards'] != null) {
      final List<dynamic> jsonList = decoded['cards'];
      cards = jsonList.map((e) => CardData.fromJson(e)).toList();
    }
  }

  static Future<void> _loadDefaultKeywords() async {
    final jsonString =
        await rootBundle.loadString('assets/data/default_database.json');
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is Map && decoded['keywords'] != null) {
      final List<dynamic> kwList = decoded['keywords'];
      keywords = kwList.map((e) => KeywordData.fromJson(e)).toList();
    }
  }

  /// 즐겨찾기 토글 및 독립 저장
  static Future<void> toggleFavorite(CardData card) async {
    card.isFavorite = !card.isFavorite;
    if (card.isFavorite) {
      favoriteCardIds.add(card.id);
    } else {
      favoriteCardIds.remove(card.id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'user_favorite_card_ids', favoriteCardIds.toList());
    await saveCards();
  }

  static void _syncFavorites() {
    for (var c in cards) {
      c.isFavorite = favoriteCardIds.contains(c.id);
    }
  }

  static bool cardNameExists(String name, {String? excludeId}) {
    final normalized = name.trim();
    if (normalized.isEmpty) return false;

    return cards.any((card) =>
        card.name.trim() == normalized &&
        (excludeId == null || card.id != excludeId));
  }

  static KeywordData? resolveKeyword(String rawName) {
    final normalized = rawName
        .trim()
        .replaceAll(RegExp(r'^[\[\^#]+|[\]\^#]+$'), '')
        .trim();
    if (normalized.isEmpty) return null;

    for (final keyword in keywords) {
      final candidate = keyword.name.trim();
      if (candidate == normalized) return keyword;
    }

    return null;
  }

  static Future<void> saveCards() async {
    final prefs = await SharedPreferences.getInstance();
    final String dataString = jsonEncode(cards.map((e) => e.toJson()).toList());
    await prefs.setString('saved_card_database', dataString);
  }

  static Future<void> saveKeywords() async {
    final prefs = await SharedPreferences.getInstance();
    final String dataString =
        jsonEncode(keywords.map((e) => e.toJson()).toList());
    await prefs.setString('saved_keyword_database', dataString);
  }

  static int applyKeywordBatch(String keyword) {
    if (keyword.trim().isEmpty) return 0;
    final cleanKw = keyword.trim();
    int count = 0;
    final pattern = RegExp('(?<!\\[)${RegExp.escape(cleanKw)}(?!\\])');

    for (var card in cards) {
      bool modified = false;

      void applyToField(String? fieldText, void Function(String) assign) {
        if (fieldText == null || fieldText.isEmpty) return;

        final placeholders = <String, String>{};
        final masked = fieldText.replaceAllMapped(RegExp(r'#(.+?)#'), (match) {
          final token = '__HASH_${placeholders.length}__';
          placeholders[token] = match.group(1)!;
          return token;
        });

        final rewritten = masked.replaceAllMapped(pattern, (m) => '[$cleanKw]');
        var merged = rewritten;
        for (final entry in placeholders.entries) {
          merged = merged.replaceAll(entry.key, '#${entry.value}#');
        }

        if (merged != fieldText) {
          assign(merged);
          modified = true;
        }
      }

      applyToField(card.effect, (value) => card.effect = value);
      if (card.upgradedEffect != null && card.upgradedEffect!.isNotEmpty) {
        applyToField(card.upgradedEffect, (value) => card.upgradedEffect = value);
      }

      if (modified) count++;
    }

    return count;
  }

  static int applyAllKeywordsBatch() {
    int totalModifiedCards = 0;
    for (var kw in keywords) {
      totalModifiedCards += applyKeywordBatch(kw.name);
    }
    return totalModifiedCards;
  }

  /// 백업 생성 (하이브리드: assets 이미지는 경로만, 커스텀 로컬 이미지만 Base64)
  static Future<String> exportDatabaseJsonAsync({
    void Function(double progress, String status)? onProgress,
  }) async {
    final List<Map<String, dynamic>> exportedCards = [];
    final total = cards.length;

    for (int i = 0; i < total; i++) {
      exportedCards.add(cards[i].toExportJson());
      if (onProgress != null && (i % 5 == 0 || i == total - 1)) {
        onProgress((i + 1) / total, '카드 데이터 내보내는 중... (${i + 1}/$total)');
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }

    return jsonEncode({
      'cards': exportedCards,
      'keywords': keywords.map((e) => e.toJson()).toList(),
    });
  }

  /// 백업 복원
  static Future<bool> importDatabaseJsonAsync(
    String jsonString, {
    void Function(double progress, String status)? onProgress,
  }) async {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      final appDir = await getApplicationDocumentsDirectory();
      List<CardData> loaded = [];
      List<KeywordData> loadedKeywords = [];

      List<dynamic> jsonCards = [];
      if (decoded is Map && decoded['cards'] != null) {
        jsonCards = decoded['cards'];
        if (decoded['keywords'] != null) {
          loadedKeywords = (decoded['keywords'] as List)
              .map((e) => KeywordData.fromJson(e))
              .toList();
        }
      } else if (decoded is List) {
        jsonCards = decoded;
      }

      final total = jsonCards.length;

      for (int i = 0; i < total; i++) {
        final json = jsonCards[i];
        String imgPath = json['imagePath'] ?? '';
        String? upImgPath = json['upgradedImagePath'];

        // Base64 이미지가 포함된 커스텀 카드인 경우에만 로컬 파일로 디코딩
        if (json['base64Image'] != null) {
          final bytes = base64Decode(json['base64Image']);
          final file = File('${appDir.path}/card_${json['id']}_normal.png');
          await file.writeAsBytes(bytes);
          imgPath = file.path;
        }

        if (json['base64UpgradedImage'] != null) {
          final bytes = base64Decode(json['base64UpgradedImage']);
          final file = File('${appDir.path}/card_${json['id']}_upgraded.png');
          await file.writeAsBytes(bytes);
          upImgPath = file.path;
        }

        final Map<String, dynamic> variantPaths = {};
        if (json['base64Variants'] != null) {
          for (var entry in (json['base64Variants'] as Map).entries) {
            final bytes = base64Decode(entry.value);
            final file =
                File('${appDir.path}/card_${json['id']}_var_${entry.key}.png');
            await file.writeAsBytes(bytes);
            variantPaths[entry.key] = file.path;
          }
        }

        final Map<String, dynamic> upVariantPaths = {};
        if (json['base64UpgradedVariants'] != null) {
          for (var entry in (json['base64UpgradedVariants'] as Map).entries) {
            final bytes = base64Decode(entry.value);
            final file = File(
                '${appDir.path}/card_${json['id']}_upvar_${entry.key}.png');
            await file.writeAsBytes(bytes);
            upVariantPaths[entry.key] = file.path;
          }
        }

        json['imagePath'] = imgPath;
        json['upgradedImagePath'] = upImgPath;
        if (variantPaths.isNotEmpty) json['variantImages'] = variantPaths;
        if (upVariantPaths.isNotEmpty) {
          json['upgradedVariantImages'] = upVariantPaths;
        }

        loaded.add(CardData.fromJson(json));

        if (onProgress != null && (i % 5 == 0 || i == total - 1)) {
          onProgress((i + 1) / total, '이미지 및 데이터 복원 중... (${i + 1}/$total)');
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }

      cards = loaded;
      if (loadedKeywords.isNotEmpty) {
        keywords = loadedKeywords;
        await saveKeywords();
      }
      _syncFavorites();
      await saveCards();
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ==========================================
// 3. 헬퍼 유틸리티 및 기본 공통 위젯
// ==========================================

