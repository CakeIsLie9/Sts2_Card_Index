part of '../main.dart';


class KoreanSearchHelper {
  static const List<String> _initialConsonants = [
    'ㄱ',
    'ㄲ',
    'ㄴ',
    'ㄷ',
    'ㄸ',
    'ㄹ',
    'ㅁ',
    'ㅂ',
    'ㅃ',
    'ㅅ',
    'ㅆ',
    'ㅇ',
    'ㅈ',
    'ㅉ',
    'ㅊ',
    'ㅋ',
    'ㅌ',
    'ㅍ',
    'ㅎ'
  ];

  /// 대상 문자열에서 한글 음절을 초성으로 변환
  static String extractChosung(String text) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (code >= 0xAC00 && code <= 0xD7A3) {
        final initialIndex = (code - 0xAC00) ~/ (21 * 28);
        buffer.write(_initialConsonants[initialIndex]);
      } else {
        buffer.write(text[i]);
      }
    }
    return buffer.toString();
  }

  /// [카드명/키워드명 전용] 일반 텍스트 매칭 + 초성 매칭 모두 허용
  static bool matches(String target, String query) {
    final cleanTarget = target
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAllMapped(RegExp(r'#(.+?)#'), (match) => match.group(1)!)
        .replaceAll('#', '');
    final cleanQuery = query.toLowerCase().replaceAll(' ', '');
    if (cleanQuery.isEmpty) return true;

    // 1. 일반 부분 일치 확인
    if (cleanTarget.contains(cleanQuery)) return true;

    // 2. 검색어가 초성/알파벳/숫자인 경우 초성 일치 확인
    final isQueryChosungOnly =
        RegExp(r'^[ㄱ-ㅎ0-9a-zA-Z]+$').hasMatch(cleanQuery);
    if (isQueryChosungOnly) {
      final targetChosung = extractChosung(cleanTarget);
      if (targetChosung.contains(cleanQuery)) return true;
    }

    return false;
  }

  /// [카드 효과/설명 전용] 오직 일반 텍스트 부분 일치만 허용 (초성 매칭 배제)
  static bool matchesPlainOnly(String target, String query) {
    final cleanTarget = target.toLowerCase().replaceAll(' ', '');
    final cleanQuery = query.toLowerCase().replaceAll(' ', '');
    if (cleanQuery.isEmpty) return true;

    // 검색어가 초성 자음(ㄱ-ㅎ)을 포함하고 있다면 효과에서는 무조건 제외
    if (RegExp(r'[ㄱ-ㅎ]').hasMatch(cleanQuery)) {
      return false;
    }

    return cleanTarget.contains(cleanQuery);
  }

  static String searchableEffect(String effect) {
    var searchable = effect
      .replaceAllMapped(
        RegExp(r'\[\[\^(.+?)\^\]\]'), (match) => match.group(1)!)
      .replaceAllMapped(RegExp(r'\[\^(.+?)\^\]'), (match) => match.group(1)!)
      .replaceAllMapped(RegExp(r'\[\[(.*?)\]\]'), (match) => match.group(1)!)
      .replaceAllMapped(RegExp(r'\[(.*?)\]'), (match) => match.group(1)!)
      .replaceAllMapped(RegExp(r'\^(.*?)\^'), (match) => match.group(1)!)
      .replaceAllMapped(RegExp(r'#(.+?)#'), (match) => match.group(1)!)
      .replaceAll('#', '')
      .replaceAll('@', ' 에너지 ')
      .replaceAll('*', ' 별 ');
    return searchable.toLowerCase();
  }
}

// ==========================================
// 에셋 / 로컬 파일 자동 판별 이미지 위젯
// ==========================================

class AppCardImage extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;

  const AppCardImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return const Icon(Icons.image, color: Colors.grey);
    }
    // 경로가 assets/ 로 시작하면 앱 내장 에셋에서 로드
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (c, o, s) =>
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
    // 그 외(갤러리 등에서 추가한 로컬 파일)는 File로 로드
    return Image.file(
      File(imagePath),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (c, o, s) =>
          const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}

class AppToast {
  static OverlayEntry? _toastEntry;
  static Timer? _toastTimer;

