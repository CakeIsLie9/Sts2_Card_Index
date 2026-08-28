part of '../main.dart';


// ==========================================
// 1. 데이터 모델 및 열거형 정의
// ==========================================

enum CardColor {
  ironclad('아이언클래드', 0xFFE53935, 0, 'assets/icons/ironclad.webp'),
  silent('사일런트', 0xFF43A047, 1, 'assets/icons/silent.webp'),
  regent('리젠트', 0xFFFB8C00, 2, 'assets/icons/regent.webp'),
  necrobinder('네크로바인더', 0xFFC15082, 3, 'assets/icons/necrobinder.webp'),
  defect('디펙트', 0xFF1E88E5, 4, 'assets/icons/defect.webp'),
  colorless('무색', 0xFF9E9E9E, 5, 'assets/icons/colorless.webp'),
  curse('저주', 0xFF8E24AA, 6, 'assets/icons/colorless.webp'),
  status('상태이상', 0xFF8D6E63, 7, 'assets/icons/colorless.webp'),
  quest('퀘스트', 0xFFF46D4C, 8, 'assets/icons/colorless.webp');

  final String label;
  final int colorHex;
  final int order;
  final String iconPath;
  const CardColor(this.label, this.colorHex, this.order, this.iconPath);

  static const List<CardColor> playableColors = [
    CardColor.ironclad,
    CardColor.silent,
    CardColor.regent,
    CardColor.necrobinder,
    CardColor.defect,
  ];
}

enum CardType {
  attack('공격', 0),
  skill('스킬', 1),
  power('파워', 2),
  other('기타', 3);

  final String label;
  final int order;
  const CardType(this.label, this.order);
}

enum CardRarity {
  token('토큰', 0, 0xFF9E9E9E),
  special('기타', 0, 0xFF9E9E9E),
  common('일반', 2, 0xFF90A4AE),
  uncommon('고급', 3, 0xFF26C6DA),
  rare('희귀', 4, 0xFFFFD700),
  event('이벤트', 5, 0xFF78CA76),
  ancient('고대', 6, 0xFFD0A9E8),
  starter('시작', 1, 0xFF78909C);

  final String label;
  final int order;
  final int colorHex;
  const CardRarity(this.label, this.order, this.colorHex);
}

enum CardCost {
  none('사용불가', -1.0),
  cost0('0', 0.0),
  cost1('1', 1.0),
  cost2('2', 2.0),
  cost3('3', 3.0),
  costX('X', 3.5),
  cost4Plus('4+', 4.0);

  final String label;
  final double value;
  const CardCost(this.label, this.value);
}

class CardData {
  String id;
  String name;
  String effect;
  CardColor color;
  CardType type;
  CardRarity rarity;
  CardCost cost;
  int? customCost;
  int? starCost;
  String imagePath;
  bool isMultiplayer;
  bool isFavorite;
  bool isRecentlyChanged;

  bool isSharedStarter;
  Map<CardColor, String> variantImages;
  Map<CardColor, String> upgradedVariantImages;

  String? upgradedImagePath;
  CardCost? upgradedCost;
  int? upgradedCustomCost;
  int? upgradedStarCost;
  String? upgradedEffect;
  String? description;

  CardData({
    required this.id,
    required this.name,
    required this.effect,
    required this.color,
    required this.type,
    this.rarity = CardRarity.common,
    required this.cost,
    this.customCost,
    this.starCost,
    required this.imagePath,
    this.isMultiplayer = false,
    this.isFavorite = false,
    this.isRecentlyChanged = false,
    this.isSharedStarter = false,
    Map<CardColor, String>? variantImages,
    Map<CardColor, String>? upgradedVariantImages,
    this.upgradedImagePath,
    this.upgradedCost,
    this.upgradedCustomCost,
    this.upgradedStarCost,
    this.upgradedEffect,
    this.description,
  })  : variantImages = variantImages ?? {},
        upgradedVariantImages = upgradedVariantImages ?? {};

  CardColor get logicalColor =>
      rarity == CardRarity.event ? CardColor.colorless : color;

