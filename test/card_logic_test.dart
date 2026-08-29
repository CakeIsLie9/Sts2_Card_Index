import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:card_index/main.dart';

void main() {
  setUp(() {
    CardStorage.cards = [];
    CardStorage.keywords = [];
  });

  test('keyword batch converts only plain keyword text and keeps hash wrappers intact', () {
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

  test('hash-wrapped keyword followed by a suffix remains searchable as one word', () {
    final text = '#영구#히';

    expect(KoreanSearchHelper.matches(text, '영구히'), isTrue);
    expect(KoreanSearchHelper.searchableEffect(text).contains('영구히'), isTrue);
  });

  testWidgets('regent star cost keeps the number before the star icon', (tester) async {
    final card = CardData(
      id: 'card-regent-star',
      name: '별 비용 카드',
      effect: '테스트',
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
            iconSize: 14,
            textStyle: const TextStyle(fontSize: 13),
          ),
        ),
      ),
    );

    final row = tester.widget<Row>(find.byType(Row));
    final children = row.children;

    expect(children[0], isA<Text>());
    expect((children[0] as Text).data, '1');
    expect((children[2] as Image).image, isNotNull);
    expect(children[4], isA<Text>());
    expect((children[4] as Text).data, '3');
    expect(children[6], isA<Image>());
  });
}