  static void show(BuildContext context, String message) {
    _toastTimer?.cancel();
    _toastEntry?.remove();
    _toastEntry = null;

    final overlay = Overlay.of(context, rootOverlay: true);

    _toastEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        bottom: 72.0,
        left: 32.0,
        right: 32.0,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xDD1D2C35),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24, width: 0.8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFontManager.fontFamily,
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_toastEntry!);
    _toastTimer = Timer(const Duration(milliseconds: 2000), () {
      _toastEntry?.remove();
      _toastEntry = null;
    });
  }
}

class AnimatedPopupBox extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDismissed;

  static _AnimatedPopupBoxState? _activeState;

  const AnimatedPopupBox({
    super.key,
    required this.child,
    this.onDismissed,
  });

  static void dismissCurrent() {
    _activeState?.dismiss();
  }

  @override
  State<AnimatedPopupBox> createState() => _AnimatedPopupBoxState();
}

class _AnimatedPopupBoxState extends State<AnimatedPopupBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    AnimatedPopupBox._activeState = this;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  void dismiss() {
    if (_controller.isAnimating) {
      _controller.stop();
    }
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismissed?.call();
      }
    });
  }

  @override
  void dispose() {
    if (AnimatedPopupBox._activeState == this) {
      AnimatedPopupBox._activeState = null;
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

// ==========================================
// 4. 인라인 텍스트 파서 및 커스텀 UI 위젯
// ==========================================

class CardPreviewHelper {
  static OverlayEntry? _currentEntry;

  static Offset _popupOffset({
    required Rect targetRect,
    required Size screenSize,
    required double popupWidth,
    required double popupHeight,
  }) {
    const margin = 12.0;
    const gap = 8.0;
    final rightTop = Offset(targetRect.right + gap, targetRect.top);
    if (rightTop.dx + popupWidth <= screenSize.width - margin &&
        rightTop.dy + popupHeight <= screenSize.height - margin) {
      return rightTop;
    }

    final leftTop = Offset(targetRect.left - popupWidth - gap, targetRect.top);
    if (leftTop.dx >= margin &&
        leftTop.dy + popupHeight <= screenSize.height - margin) {
      return leftTop;
    }

    final bottomLeft = Offset(
      targetRect.left.clamp(margin, screenSize.width - popupWidth - margin),
      (targetRect.bottom + gap).clamp(
          margin, screenSize.height - popupHeight - margin),
    );
    return bottomLeft;
  }

  static void hide() {
    if (_currentEntry != null) {
      AnimatedPopupBox.dismissCurrent();
      return;
    }
  }

  static Widget buildCostDisplay({
    required CardData card,
    required bool isUpgraded,
    required CardColor displayColor,
    double iconSize = 14,
    TextStyle? textStyle,
  }) {
    final cost = (isUpgraded && card.upgradedCost != null)
        ? card.upgradedCost!
        : card.cost;
    final starValue = (isUpgraded && card.upgradedStarCost != null)
        ? card.upgradedStarCost!
        : card.starCost;

    if (cost == CardCost.none) {
      return const SizedBox.shrink();
    }

    final baseLabel = cost == CardCost.cost4Plus
        ? ((isUpgraded && card.upgradedCost != null)
                ? (card.upgradedCustomCost ?? card.customCost ?? 4)
                : (card.customCost ?? 4))
            .toString()
        : cost.label;

    final children = <Widget>[
      Text(
        baseLabel,
        style: textStyle ??
            const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(width: 2),
      Image.asset(
        displayColor.iconPath,
        width: iconSize,
        height: iconSize,
        errorBuilder: (c, o, s) => Icon(
          Icons.circle,
          size: iconSize * 0.9,
          color: Color(displayColor.colorHex),
        ),
      ),
    ];

    if (displayColor == CardColor.regent && starValue != null && starValue != -1) {
      children.addAll([
        const SizedBox(width: 4),
        Image.asset(
          'assets/icons/star.webp',
          width: iconSize,
          height: iconSize,
          errorBuilder: (c, o, s) => Icon(
            Icons.star,
            size: iconSize,
            color: Colors.cyanAccent,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          starValue.toString(),
          style: textStyle ??
              const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
        ),
      ]);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  /// 카드 롱탭 미리보기 팝업 (기존 파라미터 100% 일치 + AppCardImage 적용)
  static void show({
    required BuildContext context,
    required CardData card,
    required bool isUpgraded,
    required Rect targetRect,
    CardColor? variantColor,
    bool showThumbnail = true,
  }) {
    hide();

    final overlayState = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = variantColor ??
        (card.isSharedStarter ? CardColor.ironclad : card.color);

    final displayImage = card.getImagePathForColor(effectiveColor, isUpgraded);
    final displayEffect = (isUpgraded &&
            card.upgradedEffect != null &&
            card.upgradedEffect!.isNotEmpty)
        ? card.upgradedEffect!
        : card.effect;
    final displayCostLabel = card.getCostDisplayText(isUpgraded);
    final isUnplayable = ((isUpgraded && card.upgradedCost != null)
        ? card.upgradedCost!
        : card.cost) ==
      CardCost.none;
    const popupWidth = 248.0;
    const popupHeight = 190.0;
    final popupOffset = _popupOffset(
      targetRect: targetRect,
      screenSize: screenSize,
      popupWidth: popupWidth,
      popupHeight: popupHeight,
    );

    _currentEntry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: hide,
              child: Container(color: Colors.black54),
            ),
          ),
          Positioned(
            left: popupOffset.dx,
            top: popupOffset.dy,
            child: AnimatedPopupBox(
              onDismissed: () {
                _currentEntry?.remove();
                _currentEntry = null;
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: popupWidth,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2529),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF557887),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF202020),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(7)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                card.name + (isUpgraded ? '+' : ''),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                  fontFamily: AppFontManager.fontFamily,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isUnplayable) ...[
                              Text(
                                displayCostLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showThumbnail && displayImage.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: SizedBox(
                                  width: 54,
                                  height: 72,
                                  child: AppCardImage(
                                    imagePath: displayImage,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: InteractiveCardText(
                                text: displayEffect,
                                cardColor: effectiveColor,
                                baseStyle: const TextStyle(
                                  fontSize: 12,
                                  height: 1.35,
                                  color: Color(0xFFE5E7E9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlayState.insert(_currentEntry!);
  }

  /// 키워드 클릭 팝업
  static void showKeyword({
    required BuildContext context,
    required KeywordData keyword,
    required Rect targetRect,
    CardData? relatedCard,
  }) {
    hide();

    final overlayState = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;
    const double popupWidth = 220.0;
    const double cardPopupWidth = 248.0;
    const double popupGap = 8.0;
    final combinedWidth = relatedCard == null
        ? popupWidth
        : popupWidth + popupGap + cardPopupWidth;
    const popupHeight = 220.0;
    final popupOffset = _popupOffset(
      targetRect: targetRect,
      screenSize: screenSize,
      popupWidth: combinedWidth,
      popupHeight: popupHeight,
    );

    _currentEntry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: hide,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: popupOffset.dx,
            top: popupOffset.dy,
            child: AnimatedPopupBox(
              onDismissed: () {
                _currentEntry?.remove();
                _currentEntry = null;
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKeywordPopupPanel(keyword, popupWidth),
                  if (relatedCard != null) ...[
                    const SizedBox(width: popupGap),
                    _buildRelatedCardPopupPanel(relatedCard, cardPopupWidth),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    overlayState.insert(_currentEntry!);
  }

  static Widget _buildKeywordPopupPanel(
      KeywordData keyword, double popupWidth) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: popupWidth,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2529),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF557887),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      keyword.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE7C66A),
                        fontFamily: AppFontManager.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      keyword.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFE5E7E9),
                        height: 1.35,
                        fontFamily: AppFontManager.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            );
  }

  static Widget _buildRelatedCardPopupPanel(CardData card, double popupWidth) {
    final color = card.isSharedStarter ? CardColor.ironclad : card.color;
    final isUnplayable = card.cost == CardCost.none;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: popupWidth,
        decoration: BoxDecoration(
          color: const Color(0xFF1B2529),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(color.colorHex), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF202020),
                borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      card.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: AppFontManager.fontFamily,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isUnplayable) ...[
                    CardPreviewHelper.buildCostDisplay(
                      card: card,
                      isUpgraded: false,
                      displayColor: color,
                      iconSize: 13,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (card.imagePath.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        width: 54,
                        height: 72,
                        child: AppCardImage(
                          imagePath: card.imagePath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: InteractiveCardText(
                      text: card.effect,
                      cardColor: color,
                      baseStyle: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Color(0xFFE5E7E9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 순수 TextSpan 기반 인라인 카드 파서 (폰트 크기 미세 불일치 완전 해결)
// ==========================================

class InteractiveCardText extends StatelessWidget {
  final String text;
  final CardColor cardColor;
  final TextStyle? baseStyle;
  final bool onlyLinks;

  const InteractiveCardText({
    super.key,
    required this.text,
    required this.cardColor,
    this.baseStyle,
    this.onlyLinks = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalizedText = text
        .replaceAllMapped(
          RegExp(r'\[\[\^(.+?)\^\]\]'),
          (match) => '^[[${match.group(1)}]]^',
        )
        .replaceAllMapped(
          RegExp(r'\[\^(.+?)\^\]'),
          (match) => '^[${match.group(1)}]^',
        )
        .replaceAllMapped(RegExp(r'#(.+?)#'), (match) => match.group(1)!);

    final defaultStyle = TextStyle(
      fontSize: 14.0,
      height: 1.5,
      color: isDark ? Colors.white : const Color(0xFF1E293B),
      fontFamily: AppFontManager.fontFamily,
    );

    final effectiveStyle = baseStyle != null
        ? defaultStyle.merge(baseStyle)
        : defaultStyle;

    if (onlyLinks) {
      final linkRegex = RegExp(r'\[\[(.*?)\]\]');
      final matches = linkRegex.allMatches(normalizedText);
      if (matches.isEmpty) return Text(text, style: effectiveStyle);

      final spans = <InlineSpan>[];
      int lastIndex = 0;
      for (final match in matches) {
        if (match.start > lastIndex) {
          spans.add(TextSpan(
            text: normalizedText.substring(lastIndex, match.start),
            style: effectiveStyle,
          ));
        }
        spans.add(
            _buildCardSpan(context, match.group(1)!, false, effectiveStyle, isDark));
        lastIndex = match.end;
      }
      if (lastIndex < normalizedText.length) {
        spans.add(TextSpan(
          text: normalizedText.substring(lastIndex),
          style: effectiveStyle,
        ));
      }
      return Text.rich(TextSpan(children: spans), style: effectiveStyle);
    }

    final blockRegex = RegExp(r'\^(.*?)\^');
    final blockMatches = blockRegex.allMatches(normalizedText);

    final spans = <InlineSpan>[];
    int lastIdx = 0;

    for (final bMatch in blockMatches) {
      if (bMatch.start > lastIdx) {
        spans.addAll(_parseInnerContent(
          context,
          normalizedText.substring(lastIdx, bMatch.start),
          false,
          effectiveStyle,
          isDark,
        ));
      }
      spans.addAll(_parseInnerContent(
        context,
        bMatch.group(1)!,
        true,
        effectiveStyle,
        isDark,
      ));
      lastIdx = bMatch.end;
    }

    if (lastIdx < normalizedText.length) {
      spans.addAll(_parseInnerContent(
        context,
        normalizedText.substring(lastIdx),
        false,
        effectiveStyle,
        isDark,
      ));
    }

    return Text.rich(TextSpan(children: spans), style: effectiveStyle);
  }

  List<InlineSpan> _parseInnerContent(
    BuildContext context,
    String content,
    bool isEnhancedBlock,
    TextStyle effectiveStyle,
    bool isDark,
  ) {
    final spans = <InlineSpan>[];
    final innerRegex = RegExp(r'(\[\[(.*?)\]\]|\[(.*?)\]|(@|\*))');
    final matches = innerRegex.allMatches(content);

    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        final plainText = content.substring(lastIndex, match.start);
        spans.add(TextSpan(
          text: plainText,
          style: isEnhancedBlock
              ? effectiveStyle.copyWith(
                  color: isDark
                      ? const Color(0xFFAAFB50)
                      : const Color(0xFF437A0B),
                  fontWeight: FontWeight.bold,
                )
              : effectiveStyle,
        ));
      }

      final cardLink = match.group(2);
      final keyword = match.group(3);
      final symbol = match.group(4);

      if (cardLink != null) {
        spans.add(_buildCardSpan(
            context, cardLink, isEnhancedBlock, effectiveStyle, isDark));
      } else if (keyword != null) {
        spans.add(_buildKeywordSpan(
            context, keyword, isEnhancedBlock, effectiveStyle, isDark));
      } else if (symbol != null) {
        Widget iconWidget;
        if (symbol == '*') {
          if (cardColor == CardColor.regent) {
            iconWidget = Image.asset(
              'assets/icons/star.webp',
              width: 16,
              height: 16,
              errorBuilder: (c, o, s) =>
                  const Icon(Icons.star, color: Colors.cyanAccent, size: 16),
            );
          } else {
            iconWidget = Text('*', style: effectiveStyle);
          }
        } else if (symbol == '@') {
          iconWidget = Image.asset(
            cardColor.iconPath,
            width: 16,
            height: 16,
            errorBuilder: (c, o, s) =>
                Icon(Icons.circle, color: Color(cardColor.colorHex), size: 14),
          );
        } else {
          iconWidget = const SizedBox.shrink();
        }

        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: iconWidget,
          ),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < content.length) {
      final plainText = content.substring(lastIndex);
      spans.add(TextSpan(
        text: plainText,
        style: isEnhancedBlock
            ? effectiveStyle.copyWith(
                color:
                    isDark ? const Color(0xFFAAFB50) : const Color(0xFF437A0B),
                fontWeight: FontWeight.bold,
              )
            : effectiveStyle,
      ));
    }

    return spans;
  }

  InlineSpan _buildCardSpan(
    BuildContext context,
    String rawName,
    bool isEnh,
    TextStyle baseStyle,
    bool isDark,
  ) {
    String cleanName = rawName.trim();
    final isUp = cleanName.endsWith('+');
    if (isUp) cleanName = cleanName.substring(0, cleanName.length - 1).trim();

    CardData? card;
    try {
      card = CardStorage.cards.firstWhere((c) => c.name == cleanName);
    } catch (_) {}

    final linkColor =
        isDark ? const Color(0xFFFFD54F) : const Color(0xFFB45309);

    if (card == null) {
      return TextSpan(
        text: rawName,
        style: baseStyle.copyWith(
          color: Colors.grey,
          decoration: TextDecoration.lineThrough,
        ),
      );
    }

    final linkStyle = baseStyle.copyWith(
      color: linkColor,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.underline,
      decorationColor: linkColor,
      backgroundColor: isEnh ? const Color(0x55AAFB50) : null,
      fontSize: baseStyle.fontSize,
      height: baseStyle.height,
      fontFamily: baseStyle.fontFamily,
    );

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Builder(
        builder: (linkContext) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            CardPreviewHelper.hide();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CardDetailScreen(
                  card: card!,
                  initialUpgraded: isUp,
                ),
              ),
            );
          },
          onLongPress: () {
            final box = linkContext.findRenderObject() as RenderBox?;
            final rect = box == null
                ? const Rect.fromLTWH(0, 0, 0, 0)
                : box.localToGlobal(Offset.zero) & box.size;
            CardPreviewHelper.show(
              context: context,
              card: card!,
              isUpgraded: isUp,
              targetRect: rect,
              variantColor: card!.isSharedStarter
                  ? CardColor.ironclad
                  : card!.color,
              showThumbnail: true,
            );
          },
          child: Text(rawName, style: linkStyle),
        ),
      ),
    );
  }

  InlineSpan _buildKeywordSpan(
    BuildContext context,
    String kwName,
    bool isEnh,
    TextStyle baseStyle,
    bool isDark,
  ) {
    KeywordData? kw;
    try {
      kw = CardStorage.keywords
          .firstWhere((k) => k.name.trim() == kwName.trim());
    } catch (_) {}

    final linkColor =
        isDark ? const Color(0xFFFFD54F) : const Color(0xFFB45309);

    if (kw == null) {
      return TextSpan(
        text: kwName,
        style: baseStyle.copyWith(
          color: linkColor,
          fontWeight: FontWeight.bold,
          backgroundColor: isEnh ? const Color(0x55AAFB50) : null,
        ),
      );
    }

    final keywordStyle = baseStyle.copyWith(
      color: linkColor,
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.none,
      backgroundColor: isEnh ? const Color(0x55AAFB50) : null,
      fontSize: baseStyle.fontSize,
      height: baseStyle.height,
      fontFamily: baseStyle.fontFamily,
    );

    void showKeywordPopup(BuildContext linkContext) {
      final box = linkContext.findRenderObject() as RenderBox?;
      final rect = box == null
          ? const Rect.fromLTWH(0, 0, 0, 0)
          : box.localToGlobal(Offset.zero) & box.size;
      CardData? relatedCard;
      if (kwName == '단조') {
        final matchingCards = CardStorage.cards
            .where((card) => card.name.trim() == '군주의 칼날')
            .toList();
        if (matchingCards.length == 1) relatedCard = matchingCards.single;
      }
      if (kw == null) return;
      if (kw == null) return;
      CardPreviewHelper.showKeyword(
        context: context,
        keyword: kw,
        targetRect: rect,
        relatedCard: relatedCard,
      );
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Builder(
        builder: (linkContext) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showKeywordPopup(linkContext),
          onLongPress: () => showKeywordPopup(linkContext),
          child: Text(kwName, style: keywordStyle),
        ),
      ),
    );
  }
}

// ==========================================
// 1줄 검색 효과 텍스트 파서 & 통합 공용 타일
// ==========================================

class SearchEffectText extends StatelessWidget {
  final String text;
  final CardColor cardColor;

  const SearchEffectText({
    super.key,
    required this.text,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseStyle = TextStyle(
      fontSize: 13,
      color: isDark ? const Color(0xFFB0BEC5) : const Color(0xFF475569),
      fontFamily: AppFontManager.fontFamily,
    );
    final renderText = text.replaceAllMapped(
      RegExp(r'#(.+?)#'),
      (match) => match.group(1)!,
    );
    final regex = RegExp(
        r'(\^\[\[(.*?)\]\]\^|\[\[(.*?)\^\]\]|\^\[(.*?)\]\^|\[\^(.*?)\^\]|\[\[(.*?)\]\]|\[(.*?)\]|\^(.*?)\^|(@|\*))');
    final matches = regex.allMatches(renderText);

    if (matches.isEmpty) {
      return Text(
        renderText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    final spans = <InlineSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: renderText.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      final enhLink1 = match.group(2);
      final enhLink2 = match.group(3);
      final enhKw1 = match.group(4);
      final enhKw2 = match.group(5);
      final regLink = match.group(6);
      final regKw = match.group(7);
      final highlightText = match.group(8);
      final symbol = match.group(9);

      if (enhLink1 != null ||
          enhLink2 != null ||
          enhKw1 != null ||
          enhKw2 != null) {
        final content = enhLink1 ?? enhLink2 ?? enhKw1 ?? enhKw2!;
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(
            color: const Color(0xFFFFD54F),
            backgroundColor: const Color(0x55AAFB50),
            fontWeight: FontWeight.bold,
            fontSize: baseStyle.fontSize,
            height: baseStyle.height,
            fontFamily: baseStyle.fontFamily,
          ),
        ));
      } else if (regLink != null || regKw != null) {
        final content = regLink ?? regKw!;
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(
            color: const Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
            fontSize: baseStyle.fontSize,
            height: baseStyle.height,
            fontFamily: baseStyle.fontFamily,
          ),
        ));
      } else if (highlightText != null) {
        spans.add(TextSpan(
          text: highlightText,
          style: baseStyle.copyWith(
            color: const Color(0xFFAAFB50),
            fontWeight: FontWeight.bold,
            fontSize: baseStyle.fontSize,
            height: baseStyle.height,
            fontFamily: baseStyle.fontFamily,
          ),
        ));
      } else if (symbol != null) {
        Widget iconWidget;
        if (symbol == '*') {
          if (cardColor == CardColor.regent) {
            iconWidget = Image.asset(
              'assets/icons/star.webp',
              width: 14,
              height: 14,
              errorBuilder: (c, o, s) =>
                  const Icon(Icons.star, color: Colors.cyanAccent, size: 14),
            );
          } else {
            iconWidget = Text('*', style: baseStyle);
          }
        } else if (symbol == '@') {
          iconWidget = Image.asset(
            cardColor.iconPath,
            width: 14,
            height: 14,
            errorBuilder: (c, o, s) =>
                Icon(Icons.circle, color: Color(cardColor.colorHex), size: 12),
          );
        } else {
          iconWidget = const SizedBox.shrink();
        }

        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: iconWidget,
          ),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < renderText.length) {
      spans.add(TextSpan(
        text: renderText.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: baseStyle, children: spans),
    );
  }
}

class UnifiedCardListTile extends StatelessWidget {
  final CardData card;
  final bool isUp;
  final CardColor effectiveColor;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  const UnifiedCardListTile({
    super.key,
    required this.card,
    required this.isUp,
    required this.effectiveColor,
    required this.onFavoriteToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayImg = card.getImagePathForColor(effectiveColor, isUp);
    final displayCostLabel = card.getCostDisplayText(isUp);
    final displayStar = card.getStarCostLabel(isUp);

    final isSpecialCategory = effectiveColor == CardColor.status ||
      effectiveColor == CardColor.quest ||
      effectiveColor == CardColor.curse;

    String tagLabel = card.rarity.label;
    Color tagBgColor = Color(card.rarity.colorHex);

    if (effectiveColor == CardColor.status) {
      tagLabel = '상태이상';
      tagBgColor = Color(CardColor.status.colorHex);
    } else if (effectiveColor == CardColor.curse) {
      tagLabel = '저주';
      tagBgColor = Color(CardColor.curse.colorHex);
    } else if (effectiveColor == CardColor.quest) {
      tagLabel = '퀘스트';
      tagBgColor = Color(CardColor.quest.colorHex);
    }

    // 일반(#B0BEC5) 및 밝은 배경은 명확하게 검은색 폰트 적용
    final double lum = tagBgColor.computeLuminance();
    final Color tagTextColor = (card.rarity == CardRarity.common || lum > 0.45)
        ? Colors.black
        : Colors.white;

    final isUnplayable = ((isUp && card.upgradedCost != null)
            ? card.upgradedCost!
            : card.cost) ==
        CardCost.none;

    final displayEffect =
        (isUp && card.upgradedEffect != null && card.upgradedEffect!.isNotEmpty)
            ? card.upgradedEffect!
            : card.effect;

    return Builder(
      builder: (itemContext) => GestureDetector(
        onLongPressStart: (details) {
          final renderBox = itemContext.findRenderObject() as RenderBox?;
          if (renderBox == null) return;
          final offset = renderBox.localToGlobal(Offset.zero);
          final rect = offset & renderBox.size;

          CardPreviewHelper.show(
            context: context,
            card: card,
            isUpgraded: isUp,
            targetRect: rect,
            variantColor: effectiveColor,
            showThumbnail: true,
          );
        },
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            width: 44,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isUp
                    ? const Color(0xFFAAFB50)
                    : Color(effectiveColor.colorHex),
                width: 1.2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 44,
                height: 44,
                child: AppCardImage(
                  imagePath: displayImg,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              // 변경 태그: 아이콘 + 외곽선 뱃지 스타일
              if (card.isRecentlyChanged) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D9CEC).withValues(alpha: 0.2),
                    border:
                        Border.all(color: const Color(0xFF5D9CEC), width: 1.0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(Icons.update,
                      size: 12, color: Color(0xFF5D9CEC)),
                ),
                const SizedBox(width: 4),
              ],
              // 멀티 태그: 아이콘 + 외곽선 뱃지 스타일
              if (card.isMultiplayer) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.orangeAccent, width: 1.0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(Icons.people,
                      size: 12, color: Colors.orangeAccent),
                ),
                const SizedBox(width: 4),
              ],
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: tagBgColor,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  tagLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: tagTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  card.name + (isUp ? '+' : ''),
                  style: TextStyle(
                    color: isUp ? const Color(0xFFAAFB50) : null,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3.0),
            child: SearchEffectText(
              text: displayEffect,
              cardColor: effectiveColor,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isSpecialCategory)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isUnplayable) ...[
                      Text(
                        '$tagLabel | ',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB0BEC5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      CardPreviewHelper.buildCostDisplay(
                        card: card,
                        isUpgraded: isUp,
                        displayColor: effectiveColor,
                        iconSize: 14,
                        textStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ] else ...[
                      Text(
                        tagLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB0BEC5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${card.type.label} | ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB0BEC5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isUnplayable) ...[
                      CardPreviewHelper.buildCostDisplay(
                        card: card,
                        isUpgraded: isUp,
                        displayColor: effectiveColor,
                        iconSize: 14,
                        textStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

// ==========================================
// 5. 테마/쓰기 모드 제어 및 앱 엔트리포인트 (main)
// ==========================================