  String getImagePathForColor(CardColor targetColor, bool isUpgraded) {
    if (isSharedStarter) {
      if (isUpgraded) {
        final upImg = upgradedVariantImages[targetColor];
        if (upImg != null && upImg.isNotEmpty) return upImg;
      }
      final normalImg = variantImages[targetColor];
      if (normalImg != null && normalImg.isNotEmpty) return normalImg;
    }
    if (isUpgraded &&
        upgradedImagePath != null &&
        upgradedImagePath!.isNotEmpty) {
      return upgradedImagePath!;
    }
    return imagePath;
  }

  String getCostLabel(bool isUpgraded) {
    final c = (isUpgraded && upgradedCost != null) ? upgradedCost! : cost;
    if (c == CardCost.cost4Plus) {
      final val = (isUpgraded && upgradedCost != null)
          ? (upgradedCustomCost ?? customCost ?? 4)
          : (customCost ?? 4);
      return '$val';
    }
    return c.label;
  }

  // 별 비용은 호환성을 위해 int를 유지하며, -1은 특수 비용 X로 표시함.
  // 별 비용 타입을 변경할 때는 이 변환과 JSON 저장/복원을 함께 수정할 것.
  String? getStarCostLabel(bool isUpgraded) {
    final value = (isUpgraded && upgradedStarCost != null)
        ? upgradedStarCost!
        : starCost;
    if (value == null) return null;
    return value == -1 ? 'X' : '$value';
  }

  double getCostValue(bool isUpgraded) {
    final c = (isUpgraded && upgradedCost != null) ? upgradedCost! : cost;
    if (c == CardCost.cost4Plus) {
      final val = (isUpgraded && upgradedCost != null)
          ? (upgradedCustomCost ?? customCost ?? 4)
          : (customCost ?? 4);
      return val.toDouble();
    }
    return c.value;
  }

