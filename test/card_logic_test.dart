import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:card_index/main.dart';

void main() {
  setUp(() {
    CardStorage.cards = [];
    CardStorage.keywords = [];
  });

  test(
      'keyword batch converts only plain keyword text and keeps hash wrappers intact',
      () {
    CardStorage.cards = [
      CardData(
        id: 'card-1',
        name: '테스트 카드',
        effect: '방어도 #방어도# [[테스트 카드]]',
        color: CardColor.ironclad,
        type: CardType.skill,
        cost: CardCost.cost1,
        imagePath: '',
      ),
    ];

    final changedCount = CardStorage.applyKeywordBatch('방어도');

    expect(changedCount, 1);
    expect(CardStorage.cards.first.effect, '[방어도] #방어도# [[테스트 카드]]');
  });

  test('duplicate name check ignores same card and catches other copies', () {
    CardStorage.cards = [
      CardData(
        id: 'card-1',
        name: '중복 카드',
        effect: '',
        color: CardColor.ironclad,
        type: CardType.skill,
        cost: CardCost.cost1,
        imagePath: '',
      ),
    ];

    expect(CardStorage.cardNameExists('중복 카드', excludeId: 'card-1'), isFalse);
    expect(CardStorage.cardNameExists('중복 카드'), isTrue);
  });

  test('token and special rarities are treated as one 기타 filter bucket', () {
    expect(CardData.rarityBucket(CardRarity.token), CardRarity.special);
    expect(CardData.rarityBucket(CardRarity.special), CardRarity.special);
    expect(
      CardData.matchesRarityBucket(CardRarity.special, CardRarity.token),
      isTrue,
    );
    expect(
      CardData.matchesRarityBucket(CardRarity.special, CardRarity.common),
      isFalse,
    );
  });

  test(
      'hash-wrapped keyword followed by a suffix remains searchable as one word',
      () {
    final text = '#영구#히';

    expect(KoreanSearchHelper.matches(text, '영구히'), isTrue);
    expect(KoreanSearchHelper.searchableEffect(text).contains('영구히'), isTrue);
  });

  test('bracketed keyword names resolve to the same keyword', () {
    CardStorage.keywords = [
      KeywordData(
        id: 'kw-1',
        name: '단조',
        description: '테스트 설명',
      ),
    ];

    expect(CardStorage.resolveKeyword('단조'), isNotNull);
    expect(CardStorage.resolveKeyword('[단조]'), isNotNull);
    expect(CardStorage.resolveKeyword('[단조]')?.name, '단조');
  });

  testWidgets('단조 keyword uses the normal tappable keyword popup',
      (tester) async {
    CardStorage.keywords = [
      KeywordData(
        id: 'kw-1',
        name: '단조',
        description: '일반 키워드 설명',
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InteractiveCardText(
            text: '[단조]',
            cardColor: CardColor.regent,
          ),
        ),
      ),
    );

    await tester.tap(find.text('단조'));
    await tester.pumpAndSettle();

    expect(find.text('일반 키워드 설명'), findsOneWidget);
  });

  testWidgets('cost display keeps numbers before energy and star icons',
      (tester) async {
    final card = CardData(
      id: 'card-regent',
      name: '테스트 카드',
      effect: '',
      color: CardColor.regent,
      type: CardType.skill,
      cost: CardCost.cost1,
      starCost: 3,
      imagePath: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CardPreviewHelper.buildCostDisplay(
            card: card,
            isUpgraded: false,
            displayColor: CardColor.regent,
            textStyle: const TextStyle(),
          ),
        ),
      ),
    );

    final row = tester.widget<Row>(find.byType(Row));
    final energyTextIndex = row.children.indexWhere(
      (child) => child is Text && child.data == '1',
    );
    final energyIconIndex = row.children.indexWhere(
      (child) =>
          child is Image &&
          child.image is AssetImage &&
          (child.image as AssetImage).assetName == CardColor.regent.iconPath,
    );
    final starTextIndex = row.children.indexWhere(
      (child) => child is Text && child.data == '3',
    );
    final starIconIndex = row.children.indexWhere(
      (child) =>
          child is Image &&
          child.image is AssetImage &&
          (child.image as AssetImage).assetName ==
              CardPreviewHelper.starIconPath,
    );

    expect(energyTextIndex, greaterThan(-1));
    expect(energyIconIndex, greaterThan(-1));
    expect(energyTextIndex < energyIconIndex, isTrue);
    expect(starTextIndex, greaterThan(-1));
    expect(starIconIndex, greaterThan(-1));
    expect(starTextIndex < starIconIndex, isTrue);
  });
}