  bool get hasUpgrade =>
      upgradedImagePath != null ||
      upgradedCost != null ||
      upgradedStarCost != null ||
      upgradedVariantImages.values.any((path) => path.isNotEmpty) ||
      (upgradedEffect != null && upgradedEffect!.isNotEmpty);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'effect': effect,
        'color': color.name,
        'type': type.name,
        'rarity': rarity.name,
        'cost': cost.name,
        'customCost': customCost,
        'starCost': starCost,
        'imagePath': imagePath,
        'isMultiplayer': isMultiplayer,
        'isFavorite': isFavorite,
        'isRecentlyChanged': isRecentlyChanged,
        'isSharedStarter': isSharedStarter,
        'variantImages': variantImages.map((k, v) => MapEntry(k.name, v)),
        'upgradedVariantImages':
            upgradedVariantImages.map((k, v) => MapEntry(k.name, v)),
        'upgradedImagePath': upgradedImagePath,
        'upgradedCost': upgradedCost?.name,
        'upgradedCustomCost': upgradedCustomCost,
        'upgradedStarCost': upgradedStarCost,
        'upgradedEffect': upgradedEffect,
        'description': description,
      };

  Map<String, dynamic> toExportJson() {
    String? base64Image;
    String? base64UpgradedImage;

    try {
      if (imagePath.isNotEmpty && File(imagePath).existsSync()) {
        base64Image = base64Encode(File(imagePath).readAsBytesSync());
      }
      if (upgradedImagePath != null &&
          upgradedImagePath!.isNotEmpty &&
          File(upgradedImagePath!).existsSync()) {
        base64UpgradedImage =
            base64Encode(File(upgradedImagePath!).readAsBytesSync());
      }
    } catch (_) {}

    final Map<String, String> base64Variants = {};
    variantImages.forEach((k, v) {
      try {
        if (v.isNotEmpty && File(v).existsSync()) {
          base64Variants[k.name] = base64Encode(File(v).readAsBytesSync());
        }
      } catch (_) {}
    });

    final Map<String, String> base64UpgradedVariants = {};
    upgradedVariantImages.forEach((k, v) {
      try {
        if (v.isNotEmpty && File(v).existsSync()) {
          base64UpgradedVariants[k.name] =
              base64Encode(File(v).readAsBytesSync());
        }
      } catch (_) {}
    });

    final map = toJson();
    map['base64Image'] = base64Image;
    map['base64UpgradedImage'] = base64UpgradedImage;
    map['base64Variants'] = base64Variants;
    map['base64UpgradedVariants'] = base64UpgradedVariants;
    return map;
  }

  factory CardData.fromJson(Map<String, dynamic> json) {
    CardColor parseColor(dynamic val) {
      if (val is int) return CardColor.values[val];
      return CardColor.values
          .firstWhere((e) => e.name == val, orElse: () => CardColor.ironclad);
    }

    CardType parseType(dynamic val) {
      if (val is int) return CardType.values[val];
      return CardType.values
          .firstWhere((e) => e.name == val, orElse: () => CardType.attack);
    }

    CardRarity parseRarity(dynamic val) {
      if (val == null) return CardRarity.common;
      if (val is int) {
        if (val >= 0 && val < CardRarity.values.length) {
          return CardRarity.values[val];
        }
        return CardRarity.common;
      }
      return CardRarity.values
          .firstWhere((e) => e.name == val, orElse: () => CardRarity.common);
    }

    CardCost parseCost(dynamic val) {
      if (val is int) return CardCost.values[val];
      return CardCost.values
          .firstWhere((e) => e.name == val, orElse: () => CardCost.cost1);
    }

    CardCost? parseUpgradedCost(dynamic val) {
      if (val == null) return null;
      if (val is int) return CardCost.values[val];
      return CardCost.values
          .firstWhere((e) => e.name == val, orElse: () => CardCost.cost1);
    }

    final Map<CardColor, String> parsedVariants = {};
    if (json['variantImages'] != null) {
      (json['variantImages'] as Map).forEach((k, v) {
        final c = CardColor.values
            .firstWhere((e) => e.name == k, orElse: () => CardColor.ironclad);
        parsedVariants[c] = v.toString();
      });
    }

    final Map<CardColor, String> parsedUpgradedVariants = {};
    if (json['upgradedVariantImages'] != null) {
      (json['upgradedVariantImages'] as Map).forEach((k, v) {
        final c = CardColor.values
            .firstWhere((e) => e.name == k, orElse: () => CardColor.ironclad);
        parsedUpgradedVariants[c] = v.toString();
      });
    }

    return CardData(
      id: json['id'],
      name: json['name'],
      effect: json['effect'],
      color: parseColor(json['color']),
      type: parseType(json['type']),
      rarity: parseRarity(json['rarity']),
      cost: parseCost(json['cost']),
      customCost: json['customCost'],
      starCost: json['starCost'],
      imagePath: json['imagePath'] ?? '',
      isMultiplayer: json['isMultiplayer'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
      isRecentlyChanged: json['isRecentlyChanged'] ?? false,
      isSharedStarter: json['isSharedStarter'] ?? false,
      variantImages: parsedVariants,
      upgradedVariantImages: parsedUpgradedVariants,
      upgradedImagePath: json['upgradedImagePath'],
      upgradedCost: parseUpgradedCost(json['upgradedCost']),
      upgradedCustomCost: json['upgradedCustomCost'],
      upgradedStarCost: json['upgradedStarCost'],
      upgradedEffect: json['upgradedEffect'] ?? json['upgradedEffectDiff'],
      description: json['description'],
    );
  }
}

class KeywordData {
  String id;
  String name;
  String description;
  bool isHidden;

  KeywordData({
    required this.id,
    required this.name,
    required this.description,
    this.isHidden = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'isHidden': isHidden,
      };

  factory KeywordData.fromJson(Map<String, dynamic> json) {
    return KeywordData(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isHidden: json['isHidden'] ?? false,
    );
  }
}

// ==========================================
// 2. 영구 저장 및 키워드/카드 DB 엔진 (기본 에셋 탑재 & 즐겨찾기 분리)
// ==========================================

