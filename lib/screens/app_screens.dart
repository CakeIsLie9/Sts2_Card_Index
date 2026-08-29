part of '../main.dart';

class ThemeModeManager {
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  static Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString('app_theme_mode') ?? 'dark';
    switch (modeStr) {
      case 'light':
        themeModeNotifier.value = ThemeMode.light;
        break;
      case 'system':
        themeModeNotifier.value = ThemeMode.system;
        break;
      case 'dark':
      default:
        themeModeNotifier.value = ThemeMode.dark;
        break;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    String modeStr = 'dark';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.system) modeStr = 'system';
    await prefs.setString('app_theme_mode', modeStr);
  }
}

class AppFontManager {
  static const builtInFont = 'GyeonggiBatang';
  static const fontFamily = builtInFont;
}

class WriteModeManager {
  static final ValueNotifier<bool> isWriteModeNotifier =
      ValueNotifier<bool>(false); // 기본값 OFF

  static Future<void> loadWriteMode() async {
    final prefs = await SharedPreferences.getInstance();
    // 저장된 설정이 없으면 기본값 false (OFF)
    isWriteModeNotifier.value = prefs.getBool('app_write_mode') ?? false;
  }

  static Future<void> setWriteMode(bool value) async {
    isWriteModeNotifier.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_write_mode', value);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CardStorage.loadCards();
  await ThemeModeManager.loadThemeMode();
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('app_font_family');
  await WriteModeManager.loadWriteMode();
  runApp(const CardDatabaseApp());
}

class CardDatabaseApp extends StatelessWidget {
  const CardDatabaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeModeManager.themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: '카드 데이터베이스',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ko', 'KR'),
            Locale('en', 'US'),
          ],
          locale: const Locale('ko', 'KR'),
          // 고대비 라이트 모드 (흰 글씨 찐빠 완전 수정)
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            fontFamily: AppFontManager.fontFamily,
            scaffoldBackgroundColor: const Color(0xFFF3F6F8),
            cardColor: Colors.white,
            dividerTheme: const DividerThemeData(
              color: Color(0xFFD5DDE3),
              thickness: 1,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF1E293B),
              elevation: 0.5,
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFF1E293B)),
              bodyMedium: TextStyle(color: Color(0xFF1E293B)),
              titleMedium: TextStyle(color: Color(0xFF1E293B)),
            ),
            listTileTheme: const ListTileThemeData(
              textColor: Color(0xFF1E293B),
              iconColor: Color(0xFF475569),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Color(0xFFD97706),
              unselectedItemColor: Color(0xFF64748B),
            ),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD97706),
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
              onPrimary: Colors.white,
            ),
          ),
          // 다크 모드 (#283B46 딥 슬레이트 블루)
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            fontFamily: AppFontManager.fontFamily,
            scaffoldBackgroundColor: const Color(0xFF283B46),
            cardColor: const Color(0xFF1D2C35),
            dividerTheme: const DividerThemeData(
              color: Colors.white12,
              thickness: 1,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E2D36),
              foregroundColor: Colors.white,
              elevation: 0.5,
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white),
              titleMedium: TextStyle(color: Colors.white),
            ),
            listTileTheme: const ListTileThemeData(
              textColor: Colors.white,
              iconColor: Colors.white70,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF1E2D36),
              selectedItemColor: Colors.amberAccent,
              unselectedItemColor: Color(0xFF8FA7B5),
            ),
            colorScheme: const ColorScheme.dark(
              primary: Colors.amberAccent,
              surface: Color(0xFF1D2C35),
              onSurface: Colors.white,
              onPrimary: Colors.black,
            ),
          ),
          home: const MainNavigationScreen(),
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  DateTime? _lastPressedAt;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        CardPreviewHelper.hide();
        if (didPop) return;

        final now = DateTime.now();
        if (_lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          AppToast.show(context, "'뒤로' 버튼을 한 번 더 누르면 종료됩니다.");
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            CardCompendiumScreen(onDataChanged: () => setState(() {})),
            CardSearchScreen(onDataChanged: () => setState(() {})),
            ExtraFeaturesScreen(onDataChanged: () => setState(() {})),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.amberAccent,
          onTap: (index) {
            FocusScope.of(context).unfocus(); // 탭 이동 시 키보드 닫기
            CardPreviewHelper.hide(); // 탭 이동 시 떠있는 팝업 닫기
            setState(() => _currentIndex = index);
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.menu_book), label: '카드 도감'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: '카드 검색'),
            BottomNavigationBarItem(icon: Icon(Icons.widgets), label: '추가 기능'),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 6. 추가 기능 화면 (기타 유틸리티 제공)
// ==========================================

class ExtraFeaturesScreen extends StatelessWidget {
  final VoidCallback onDataChanged;
  const ExtraFeaturesScreen({super.key, required this.onDataChanged});

  void _showComingSoon(BuildContext context) {
    AppToast.show(context, '준비중입니다.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('추가 기능')),
      body: ValueListenableBuilder<bool>(
        valueListenable: WriteModeManager.isWriteModeNotifier,
        builder: (context, isWriteMode, _) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    if (isWriteMode) ...[
                      ListTile(
                        leading: const Icon(Icons.add_circle,
                            color: Colors.amberAccent),
                        title: const Text('새 카드 등록',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('새로운 카드를 데이터베이스에 추가합니다.',
                            style: TextStyle(fontSize: 13)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) =>
                                  CardRegisterScreen(onSaved: onDataChanged),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                    ],
                    ListTile(
                      leading: const Icon(Icons.menu_book_outlined,
                          color: Colors.amberAccent),
                      title: const Text('키워드 도감',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('게임의 키워드 목록을 확인할 수 있습니다.',
                          style: TextStyle(fontSize: 13)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => KeywordCompendiumScreen(
                                onDataChanged: onDataChanged),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading:
                          const Icon(Icons.casino, color: Colors.purpleAccent),
                      title: const Text('카드 보상 시뮬레이터',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('게임 내 카드 보상을 시뮬레이션할 수 있습니다.',
                          style: TextStyle(fontSize: 13)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            const Text('준비 중', style: TextStyle(fontSize: 11)),
                      ),
                      onTap: () => _showComingSoon(context),
                    ),
                    const Divider(),
                    ListTile(
                      leading:
                          const Icon(Icons.style, color: Colors.greenAccent),
                      title: const Text('덱 빌더',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('덱을 직접 만들고 드로우 시뮬레이션을 할 수 있습니다.',
                          style: TextStyle(fontSize: 13)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            const Text('준비 중', style: TextStyle(fontSize: 11)),
                      ),
                      onTap: () => _showComingSoon(context),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.settings, color: Colors.grey),
                      title: const Text('환경설정',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('앱 테마 및 데이터베이스 관리',
                          style: TextStyle(fontSize: 13)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) =>
                                SettingsScreen(onDataChanged: onDataChanged),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      Text(
                        'StS2 Card Index',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.grey.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'v0.4.1 | Game v0.107.1',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ==========================================
// 7. 키워드 도감 화면 (도감 조회 및 수정)
// ==========================================

class KeywordCompendiumScreen extends StatefulWidget {
  final VoidCallback onDataChanged;
  const KeywordCompendiumScreen({super.key, required this.onDataChanged});

  @override
  State<KeywordCompendiumScreen> createState() =>
      _KeywordCompendiumScreenState();
}

class _KeywordCompendiumScreenState extends State<KeywordCompendiumScreen> {
  bool _showHiddenKeywords = false;
  String _searchQuery = '';
  final FocusNode _kwSearchFocusNode = FocusNode();

  @override
  void dispose() {
    CardPreviewHelper.hide();
    _kwSearchFocusNode.dispose();
    super.dispose();
  }

  void _openAddEditKeywordModal({KeywordData? editKeyword}) {
    _kwSearchFocusNode.unfocus();
    CardPreviewHelper.hide();

    final nameController = TextEditingController(text: editKeyword?.name ?? '');
    final descController =
        TextEditingController(text: editKeyword?.description ?? '');
    bool applyBatch = false;
    bool isHidden = editKeyword?.isHidden ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(editKeyword != null ? '키워드 수정' : '새 키워드 추가'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '키워드 이름 *',
                    hintText: '예: 소멸, 방어도',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: '키워드 설명 *',
                    hintText: '키워드에 대한 설명 문구 입력',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('기존 카드에 [키워드] 문법 일괄 적용',
                      style: TextStyle(fontSize: 13)),
                  subtitle: const Text(
                    '카드 효과 문구 중 일치하는 단어를 자동으로 [키워드]로 감쌉니다.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  value: applyBatch,
                  activeColor: Colors.amberAccent,
                  checkColor: Colors.black,
                  onChanged: (val) =>
                      setDialogState(() => applyBatch = val ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title:
                      const Text('키워드 도감에서 숨김', style: TextStyle(fontSize: 13)),
                  subtitle: const Text(
                    '체크 시 도감 목록에서 기본적으로 숨겨집니다.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  value: isHidden,
                  activeColor: Colors.amberAccent,
                  checkColor: Colors.black,
                  onChanged: (val) =>
                      setDialogState(() => isHidden = val ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
              onPressed: () async {
                final kwName = nameController.text.trim();
                final kwDesc = descController.text.trim();
                if (kwName.isEmpty || kwDesc.isEmpty) {
                  AppToast.show(context, '이름과 설명을 모두 입력하세요.');
                  return;
                }

                if (editKeyword != null) {
                  editKeyword.name = kwName;
                  editKeyword.description = kwDesc;
                  editKeyword.isHidden = isHidden;
                } else {
                  CardStorage.keywords.add(KeywordData(
                    id: const Uuid().v4(),
                    name: kwName,
                    description: kwDesc,
                    isHidden: isHidden,
                  ));
                }

                int batchCount = 0;
                if (applyBatch) {
                  batchCount = CardStorage.applyKeywordBatch(kwName);
                  if (batchCount > 0) {
                    await CardStorage.saveCards();
                    widget.onDataChanged();
                  }
                }

                await CardStorage.saveKeywords();
                setState(() {});
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  if (applyBatch && batchCount > 0) {
                    AppToast.show(
                        context, '키워드가 저장되었으며, $batchCount개 카드에 일괄 적용되었습니다.');
                  } else {
                    AppToast.show(
                        context,
                        editKeyword != null
                            ? '키워드가 수정되었습니다.'
                            : '키워드가 추가되었습니다.');
                  }
                }
              },
              child: Text(
                editKeyword != null ? '수정' : '추가',
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApplyAllKeywordsDialog() {
    _kwSearchFocusNode.unfocus();
    CardPreviewHelper.hide();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('모든 키워드 일괄 적용'),
        content: const Text(
          '현재 등록된 모든 키워드를 데이터베이스 전체 카드의 효과 및 강화 효과에 [키워드] 문법으로 일괄 적용하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
            onPressed: () async {
              final count = CardStorage.applyAllKeywordsBatch();
              if (count > 0) {
                await CardStorage.saveCards();
                widget.onDataChanged();
              }
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                AppToast.show(context, '총 $count개의 카드에 모든 키워드 문법이 일괄 적용되었습니다.');
              }
            },
            child: const Text('일괄 적용 실행',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showKeywordActionSheet(KeywordData kw) {
    _kwSearchFocusNode.unfocus();
    CardPreviewHelper.hide();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.amberAccent),
              title: const Text('수정'),
              onTap: () {
                Navigator.pop(ctx);
                _openAddEditKeywordModal(editKeyword: kw);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text('삭제'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteKeyword(kw);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteKeyword(KeywordData kw) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('키워드 삭제'),
        content: Text("'${kw.name}' 키워드를 도감에서 삭제하겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              CardStorage.keywords.removeWhere((k) => k.id == kw.id);
              await CardStorage.saveKeywords();
              setState(() {});
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) AppToast.show(context, '키워드가 삭제되었습니다.');
            },
            child: const Text('삭제',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayedKeywords = CardStorage.keywords.where((k) {
      if (!_showHiddenKeywords && k.isHidden) return false;
      if (_searchQuery.isNotEmpty) {
        return KoreanSearchHelper.matches(k.name, _searchQuery);
      }
      return true;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return ValueListenableBuilder<bool>(
      valueListenable: WriteModeManager.isWriteModeNotifier,
      builder: (context, isWriteMode, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('키워드 도감'),
            actions: [
              if (isWriteMode) ...[
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: '새 키워드 추가',
                  onPressed: () => _openAddEditKeywordModal(),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) {
                    _kwSearchFocusNode.unfocus();
                    CardPreviewHelper.hide();
                    if (val == 'toggle_hidden') {
                      setState(
                          () => _showHiddenKeywords = !_showHiddenKeywords);
                    } else if (val == 'apply_all') {
                      _showApplyAllKeywordsDialog();
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'toggle_hidden',
                      child: Row(
                        children: [
                          Icon(
                            _showHiddenKeywords
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: _showHiddenKeywords
                                ? Colors.amberAccent
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _showHiddenKeywords
                                ? '숨김 키워드 감추기'
                                : '숨김 키워드 포함하여 보기',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'apply_all',
                      child: Row(
                        children: [
                          Icon(Icons.auto_fix_high,
                              color: Colors.cyanAccent, size: 20),
                          SizedBox(width: 8),
                          Text('모든 키워드 일괄 적용', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  focusNode: _kwSearchFocusNode,
                  decoration: const InputDecoration(
                    hintText: '키워드 이름 검색... (초성 검색 가능)',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) {
                    CardPreviewHelper.hide();
                    setState(() => _searchQuery = val.trim());
                  },
                ),
              ),
              Expanded(
                child: displayedKeywords.isEmpty
                    ? const Center(
                        child: Text(
                          '표시할 키워드가 없습니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFB0BEC5)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: displayedKeywords.length,
                        separatorBuilder: (ctx, i) =>
                            const Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                          final kw = displayedKeywords[idx];
                          return InkWell(
                            onLongPress: isWriteMode
                                ? () => _showKeywordActionSheet(kw)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 90,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            kw.name,
                                            style: TextStyle(
                                              fontFamily: AppFontManager.fontFamily,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? const Color(0xFFFFD54F)
                                                  : const Color(0xFFB45309),
                                            ),
                                          ),
                                        ),
                                        if (kw.isHidden)
                                          const Padding(
                                            padding:
                                                EdgeInsets.only(right: 4.0),
                                            child: Icon(Icons.visibility_off,
                                                size: 14, color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      kw.description,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontFamily: AppFontManager.fontFamily,
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// 8. 환경설정 화면 (테마 제어 및 DB 관리)
// ==========================================

class SettingsScreen extends StatelessWidget {
  final VoidCallback onDataChanged;
  const SettingsScreen({super.key, required this.onDataChanged});

  Future<void> _showWriteModeNotice(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('쓰기 모드가 켜졌습니다!'),
        content: const Text(
          '카드, 키워드 데이터를 작성/편집/삭제하거나 직접 만든 카드 데이터베이스를 내보내거나 복원할 수 있는 여러 가지 메뉴가 추가되었습니다.\n"기본 데이터로 초기화" 시 초기 상태로 돌아갑니다.\n\n추가된 메뉴:\n추가 기능 - 새 카드 등록\n키워드 도감 (추가 기능) - 키워드 추가, 숨김 키워드 포함하여 보기, 모든 키워드 일괄 적용. 키워드를 길게 클릭하면 수정 및 삭제가 가능합니다.\n카드 상세 페이지 - 카드 편집, 카드 삭제\n환경설정 - 데이터베이스 관리의 모든 설정\n\n이 메시지는 쓰기 모드를 켤 때마다 표시됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await WriteModeManager.setWriteMode(true);
      if (context.mounted) {
        AppToast.show(context, '쓰기 모드가 켜졌습니다.');
      }
    }
  }

  void _showResetToDefaultDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기본 데이터로 초기화'),
        content: const Text(
          '앱에 기본 내장된 순정 데이터베이스로 되돌립니다.\n\n사용자가 직접 추가/수정한 카드는 사라지지만, 즐겨찾기(별표)는 그대로 유지됩니다.\n\n계속하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await CardStorage.resetToDefaultDatabase();
              onDataChanged();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                AppToast.show(context, '기본 데이터베이스로 초기화되었습니다.');
              }
            },
            child: const Text('초기화 실행',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showResetChangedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('변경 태그 모두 없애기'),
        content: const Text(
          '모든 카드에 붙어있는 "최근 변경됨" 태그를 전부 제거하겠습니까?\n\n이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              for (var c in CardStorage.cards) {
                c.isRecentlyChanged = false;
              }
              await CardStorage.saveCards();
              onDataChanged();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                AppToast.show(context, '모든 "최근 변경됨" 태그가 회수되었습니다.');
              }
            },
            child: const Text('회수 실행',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showProgressDialog({
    required BuildContext context,
    required String title,
    required Future<void> Function(void Function(double, String) updateProgress)
        task,
  }) {
    double currentProgress = 0.0;
    String currentStatus = '준비 중...';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: currentProgress > 0.0 ? currentProgress : null,
                    backgroundColor: Colors.white12,
                    color: Colors.amberAccent,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          currentStatus,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${(currentProgress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.amberAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    task((progress, status) {
      currentProgress = progress;
      currentStatus = status;
      (context as Element).markNeedsBuild();
    });
  }

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('백업 및 복원'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '카드 데이터와 이미지를 .json 파일로 저장하거나, 저장해 둔 백업 파일을 선택하여 복원합니다.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.upload_file, color: Colors.black),
              label: const Text(
                'DB 파일로 내보내기 (저장/공유)',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                Navigator.pop(ctx);

                _showProgressDialog(
                  context: context,
                  title: '데이터베이스 내보내기',
                  task: (updateProgress) async {
                    try {
                      final jsonStr = await CardStorage.exportDatabaseJsonAsync(
                        onProgress: (prog, status) =>
                            updateProgress(prog, status),
                      );

                      final appDir = await getTemporaryDirectory();
                      final backupFile =
                          File('${appDir.path}/card_database_backup.json');
                      await backupFile.writeAsString(jsonStr);

                      if (context.mounted) Navigator.pop(context);

                      await Share.shareXFiles(
                        [XFile(backupFile.path)],
                        text: '카드 데이터베이스 백업 파일',
                      );
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        AppToast.show(context, '파일 내보내기 실패: $e');
                      }
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[800],
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.file_open, color: Colors.white),
              label: const Text(
                '백업 파일(.json) 선택하여 복원',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                try {
                  final result =
                      await FilePicker.platform.pickFiles(type: FileType.any);
                  if (result != null && result.files.single.path != null) {
                    final selectedFile = File(result.files.single.path!);
                    final content = await selectedFile.readAsString();

                    if (ctx.mounted) Navigator.pop(ctx);

                    if (context.mounted) {
                      _showProgressDialog(
                        context: context,
                        title: '데이터베이스 복원 중',
                        task: (updateProgress) async {
                          final ok = await CardStorage.importDatabaseJsonAsync(
                            content,
                            onProgress: (prog, status) =>
                                updateProgress(prog, status),
                          );

                          if (context.mounted) Navigator.pop(context);

                          if (ok) {
                            onDataChanged();
                            if (context.mounted) {
                              AppToast.show(context, 'DB 파일 복구 완료!');
                            }
                          } else {
                            if (context.mounted) {
                              AppToast.show(context, '올바른 파일 형식이 아닙니다.');
                            }
                          }
                        },
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppToast.show(context, '파일 불러오기 실패: $e');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('환경설정')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '화면 테마 설정',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB0BEC5),
              ),
            ),
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeModeManager.themeModeNotifier,
            builder: (context, currentMode, _) {
              return Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('다크 모드',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    value: ThemeMode.dark,
                    groupValue: currentMode,
                    onChanged: (mode) {
                      if (mode != null) ThemeModeManager.setThemeMode(mode);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('라이트 모드',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    value: ThemeMode.light,
                    groupValue: currentMode,
                    onChanged: (mode) {
                      if (mode != null) ThemeModeManager.setThemeMode(mode);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('기기 설정을 따름',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('시스템 설정에 따라 테마를 자동으로 변경합니다.',
                        style: TextStyle(fontSize: 13)),
                    value: ThemeMode.system,
                    groupValue: currentMode,
                    onChanged: (mode) {
                      if (mode != null) ThemeModeManager.setThemeMode(mode);
                    },
                  ),
                ],
              );
            },
          ),
          const Divider(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '데이터베이스 관리',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB0BEC5),
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: WriteModeManager.isWriteModeNotifier,
            builder: (context, isWriteMode, _) {
              return Column(
                children: [
                  SwitchListTile(
                    title: const Text('쓰기 모드',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text(
                      'ON하면 카드 정보나 키워드를 추가/수정하는 등 데이터베이스를 직접 수정할 수 있는 기능이 활성화됩니다.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: isWriteMode,
                    activeThumbColor: Colors.amberAccent,
                    onChanged: (val) {
                      if (val && !isWriteMode) {
                        _showWriteModeNotice(context);
                        return;
                      }
                      WriteModeManager.setWriteMode(false);
                      AppToast.show(context, '쓰기 모드가 꺼졌습니다.');
                    },
                  ),
                  ListTile(
                    enabled: isWriteMode,
                    leading: Icon(Icons.label_off,
                        color: isWriteMode ? Colors.tealAccent : Colors.grey),
                    title: Text(
                      '변경 태그 모두 없애기',
                      style: TextStyle(
                          color: isWriteMode ? null : Colors.grey,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '모든 카드의 "최근 변경됨" 태그를 모두 제거합니다.',
                      style: TextStyle(
                          fontSize: 12,
                          color: isWriteMode ? null : Colors.grey[700]),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: isWriteMode
                        ? () => _showResetChangedDialog(context)
                        : null,
                  ),
                  ListTile(
                    enabled: isWriteMode,
                    leading: Icon(Icons.backup,
                        color: isWriteMode ? Colors.cyanAccent : Colors.grey),
                    title: Text(
                      '백업 및 복원',
                      style: TextStyle(
                          color: isWriteMode ? null : Colors.grey,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '카드 데이터베이스를 json 파일로 내보내거나 복원합니다.',
                      style: TextStyle(
                          fontSize: 12,
                          color: isWriteMode ? null : Colors.grey[700]),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap:
                        isWriteMode ? () => _showBackupDialog(context) : null,
                  ),
                  ListTile(
                    enabled: isWriteMode,
                    leading: Icon(Icons.restore,
                        color: isWriteMode ? Colors.redAccent : Colors.grey),
                    title: Text(
                      '기본 데이터로 초기화',
                      style: TextStyle(
                          color: isWriteMode ? Colors.redAccent : Colors.grey,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '앱에 내장된 초기 기본 데이터베이스 상태로 되돌립니다.',
                      style: TextStyle(
                          fontSize: 12,
                          color: isWriteMode ? null : Colors.grey[700]),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: isWriteMode
                        ? () => _showResetToDefaultDialog(context)
                        : null,
                  ),
                ],
              );
            },
          ),
          const Divider(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '앱 정보',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB0BEC5),
              ),
            ),
          ),
          ListTile(
            title: const Text('버전 정보',
                style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Text('v0.4.1', style: TextStyle(fontSize: 13)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 6. 카드 도감 화면
// ==========================================

enum SortOption { defaultSort, name, cost, type, rarity }

class CardCompendiumScreen extends StatefulWidget {
  final VoidCallback onDataChanged;
  const CardCompendiumScreen({super.key, required this.onDataChanged});

  @override
  State<CardCompendiumScreen> createState() => _CardCompendiumScreenState();
}

class _CardCompendiumScreenState extends State<CardCompendiumScreen> {
  bool isGrid = true;
  int gridColumns = 3;
  bool isAscending = true;
  bool showUpgrades = false;
  bool showFavoritesOnly = false;
  bool showRecentlyChangedOnly = false;
  SortOption currentSort = SortOption.defaultSort;

  final Set<CardColor> selectedColors = {};
  final Set<CardRarity> selectedRarities = {};
  final Set<CardCost> selectedCosts = {};
  final Set<CardType> selectedTypes = {};

  CardColor get representativePlayableColor {
    List<CardColor> activePlayable = selectedColors
        .where((c) => CardColor.playableColors.contains(c))
        .toList();

    if (activePlayable.isEmpty) {
      activePlayable = List.from(CardColor.playableColors);
    }

    activePlayable.sort((a, b) => a.order.compareTo(b.order));
    return isAscending ? activePlayable.first : activePlayable.last;
  }

  List<CardData> get sortedCards {
    List<CardData> list = CardStorage.cards.where((c) {
      if (!CardStorage.includeMultiplayer && c.isMultiplayer) return false;
      if (showFavoritesOnly && !c.isFavorite) return false;
      if (showRecentlyChangedOnly && !c.isRecentlyChanged) return false;

      if (selectedColors.isNotEmpty) {
        if (c.isSharedStarter) {
          final hasMatchingPlayable = selectedColors
              .any((col) => CardColor.playableColors.contains(col));
          if (!hasMatchingPlayable) return false;
        } else {
          if (!selectedColors.contains(c.logicalColor)) return false;
        }
      }

      if (selectedRarities.isNotEmpty) {
        final selectedBucket = selectedRarities
            .map(CardData.rarityBucket)
            .toSet();
        if (!selectedBucket.contains(CardData.rarityBucket(c.rarity))) {
          return false;
        }
      }
      if (selectedCosts.isNotEmpty && !selectedCosts.contains(c.cost)) {
        return false;
      }
      if (selectedTypes.isNotEmpty && !selectedTypes.contains(c.type)) {
        return false;
      }

      return true;
    }).toList();

    list.sort((a, b) {
      int result = 0;
      switch (currentSort) {
        case SortOption.defaultSort:
          final CardColor aEffectiveColor =
              a.isSharedStarter ? representativePlayableColor : a.logicalColor;
          final CardColor bEffectiveColor =
              b.isSharedStarter ? representativePlayableColor : b.logicalColor;

          int c = aEffectiveColor.order.compareTo(bEffectiveColor.order);
          if (c != 0) {
            result = c;
            break;
          }

          int r = a.rarity.order.compareTo(b.rarity.order);
          if (r != 0) {
            result = r;
            break;
          }

          int t = a.type.order.compareTo(b.type.order);
          if (t != 0) {
            result = t;
            break;
          }

          int cost = a.getCostValue(false).compareTo(b.getCostValue(false));
          if (cost != 0) {
            result = cost;
            break;
          }

          result = a.name.compareTo(b.name);
          break;

        case SortOption.name:
          result = a.name.compareTo(b.name);
          break;

        case SortOption.cost:
          result = a.getCostValue(false).compareTo(b.getCostValue(false));
          break;

        case SortOption.type:
          result = a.type.order.compareTo(b.type.order);
          break;

        case SortOption.rarity:
          result = a.rarity.order.compareTo(b.rarity.order);
          break;
      }
      return isAscending ? result : -result;
    });
    return list;
  }

  void _toggleFavorite(CardData card) async {
    setState(() {
      card.isFavorite = !card.isFavorite;
    });
    await CardStorage.saveCards();
    widget.onDataChanged();
  }

  // 필터 칩 스타일 생성 헬퍼
  Widget _buildFilterChipItem({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
    Color? activeColor,
    Color? defaultTextColor,
  }) {
    final effectiveActiveBg = activeColor ?? Colors.amber[700]!;
    final double lum = effectiveActiveBg.computeLuminance();
    final Color selectedTextColor = lum > 0.55 ? Colors.black : Colors.white;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: isSelected
              ? selectedTextColor
              : (defaultTextColor ?? activeColor),
        ),
      ),
      selected: isSelected,
      selectedColor: effectiveActiveBg,
      backgroundColor: Colors.white.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: isSelected
              ? effectiveActiveBg
              : (activeColor != null
                  ? activeColor.withValues(alpha: 0.5)
                  : Colors.white24),
          width: isSelected ? 1.4 : 0.8,
        ),
      ),
      showCheckmark: false,
      onSelected: onSelected,
    );
  }

  void _showSortAndLayoutModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('보기, 정렬 및 필터 설정',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          showFavoritesOnly = false;
                          showRecentlyChangedOnly = false;
                          selectedColors.clear();
                          selectedRarities.clear();
                          selectedCosts.clear();
                          selectedTypes.clear();
                        });
                        setModalState(() {});
                      },
                      child: const Text('필터 초기화',
                          style: TextStyle(
                              color: Colors.amberAccent, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amberAccent, size: 20),
                      SizedBox(width: 8),
                      Text('즐겨찾기 카드만 보기',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  value: showFavoritesOnly,
                  activeThumbColor: Colors.amberAccent,
                  onChanged: (val) {
                    setState(() => showFavoritesOnly = val);
                    setModalState(() {});
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Row(
                    children: [
                      Icon(Icons.update, color: Color(0xFF5D9CEC), size: 20),
                      SizedBox(width: 8),
                      Text('최근 변경된 카드만 보기',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  value: showRecentlyChangedOnly,
                  activeThumbColor: const Color(0xFF5D9CEC),
                  onChanged: (val) {
                    setState(() => showRecentlyChangedOnly = val);
                    setModalState(() {});
                  },
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Text('레이아웃 형태',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    SegmentedButton<bool>(
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.resolveWith<Color?>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.amber[700];
                          }
                          return null;
                        }),
                        foregroundColor:
                            WidgetStateProperty.resolveWith<Color?>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.black;
                          }
                          return null;
                        }),
                      ),
                      segments: const [
                        ButtonSegment(
                            value: true,
                            label: Text('바둑판'),
                            icon: Icon(Icons.grid_view)),
                        ButtonSegment(
                            value: false,
                            label: Text('리스트'),
                            icon: Icon(Icons.view_list)),
                      ],
                      selected: {isGrid},
                      onSelectionChanged: (val) {
                        setState(() => isGrid = val.first);
                        setModalState(() {});
                      },
                    ),
                  ],
                ),
                if (isGrid) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('한 줄 카드 개수',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Wrap(
                        spacing: 6,
                        children: [2, 3, 4, 5].map((cols) {
                          final selected = gridColumns == cols;
                          return _buildFilterChipItem(
                            label: '$cols열',
                            isSelected: selected,
                            onSelected: (_) {
                              setState(() => gridColumns = cols);
                              setModalState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 24),
                Row(
                  children: [
                    const Text('정렬 순서',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    _buildFilterChipItem(
                      label: isAscending ? '오름차순 (▲)' : '내림차순 (▼)',
                      isSelected: true,
                      onSelected: (_) {
                        setState(() => isAscending = !isAscending);
                        setModalState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('정렬 기준',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    SortOption.defaultSort,
                    SortOption.name,
                    SortOption.cost,
                    SortOption.type,
                    SortOption.rarity,
                  ].map((opt) {
                    final names = {
                      SortOption.defaultSort: '기본',
                      SortOption.name: '가나다순',
                      SortOption.cost: '비용순',
                      SortOption.type: '종류순',
                      SortOption.rarity: '희귀도순',
                    };
                    return _buildFilterChipItem(
                      label: names[opt]!,
                      isSelected: currentSort == opt,
                      onSelected: (_) {
                        setState(() => currentSort = opt);
                        setModalState(() {});
                      },
                    );
                  }).toList(),
                ),
                const Divider(height: 24),
                const Text('색상 필터',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: CardColor.values.map((c) {
                    final selected = selectedColors.contains(c);
                    return _buildFilterChipItem(
                      label: c.label,
                      isSelected: selected,
                      activeColor: Color(c.colorHex),
                      onSelected: (val) {
                        setState(() {
                          val
                              ? selectedColors.add(c)
                              : selectedColors.remove(c);
                        });
                        setModalState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('희귀도 필터',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    CardRarity.starter,
                    CardRarity.common,
                    CardRarity.uncommon,
                    CardRarity.rare,
                    CardRarity.event,
                    CardRarity.ancient,
                    CardRarity.special,
                  ].map((r) {
                    final selected = selectedRarities.contains(r) ||
                        (r == CardRarity.special &&
                            selectedRarities.contains(CardRarity.token));
                    final displayLabel = r == CardRarity.special ? '기타' : r.label;
                    return _buildFilterChipItem(
                      label: displayLabel,
                      isSelected: selected,
                      activeColor: Color(r.colorHex),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            if (r == CardRarity.special) {
                              selectedRarities.remove(CardRarity.token);
                              selectedRarities.add(CardRarity.special);
                            } else {
                              selectedRarities.remove(CardRarity.special);
                              selectedRarities.add(r);
                            }
                          } else {
                            selectedRarities.remove(CardRarity.special);
                            selectedRarities.remove(CardRarity.token);
                            selectedRarities.remove(r);
                          }
                        });
                        setModalState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('비용 필터',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    CardCost.cost0,
                    CardCost.cost1,
                    CardCost.cost2,
                    CardCost.cost3,
                    CardCost.costX,
                    CardCost.cost4Plus,
                  ].map((cost) {
                    final selected = selectedCosts.contains(cost);
                    return _buildFilterChipItem(
                      label: cost.label,
                      isSelected: selected,
                      onSelected: (val) {
                        setState(() {
                          val
                              ? selectedCosts.add(cost)
                              : selectedCosts.remove(cost);
                        });
                        setModalState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('카드 종류 필터',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: CardType.values.map((t) {
                    final selected = selectedTypes.contains(t);
                    return _buildFilterChipItem(
                      label: t.label,
                      isSelected: selected,
                      onSelected: (val) {
                        setState(() {
                          val ? selectedTypes.add(t) : selectedTypes.remove(t);
                        });
                        setModalState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilter = selectedColors.isNotEmpty ||
        selectedRarities.isNotEmpty ||
        selectedCosts.isNotEmpty ||
        selectedTypes.isNotEmpty ||
        showFavoritesOnly ||
        showRecentlyChangedOnly;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text('카드 도감'),
            const SizedBox(width: 8),
            Text(
              '(${sortedCards.length}종)',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFB0BEC5),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              showFavoritesOnly ? Icons.star : Icons.star_border,
              color: showFavoritesOnly ? Colors.amberAccent : Colors.grey,
            ),
            tooltip: showFavoritesOnly ? '전체 카드 보기' : '즐겨찾기 카드만 보기',
            onPressed: () =>
                setState(() => showFavoritesOnly = !showFavoritesOnly),
          ),
          IconButton(
            icon: Icon(
              CardStorage.includeMultiplayer
                  ? Icons.people
                  : Icons.people_outline,
              color: CardStorage.includeMultiplayer
                  ? Colors.orangeAccent
                  : Colors.grey,
            ),
            tooltip: CardStorage.includeMultiplayer
                ? '멀티플레이 카드 숨기기'
                : '멀티플레이 카드 포함하여 보기',
            onPressed: () => setState(() => CardStorage.includeMultiplayer =
                !CardStorage.includeMultiplayer),
          ),
          IconButton(
            icon: Icon(
              showUpgrades ? Icons.arrow_upward : Icons.arrow_upward_outlined,
              color: showUpgrades ? const Color(0xFFAAFB50) : Colors.grey,
            ),
            tooltip: showUpgrades ? '강화 해제' : '강화 효과 일괄 보기',
            onPressed: () => setState(() => showUpgrades = !showUpgrades),
          ),
          IconButton(
            icon: Icon(Icons.tune,
                color: hasActiveFilter ? Colors.amberAccent : null),
            tooltip: '정렬 및 보기 설정',
            onPressed: _showSortAndLayoutModal,
          ),
        ],
      ),
      body: sortedCards.isEmpty
          ? Center(
              child: Text(
                CardStorage.cards.isEmpty
                    ? '등록된 카드가 없음.\n(추가 기능 탭에서 카드를 등록할 수 있음)'
                    : '조건에 맞는 카드가 없음.\n(필터를 초기화하거나 즐겨찾기를 등록할 것)',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB0BEC5)),
              ),
            )
          : isGrid
              ? GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridColumns,
                    childAspectRatio: 3 / 4,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: sortedCards.length,
                  itemBuilder: (ctx, idx) => _buildCardTile(sortedCards[idx]),
                )
              : ListView.separated(
                  itemCount: sortedCards.length,
                  separatorBuilder: (ctx, i) =>
                      const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final card = sortedCards[idx];
                    final isUp = showUpgrades && card.hasUpgrade;
                    final effectiveColor = card.isSharedStarter
                        ? representativePlayableColor
                        : card.color;
                    return UnifiedCardListTile(
                      card: card,
                      isUp: isUp,
                      effectiveColor: effectiveColor,
                      onFavoriteToggle: () => _toggleFavorite(card),
                      onTap: () =>
                          _openDetail(card, initialColor: effectiveColor),
                    );
                  },
                ),
    );
  }

  Widget _buildCardTile(CardData card) {
    final isUp = showUpgrades && card.hasUpgrade;
    final effectiveColor =
        card.isSharedStarter ? representativePlayableColor : card.color;
    final displayImg = card.getImagePathForColor(effectiveColor, isUp);

    final fontSize = gridColumns >= 4 ? 10.0 : 12.0;

    double nextTop = 4.0;
    final double? multiTop = card.isMultiplayer ? nextTop : null;
    if (card.isMultiplayer) nextTop += 20.0;

    final double? changedTop = card.isRecentlyChanged ? nextTop : null;
    if (card.isRecentlyChanged) nextTop += 20.0;

    final double starTop = nextTop;

    return Builder(
      builder: (tileContext) => GestureDetector(
        onLongPressStart: (details) {
          final renderBox = tileContext.findRenderObject() as RenderBox?;
          if (renderBox == null) return;
          final offset = renderBox.localToGlobal(Offset.zero);
          final rect = offset & renderBox.size;

          CardPreviewHelper.show(
            context: context,
            card: card,
            isUpgraded: isUp,
            targetRect: rect,
            variantColor: effectiveColor,
            showThumbnail: false,
          );
        },
        onTap: () => _openDetail(card, initialColor: effectiveColor),
        child: Card(
          color: Color(effectiveColor.colorHex).withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: isUp
                  ? const Color(0xFFAAFB50)
                  : Color(effectiveColor.colorHex),
              width: isUp ? 2.0 : 1.5,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    displayImg.isNotEmpty
                        ? AppCardImage(
                            imagePath: displayImg,
                            fit: BoxFit.cover,
                            width: double.infinity)
                        : const Icon(Icons.image, size: 40),
                    if (card.isMultiplayer && multiTop != null)
                      Positioned(
                        top: multiTop,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('멀티',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    if (card.isRecentlyChanged && changedTop != null)
                      Positioned(
                        top: changedTop,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5D9CEC),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('변경',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    Positioned(
                      top: starTop,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _toggleFavorite(card),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            card.isFavorite ? Icons.star : Icons.star_border,
                            size: 18,
                            color: card.isFavorite
                                ? Colors.amberAccent
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                child: Text(
                  card.name + (isUp ? '+' : ''),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: isUp
                      ? const Color(0xFFAAFB50)
                      : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF1E293B)),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(CardData card, {CardColor? initialColor}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (ctx) => CardDetailScreen(
                card: card,
                activeVariantColor: initialColor,
              )),
    );
    widget.onDataChanged();
    setState(() {});
  }
}

// ==========================================
// 7. 카드 상세 화면 (쓰기 모드 연동)
// ==========================================

class CardDetailScreen extends StatefulWidget {
  final CardData card;
  final bool initialUpgraded;
  final CardColor? activeVariantColor;

  const CardDetailScreen({
    super.key,
    required this.card,
    this.initialUpgraded = false,
    this.activeVariantColor,
  });

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late bool isUpgraded;
  late CardColor selectedVariantColor;

  @override
  void initState() {
    super.initState();
    isUpgraded = widget.initialUpgraded;
    selectedVariantColor = widget.activeVariantColor ??
        (widget.card.isSharedStarter ? CardColor.ironclad : widget.card.color);
  }

  @override
  void dispose() {
    CardPreviewHelper.hide();
    super.dispose();
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('카드 삭제'),
        content: Text("'${widget.card.name}' 카드를 정말로 삭제하겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              CardStorage.cards.removeWhere((c) => c.id == widget.card.id);
              await CardStorage.saveCards();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('삭제',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = widget.card;
    final effectiveColor =
        card.isSharedStarter ? selectedVariantColor : card.color;

    final displayCost = (isUpgraded && card.upgradedCost != null)
        ? card.upgradedCost!
        : card.cost;
    final displayCostLabel = card.getCostDisplayText(isUpgraded);
    final displayStarCost = card.getStarCostLabel(isUpgraded);

    final hasCostDecreased = isUpgraded &&
        card.upgradedCost != null &&
        card.upgradedCost!.value < card.cost.value;
    final hasStarDecreased = isUpgraded &&
        card.upgradedStarCost != null &&
        (card.starCost == null || card.upgradedStarCost! < card.starCost!);

    final displayImage = card.getImagePathForColor(effectiveColor, isUpgraded);

    final displayEffect = (isUpgraded &&
            card.upgradedEffect != null &&
            card.upgradedEffect!.isNotEmpty)
        ? card.upgradedEffect!
        : card.effect;

    final bool isEffectTextChanged = isUpgraded &&
        card.upgradedEffect != null &&
        card.upgradedEffect!.trim().isNotEmpty &&
        card.upgradedEffect!.trim() != card.effect.trim();

    final isSpecialCategory = effectiveColor == CardColor.status ||
        effectiveColor == CardColor.quest ||
        effectiveColor == CardColor.curse;

    final hasNoCost = displayCost == CardCost.none;

    final slashColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final typeColor = isDark ? Colors.white : const Color(0xFF1E293B);

    final List<InlineSpan> metaSpans = [];

    metaSpans.add(TextSpan(
      text: card.isSharedStarter ? '공용 시작' : effectiveColor.label,
      style: TextStyle(
        color: Color(effectiveColor.colorHex),
        fontWeight: FontWeight.bold,
        fontSize: 15,
        fontFamily: AppFontManager.fontFamily,
      ),
    ));

    if (!isSpecialCategory) {
      metaSpans.add(TextSpan(
        text: ' / ',
        style: TextStyle(
          color: slashColor,
          fontWeight: FontWeight.bold,
          fontSize: 15,
          fontFamily: AppFontManager.fontFamily,
        ),
      ));
      metaSpans.add(TextSpan(
        text: card.rarity.label,
        style: TextStyle(
          color: Color(card.rarity.colorHex),
          fontWeight: FontWeight.bold,
          fontSize: 15,
          fontFamily: AppFontManager.fontFamily,
        ),
      ));
      metaSpans.add(TextSpan(
        text: ' / ',
        style: TextStyle(
          color: slashColor,
          fontWeight: FontWeight.bold,
          fontSize: 15,
          fontFamily: AppFontManager.fontFamily,
        ),
      ));
      metaSpans.add(TextSpan(
        text: card.type.label,
        style: TextStyle(
          color: typeColor,
          fontWeight: FontWeight.bold,
          fontSize: 15,
          fontFamily: AppFontManager.fontFamily,
        ),
      ));
    }

    return ValueListenableBuilder<bool>(
      valueListenable: WriteModeManager.isWriteModeNotifier,
      builder: (context, isWriteMode, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              card.name + (isUpgraded ? '+' : ''),
              style: TextStyle(
                color: isUpgraded ? const Color(0xFFAAFB50) : null,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  card.isFavorite ? Icons.star : Icons.star_border,
                  color: card.isFavorite ? Colors.amberAccent : null,
                ),
                tooltip: '즐겨찾기 토글',
                onPressed: () async {
                  await CardStorage.toggleFavorite(card);
                  setState(() {});
                },
              ),
              if (isWriteMode) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (ctx) => CardRegisterScreen(
                              editCard: card, onSaved: () {})),
                    );
                    setState(() {});
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: _confirmDelete,
                ),
              ],
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.66, 1.0],
                colors: [
                  Color(effectiveColor.colorHex).withValues(alpha: 0.28),
                  Color(effectiveColor.colorHex).withValues(alpha: 0.0),
                  Colors.transparent,
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenSize = MediaQuery.sizeOf(context);
                    final isCompactLayout =
                      screenSize.width / screenSize.height >= 3 / 4;
                    const layoutGap = 12.0;
                    final availableWidth = constraints.maxWidth - layoutGap;
                    final imageWidth = isCompactLayout
                      ? availableWidth / 3
                        : constraints.maxWidth * 0.75;
                    final infoWidth = isCompactLayout
                      ? availableWidth * 2 / 3
                        : constraints.maxWidth;

                    return Flex(
                      direction:
                          isCompactLayout ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isCompactLayout)
                          SizedBox(
                            width: imageWidth,
                            child: AspectRatio(
                              aspectRatio: 3 / 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AppCardImage(
                                  imagePath: displayImage,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          )
                        else
                          Center(
                            child: SizedBox(
                              width: imageWidth,
                              child: AspectRatio(
                                aspectRatio: 3 / 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AppCardImage(
                                    imagePath: displayImage,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (isCompactLayout)
                          const SizedBox(width: 12)
                        else
                          const SizedBox(height: 10),
                        SizedBox(
                          width: infoWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                if (card.isSharedStarter) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: CardColor.playableColors.map((color) {
                        final isSelected = selectedVariantColor == color;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => selectedVariantColor = color),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(color.colorHex).withValues(alpha: 0.25)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(
                                      color: Color(color.colorHex), width: 1.5)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  color.iconPath,
                                  width: 16,
                                  height: 16,
                                  errorBuilder: (c, o, s) => Icon(Icons.circle,
                                      color: Color(color.colorHex), size: 14),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  color.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (card.hasUpgrade)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => isUpgraded = !isUpgraded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 4.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: isUpgraded,
                              activeColor: const Color(0xFFAAFB50),
                              checkColor: Colors.black,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (val) =>
                                  setState(() => isUpgraded = val ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '강화 효과 보기',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isUpgraded
                                  ? const Color(0xFFAAFB50)
                                  : const Color(0xFFB0BEC5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (card.isRecentlyChanged || card.isMultiplayer) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (card.isRecentlyChanged)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5D9CEC).withValues(alpha: 0.2),
                            border: Border.all(color: const Color(0xFF5D9CEC)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.update,
                                  size: 14, color: Color(0xFF5D9CEC)),
                              SizedBox(width: 4),
                              Text('최근 변경됨',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF5D9CEC),
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      if (card.isMultiplayer)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            border: Border.all(color: Colors.orangeAccent),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people,
                                  size: 14, color: Colors.orangeAccent),
                              SizedBox(width: 4),
                              Text('멀티플레이 전용',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orangeAccent,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(children: metaSpans),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!hasNoCost)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: hasCostDecreased
                                ? BoxDecoration(
                                    color: const Color(0x55AAFB50),
                                    borderRadius: BorderRadius.circular(3),
                                  )
                                : null,
                            padding: hasCostDecreased
                                ? const EdgeInsets.symmetric(horizontal: 3)
                                : EdgeInsets.zero,
                            child: CardPreviewHelper.buildCostDisplay(
                              card: card,
                              isUpgraded: isUpgraded,
                              displayColor: effectiveColor,
                              iconSize: 16,
                              textStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isEffectTextChanged
                        ? Colors.lightGreen.withValues(alpha: 0.12)
                        : Theme.of(context).cardColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isEffectTextChanged
                          ? Colors.lightGreenAccent.withValues(alpha: 0.5)
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: InteractiveCardText(
                    text: displayEffect,
                    cardColor: effectiveColor,
                  ),
                ),
                if (card.description != null &&
                    card.description!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InteractiveCardText(
                      text: card.description!,
                      cardColor: effectiveColor,
                      onlyLinks: true,
                      baseStyle: TextStyle(
                        color: isDark
                            ? const Color(0xFFB0BEC5)
                            : const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}

// ==========================================
// 8. 카드 검색 화면
// ==========================================

class CardSearchScreen extends StatefulWidget {
  final VoidCallback onDataChanged;
  const CardSearchScreen({super.key, required this.onDataChanged});

  @override
  State<CardSearchScreen> createState() => _CardSearchScreenState();
}

class _CardSearchScreenState extends State<CardSearchScreen> {
  String keyword = '';
  bool showUpgrades = false;
  CardColor? filterColor;
  CardType? filterType;
  CardRarity? filterRarity;
  CardCost? filterCost;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    CardPreviewHelper.hide();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = keyword.trim().isEmpty
        ? <CardData>[]
        : CardStorage.cards.where((card) {
            if (!CardStorage.includeMultiplayer && card.isMultiplayer) {
              return false;
            }

            final curEffect = (showUpgrades &&
                    card.upgradedEffect != null &&
                    card.upgradedEffect!.isNotEmpty)
                ? card.upgradedEffect!
                : card.effect;
            final curCost = (showUpgrades && card.upgradedCost != null)
                ? card.upgradedCost!
                : card.cost;

            final matchesQuery =
              KoreanSearchHelper.matches(card.name, keyword) ||
                KoreanSearchHelper.searchableEffect(curEffect)
                  .contains(keyword.trim().toLowerCase());

            bool matchesColor = true;
            if (filterColor != null) {
              if (card.isSharedStarter) {
                matchesColor = CardColor.playableColors.contains(filterColor);
              } else {
                matchesColor = (card.logicalColor == filterColor);
              }
            }

            final matchesType = filterType == null || card.type == filterType;

            bool matchesRarity = true;
            if (filterRarity != null) {
              matchesRarity = CardData.matchesRarityBucket(
                filterRarity!,
                card.rarity,
              );
            }

            bool matchesCost = true;
            if (filterCost != null) {
              if (filterCost == CardCost.cost4Plus) {
                matchesCost = (curCost == CardCost.cost4Plus ||
                    curCost == CardCost.costX);
              } else {
                matchesCost = (curCost == filterCost);
              }
            }

            return matchesQuery &&
                matchesColor &&
                matchesType &&
                matchesRarity &&
                matchesCost;
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('카드 검색'),
        actions: [
          IconButton(
            icon: Icon(
              CardStorage.includeMultiplayer
                  ? Icons.people
                  : Icons.people_outline,
              color: CardStorage.includeMultiplayer
                  ? Colors.orangeAccent
                  : Colors.grey,
            ),
            tooltip: CardStorage.includeMultiplayer
                ? '멀티플레이 카드 숨기기'
                : '멀티플레이 카드 포함하여 검색',
            onPressed: () {
              CardPreviewHelper.hide();
              setState(() => CardStorage.includeMultiplayer =
                  !CardStorage.includeMultiplayer);
            },
          ),
          IconButton(
            icon: Icon(
              showUpgrades ? Icons.arrow_upward : Icons.arrow_upward_outlined,
              color: showUpgrades ? const Color(0xFFAAFB50) : Colors.grey,
            ),
            tooltip: showUpgrades ? '강화 해제' : '강화 효과 일괄 보기',
            onPressed: () {
              CardPreviewHelper.hide();
              setState(() => showUpgrades = !showUpgrades);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              focusNode: _searchFocusNode,
              decoration: const InputDecoration(
                hintText: '카드명 또는 효과 검색...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                CardPreviewHelper.hide();
                setState(() => keyword = val);
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                DropdownButton<CardColor?>(
                  hint: const Text('색상'),
                  value: filterColor,
                  onChanged: (val) {
                    _searchFocusNode.unfocus();
                    CardPreviewHelper.hide();
                    setState(() => filterColor = val);
                  },
                  items: [
                    const DropdownMenuItem(value: null, child: Text('색상 전체')),
                    ...CardColor.values.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.label,
                              style: TextStyle(
                                  color: Color(c.colorHex),
                                  fontWeight: FontWeight.bold)),
                        )),
                  ],
                ),
                const SizedBox(width: 10),
                DropdownButton<CardType?>(
                  hint: const Text('종류'),
                  value: filterType,
                  onChanged: (val) {
                    _searchFocusNode.unfocus();
                    CardPreviewHelper.hide();
                    setState(() => filterType = val);
                  },
                  items: [
                    const DropdownMenuItem(value: null, child: Text('종류 전체')),
                    ...CardType.values.map((t) =>
                        DropdownMenuItem(value: t, child: Text(t.label))),
                  ],
                ),
                const SizedBox(width: 10),
                DropdownButton<CardRarity?>(
                  hint: const Text('희귀도'),
                  value: filterRarity,
                  onChanged: (val) {
                    _searchFocusNode.unfocus();
                    CardPreviewHelper.hide();
                    setState(() => filterRarity = val);
                  },
                  items: [
                    const DropdownMenuItem(value: null, child: Text('희귀도 전체')),
                    ...[
                      CardRarity.starter,
                      CardRarity.common,
                      CardRarity.uncommon,
                      CardRarity.rare,
                      CardRarity.event,
                      CardRarity.ancient,
                      CardRarity.special,
                    ].map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                            r == CardRarity.special ? '기타 (토큰 포함)' : r.label,
                            style: TextStyle(
                                color: Color(r.colorHex),
                                fontWeight: FontWeight.bold),
                          ),
                        )),
                  ],
                ),
                const SizedBox(width: 10),
                DropdownButton<CardCost?>(
                  hint: const Text('비용'),
                  value: filterCost,
                  onChanged: (val) {
                    _searchFocusNode.unfocus();
                    CardPreviewHelper.hide();
                    setState(() => filterCost = val);
                  },
                  items: [
                    const DropdownMenuItem(value: null, child: Text('비용 전체')),
                    ...CardCost.values.where((c) => c != CardCost.costX).map(
                        (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c == CardCost.cost4Plus
                                ? '4+ (X 포함)'
                                : c.label))),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: keyword.trim().isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          '카드명 초성 검색을 지원합니다. "에너지", "별"을 검색해보세요.',
                          style:
                              TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : searchResults.isEmpty
                    ? const Center(
                        child: Text(
                          '검색 결과가 없음',
                          style: TextStyle(color: Color(0xFFB0BEC5)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: searchResults.length,
                        separatorBuilder: (ctx, i) =>
                            const Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                          final card = searchResults[idx];
                          final isUp = showUpgrades && card.hasUpgrade;
                          final effectiveColor = (card.isSharedStarter &&
                                  filterColor != null &&
                                  CardColor.playableColors
                                      .contains(filterColor))
                              ? filterColor!
                              : card.color;
                          return UnifiedCardListTile(
                            card: card,
                            isUp: isUp,
                            effectiveColor: effectiveColor,
                            onFavoriteToggle: () async {
                              await CardStorage.toggleFavorite(card);
                              widget.onDataChanged();
                              setState(() {});
                            },
                            onTap: () async {
                              _searchFocusNode.unfocus();
                              CardPreviewHelper.hide();
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (ctx) => CardDetailScreen(
                                          card: card,
                                          activeVariantColor: effectiveColor,
                                        )),
                              );
                              widget.onDataChanged();
                              setState(() {});
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 9. 카드 등록 / 수정 화면
// ==========================================

class CardRegisterScreen extends StatefulWidget {
  final CardData? editCard;
  final VoidCallback onSaved;
  const CardRegisterScreen({super.key, this.editCard, required this.onSaved});

  @override
  State<CardRegisterScreen> createState() => _CardRegisterScreenState();
}

class _CardRegisterScreenState extends State<CardRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _effectController;
  late TextEditingController _upgradedEffectController;

  late String _name;
  late CardColor _color;
  late CardType _type;
  late CardRarity _rarity;
  late CardCost _cost;
  int? _customCost;
  int? _starCost;
  String? _imagePath;
  late bool _isMultiplayer;
  late bool _isFavorite;
  late bool _isRecentlyChanged;

  late bool _isSharedStarter;
  late Map<CardColor, String> _variantImages;
  late Map<CardColor, String> _upgradedVariantImages;
  CardColor _activeEditingColor = CardColor.ironclad;

  String? _upgradedImagePath;
  CardCost? _upgradedCost;
  int? _upgradedCustomCost;
  int? _upgradedStarCost;
  String? _description;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final c = widget.editCard;
    _name = c?.name ?? '';
    _effectController = TextEditingController(text: c?.effect ?? '');
    _upgradedEffectController =
        TextEditingController(text: c?.upgradedEffect ?? '');

    _effectController.addListener(() {
      setState(() {});
    });

    _isSharedStarter = c?.isSharedStarter ?? false;
    _isRecentlyChanged = c?.isRecentlyChanged ?? false;
    _color = _isSharedStarter
        ? CardColor.ironclad
        : (c?.color ?? CardColor.ironclad);
    _type = c?.type ?? CardType.attack;
    _rarity = _isSharedStarter
        ? CardRarity.starter
        : (c?.rarity ?? CardRarity.common);
    _cost = c?.cost ?? CardCost.cost1;
    _customCost = c?.customCost ?? (c?.cost == CardCost.cost4Plus ? 4 : null);
    _starCost = c?.starCost;
    _imagePath = c?.imagePath;
    _isMultiplayer = c?.isMultiplayer ?? false;
    _isFavorite = c?.isFavorite ?? false;

    _variantImages = Map.from(c?.variantImages ?? {});
    _upgradedVariantImages = Map.from(c?.upgradedVariantImages ?? {});

    _upgradedImagePath = c?.upgradedImagePath;
    _upgradedCost = c?.upgradedCost;
    _upgradedCustomCost = c?.upgradedCustomCost ??
        (c?.upgradedCost == CardCost.cost4Plus ? 4 : null);
    _upgradedStarCost = c?.upgradedStarCost;
    _description = c?.description;
  }

  @override
  void dispose() {
    _effectController.dispose();
    _upgradedEffectController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isUpgrade, {CardColor? variantColor}) async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (_isSharedStarter && variantColor != null) {
          if (isUpgrade) {
            _upgradedVariantImages[variantColor] = picked.path;
          } else {
            _variantImages[variantColor] = picked.path;
            if (variantColor == CardColor.ironclad || _imagePath == null) {
              _imagePath = picked.path;
            }
          }
        } else {
          if (isUpgrade) {
            _upgradedImagePath = picked.path;
          } else {
            _imagePath = picked.path;
          }
        }
      });
    }
  }

  void _copyBaseEffectToUpgrade() {
    if (_effectController.text.trim().isEmpty) {
      AppToast.show(context, '기본 효과 내용이 비어 있습니다.');
      return;
    }
    setState(() {
      _upgradedEffectController.text = _effectController.text;
    });
  }

  Widget _buildCustomContextMenu(
    BuildContext context,
    EditableTextState editableTextState,
    TextEditingController controller,
  ) {
    final List<ContextMenuButtonItem> buttonItems =
        editableTextState.contextMenuButtonItems;

    void wrapSelection(String prefix, String suffix) {
      final value = controller.value;
      final selection = value.selection;
      if (!selection.isValid || selection.isCollapsed) return;

      final selectedText = selection.textInside(value.text);
      final newText = value.text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );

      final newSelection = TextSelection(
        baseOffset: selection.start,
        extentOffset: selection.start +
            prefix.length +
            selectedText.length +
            suffix.length,
      );

      controller.value = TextEditingValue(
        text: newText,
        selection: newSelection,
      );
      ContextMenuController.removeAny();
    }

    buttonItems.insert(
      0,
      ContextMenuButtonItem(
        label: '링크',
        onPressed: () => wrapSelection('[[', ']]'),
      ),
    );
    buttonItems.insert(
      1,
      ContextMenuButtonItem(
        label: '강화 강조',
        onPressed: () => wrapSelection('^', '^'),
      ),
    );
    buttonItems.insert(
      2,
      ContextMenuButtonItem(
        label: '키워드',
        onPressed: () => wrapSelection('[', ']'),
      ),
    );

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }

  void _showSyntaxHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text('텍스트 문법 도움말', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem(
                symbol: '@',
                desc: '에너지 아이콘으로 전환됩니다.',
                exampleInput: '@@을 얻습니다.',
                exampleOutput: const InteractiveCardText(
                  text: '@@을 얻습니다.',
                  cardColor: CardColor.colorless,
                ),
              ),
              const Divider(height: 16),
              _buildHelpItem(
                symbol: '*',
                desc: '리젠트의 별 아이콘으로 전환됩니다.',
                exampleInput: '**을 얻습니다.',
                exampleOutput: const InteractiveCardText(
                  text: '**을 얻습니다.',
                  cardColor: CardColor.regent,
                ),
              ),
              const Divider(height: 16),
              _buildHelpItem(
                symbol: '[[카드명]]',
                desc: '해당 카드로 링크되는 하이퍼링크로 전환됩니다. +를 붙이면 강화된 카드로 링크됩니다.',
                exampleInput: '[[단도+]]를 손으로 가져옵니다.',
                exampleOutput: const InteractiveCardText(
                  text: '[[단도+]]를 손으로 가져옵니다.',
                  cardColor: CardColor.colorless,
                ),
              ),
              const Divider(height: 16),
              _buildHelpItem(
                symbol: '[키워드]',
                desc: '누르면 해당 키워드의 설명을 보여줍니다.',
                exampleInput: '[방어도]를 5 얻습니다.',
                exampleOutput: const InteractiveCardText(
                  text: '[방어도]를 5 얻습니다.',
                  cardColor: CardColor.colorless,
                ),
              ),
              const Divider(height: 16),
              _buildHelpItem(
                symbol: '^텍스트^',
                desc:
                    '강화된 효과를 적용하기 위해 텍스트를 초록색으로 강조합니다. 카드 링크 및 키워드와 함께 적용할 수 있습니다.',
                exampleInput: '피해를 ^9^ 줍니다.',
                exampleOutput: RichText(
                  text: TextSpan(
                    style: TextStyle(
                        fontFamily: AppFontManager.fontFamily,
                        fontSize: 13,
                        color: Colors.white),
                    children: [
                      TextSpan(text: '피해를 '),
                      TextSpan(
                        text: '9',
                        style: TextStyle(
                          color: Color(0xFFAAFB50),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: ' 줍니다.'),
                    ],
                  ),
                ),
              ),
              const Divider(height: 16),
              _buildHelpItem(
                symbol: '#텍스트#',
                desc: '키워드로 인식하지 않고 일반 텍스트로만 표시됩니다. 카드 링크와 키워드보다 우선순위가 높습니다.',
                exampleInput: '피해량이 #영구#적으로 증가합니다.',
                exampleOutput: const InteractiveCardText(
                  text: '이 "영구"는 일반 텍스트로 표시되며 키워드 일괄 등록 기능에서 제외됩니다.',
                  cardColor: CardColor.colorless,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('닫기', style: TextStyle(color: Colors.amberAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required String symbol,
    required String desc,
    required String exampleInput,
    required Widget exampleOutput,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          symbol,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.amberAccent,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          desc,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '입력: $exampleInput',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('결과: ',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Expanded(child: exampleOutput),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageButton({
    required String label,
    required String? imagePath,
    required VoidCallback onPressed,
    VoidCallback? onRemove,
  }) {
    final hasImage = imagePath != null && imagePath.isNotEmpty;
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          side: BorderSide(
            color: hasImage ? Colors.amberAccent : Colors.grey.withValues(alpha: 0.5),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: AppCardImage(
                  imagePath: imagePath,
                  width: 24,
                  height: 30,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
            ] else ...[
              const Icon(Icons.add_photo_alternate,
                  size: 20, color: Colors.grey),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hasImage ? FontWeight.bold : FontWeight.normal,
                  color: hasImage ? Colors.amberAccent : Colors.white70,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasImage && onRemove != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Colors.redAccent,
                tooltip: '이미지 제거',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isSharedStarter) {
      for (var col in CardColor.playableColors) {
        if (_variantImages[col] == null || _variantImages[col]!.isEmpty) {
          AppToast.show(context, '${col.label}의 기본 이미지를 선택하세요.');
          return;
        }
      }
      _imagePath = _variantImages[CardColor.ironclad] ?? '';
      _color = CardColor.ironclad;
      _rarity = CardRarity.starter;
    } else {
      if (_imagePath == null) {
        AppToast.show(context, '기본 이미지를 선택하세요.');
        return;
      }
    }

    _formKey.currentState!.save();

    final effectText = _effectController.text.trim();
    final upEffectText = _upgradedEffectController.text.trim().isEmpty
        ? null
        : _upgradedEffectController.text.trim();

    if (widget.editCard == null && CardStorage.cardNameExists(_name)) {
      AppToast.show(context, '이미 존재하는 카드 이름입니다.');
      return;
    }

    if (widget.editCard != null &&
        CardStorage.cardNameExists(_name, excludeId: widget.editCard!.id)) {
      AppToast.show(context, '이미 존재하는 카드 이름입니다.');
      return;
    }

    if (_color != CardColor.regent) {
      _starCost = null;
      _upgradedStarCost = null;
    }

    if (_cost != CardCost.cost4Plus) {
      _customCost = null;
    }

    if (_upgradedCost != CardCost.cost4Plus) {
      _upgradedCustomCost = null;
    }

    if (widget.editCard != null) {
      widget.editCard!
        ..name = _name
        ..effect = effectText
        ..color = _color
        ..type = _type
        ..rarity = _rarity
        ..cost = _cost
        ..customCost = _customCost
        ..starCost = _starCost
        ..imagePath = _imagePath!
        ..isMultiplayer = _isMultiplayer
        ..isFavorite = _isFavorite
        ..isRecentlyChanged = _isRecentlyChanged
        ..isSharedStarter = _isSharedStarter
        ..variantImages = _variantImages
        ..upgradedVariantImages = _upgradedVariantImages
        ..upgradedImagePath = _upgradedImagePath
        ..upgradedCost = _upgradedCost
        ..upgradedCustomCost = _upgradedCustomCost
        ..upgradedStarCost = _upgradedStarCost
        ..upgradedEffect = upEffectText
        ..description = _description;
    } else {
      CardStorage.cards.add(CardData(
        id: const Uuid().v4(),
        name: _name,
        effect: effectText,
        color: _color,
        type: _type,
        rarity: _rarity,
        cost: _cost,
        customCost: _customCost,
        starCost: _starCost,
        imagePath: _imagePath!,
        isMultiplayer: _isMultiplayer,
        isFavorite: _isFavorite,
        isRecentlyChanged: _isRecentlyChanged,
        isSharedStarter: _isSharedStarter,
        variantImages: _variantImages,
        upgradedVariantImages: _upgradedVariantImages,
        upgradedImagePath: _upgradedImagePath,
        upgradedCost: _upgradedCost,
        upgradedCustomCost: _upgradedCustomCost,
        upgradedStarCost: _upgradedStarCost,
        upgradedEffect: upEffectText,
        description: _description,
      ));
    }

    await CardStorage.saveCards();
    widget.onSaved();

    if (!mounted) return;
    if (widget.editCard != null) {
      AppToast.show(context, '카드가 수정되었습니다.');
      Navigator.pop(context);
    } else {
      AppToast.show(context, '카드가 추가되었습니다.');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBaseEffect = _effectController.text.trim();
    final dynamicUpgradeHint = currentBaseEffect.isNotEmpty
        ? '기본 효과: $currentBaseEffect'
        : '강화 시 변경될 전체 효과 문구 입력';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editCard != null
            ? (_isSharedStarter ? '공용 카드 수정' : '카드 수정')
            : (_isSharedStarter ? '공용 시작 카드 등록' : '카드 등록')),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'toggle_multi') {
                setState(() => _isMultiplayer = !_isMultiplayer);
                AppToast.show(
                  context,
                  _isMultiplayer ? '멀티플레이 전용 카드로 설정됨' : '멀티플레이 설정이 해제됨',
                );
              } else if (val == 'toggle_changed') {
                setState(() => _isRecentlyChanged = !_isRecentlyChanged);
                AppToast.show(
                  context,
                  _isRecentlyChanged
                      ? '"최근 변경된 카드" 태그가 켜졌음'
                      : '"최근 변경된 카드" 태그가 꺼졌음',
                );
              } else if (val == 'toggle_shared') {
                setState(() {
                  _isSharedStarter = !_isSharedStarter;
                  if (_isSharedStarter) _rarity = CardRarity.starter;
                });
                AppToast.show(
                  context,
                  _isSharedStarter
                      ? '공용 시작 카드(타격/수비) 모드로 전환됨'
                      : '일반 카드 등록 모드로 전환됨',
                );
              } else if (val == 'show_help') {
                _showSyntaxHelpDialog();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'toggle_multi',
                child: Row(
                  children: [
                    Icon(
                      _isMultiplayer
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: Colors.orangeAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('멀티플레이 전용 카드', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_changed',
                child: Row(
                  children: [
                    Icon(
                      _isRecentlyChanged
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: const Color(0xFF5D9CEC),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('최근 변경된 카드', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_shared',
                child: Row(
                  children: [
                    Icon(
                      _isSharedStarter
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: Colors.cyanAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('공용 시작 카드 (타격/수비) 모드',
                        style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'show_help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline,
                        color: Colors.amberAccent, size: 20),
                    SizedBox(width: 8),
                    Text('텍스트 문법 도움말', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isRecentlyChanged || _isMultiplayer) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (_isRecentlyChanged)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5D9CEC).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF5D9CEC)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.update,
                                size: 16, color: Color(0xFF5D9CEC)),
                            SizedBox(width: 6),
                            Text('최근 변경된 카드 태그 활성화됨',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5D9CEC),
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    if (_isMultiplayer)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orangeAccent),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people,
                                size: 16, color: Colors.orangeAccent),
                            SizedBox(width: 6),
                            Text('멀티플레이 전용 카드로 설정됨',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orangeAccent,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (_isSharedStarter) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: Colors.cyanAccent),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '공용 시작 카드 모드: 5개 직업의 일러스트를 한 번에 등록함',
                          style:
                              TextStyle(fontSize: 12, color: Colors.cyanAccent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text('직업별 일러스트 등록 (5×2)',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: CardColor.playableColors.map((color) {
                      final isSelected = _activeEditingColor == color;
                      final hasNormal =
                          _variantImages[color]?.isNotEmpty == true;

                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          avatar: Image.asset(color.iconPath,
                              width: 16,
                              height: 16,
                              errorBuilder: (c, o, s) =>
                                  const SizedBox.shrink()),
                          label: Text(
                            '${color.label} ${hasNormal ? '✓' : ''}',
                            style: TextStyle(
                              color: Color(color.colorHex),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _activeEditingColor = color),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Color(_activeEditingColor.colorHex).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Color(_activeEditingColor.colorHex)
                            .withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '[${_activeEditingColor.label}] 일러스트 설정',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(_activeEditingColor.colorHex)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildImageButton(
                            label: '${_activeEditingColor.label} 기본 *',
                            imagePath: _variantImages[_activeEditingColor],
                            onPressed: () => _pickImage(false,
                                variantColor: _activeEditingColor),
                          ),
                          const SizedBox(width: 8),
                          _buildImageButton(
                            label: '${_activeEditingColor.label} 강화',
                            imagePath:
                                _upgradedVariantImages[_activeEditingColor],
                            onPressed: () => _pickImage(true,
                                variantColor: _activeEditingColor),
                            onRemove: () => setState(() =>
                              _upgradedVariantImages.remove(
                                _activeEditingColor)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    _buildImageButton(
                      label: '기본 이미지 *',
                      imagePath: _imagePath,
                      onPressed: () => _pickImage(false),
                    ),
                    const SizedBox(width: 8),
                    _buildImageButton(
                      label: '강화 이미지',
                      imagePath: _upgradedImagePath,
                      onPressed: () => _pickImage(true),
                      onRemove: () => setState(() => _upgradedImagePath = null),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(
                  labelText: '카드명 *',
                  hintText: '카드 이름 입력',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? '카드명을 입력할 것' : null,
                onSaved: (v) => _name = v!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _effectController,
                contextMenuBuilder: (ctx, state) =>
                    _buildCustomContextMenu(ctx, state, _effectController),
                decoration: InputDecoration(
                  labelText: '카드 기본 효과 *',
                  hintText: '카드 기본 효과 문구 입력',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '카드 효과를 입력할 것' : null,
              ),
              const SizedBox(height: 16),
              if (!_isSharedStarter) ...[
                DropdownButtonFormField<CardColor>(
                  initialValue: _color,
                  decoration: const InputDecoration(
                    labelText: '카드 색상 *',
                    border: OutlineInputBorder(),
                  ),
                  items: CardColor.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.label,
                                style: TextStyle(
                                    color: Color(c.colorHex),
                                    fontWeight: FontWeight.bold)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _color = v;
                      if (_color == CardColor.curse ||
                          _color == CardColor.status ||
                          _color == CardColor.quest) {
                        _type = CardType.other;
                        _rarity = CardRarity.special;
                      } else {
                        if (_type == CardType.other) _type = CardType.attack;

                        final isMainHero =
                            CardColor.playableColors.contains(_color);

                        if (_rarity == CardRarity.special ||
                            _rarity == CardRarity.token ||
                            (!isMainHero && _rarity == CardRarity.starter)) {
                          _rarity = CardRarity.common;
                        }
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              if (_color != CardColor.curse &&
                  _color != CardColor.status &&
                  _color != CardColor.quest) ...[
                DropdownButtonFormField<CardType>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: '카드 종류 *',
                    border: OutlineInputBorder(),
                  ),
                  items: CardType.values
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 16),
                if (!_isSharedStarter) ...[
                  DropdownButtonFormField<CardRarity>(
                    initialValue: _rarity,
                    decoration: const InputDecoration(
                      labelText: '카드 희귀도 *',
                      border: OutlineInputBorder(),
                    ),
                    items: () {
                      final isMainHero =
                          CardColor.playableColors.contains(_color);

                      return [
                        if (isMainHero) CardRarity.starter,
                        CardRarity.common,
                        CardRarity.uncommon,
                        CardRarity.rare,
                        CardRarity.event,
                        CardRarity.token,
                        CardRarity.ancient,
                      ]
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.label,
                                    style: TextStyle(
                                        color: Color(r.colorHex),
                                        fontWeight: FontWeight.bold)),
                              ))
                          .toList();
                    }(),
                    onChanged: (v) => setState(() => _rarity = v!),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
              DropdownButtonFormField<CardCost>(
                initialValue: _cost,
                decoration: const InputDecoration(
                  labelText: '카드 비용 *',
                  border: OutlineInputBorder(),
                ),
                items: CardCost.values
                    .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.label)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _cost = v!;
                    if (_cost == CardCost.cost4Plus && _customCost == null) {
                      _customCost = 4;
                    }
                  });
                },
              ),
              if (_cost == CardCost.cost4Plus) ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _customCost?.toString() ?? '4',
                  decoration: const InputDecoration(
                    labelText: '비용 숫자 직접 입력 (4 이상)',
                    hintText: '4, 5, 6 등 숫자 입력',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (_cost != CardCost.cost4Plus) return null;
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 4) return '4 이상의 정수를 입력할 것';
                    return null;
                  },
                  onSaved: (v) => _customCost = int.tryParse(v ?? '') ?? 4,
                ),
              ],
              if (_color == CardColor.regent && !_isSharedStarter) ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _starCost?.toString() ?? '',
                  decoration: const InputDecoration(
                    labelText: '★ 별 비용 (리젠트 전용, 없으면 공백)',
                    hintText: '숫자 입력 (-1 입력 시 X로 표시)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (v) => _starCost =
                      (v != null && v.isNotEmpty) ? int.tryParse(v) : null,
                ),
              ],
              const SizedBox(height: 28),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.lightGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.lightGreenAccent.withValues(alpha: 0.5),
                      width: 1.2),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.flash_on,
                        color: Colors.lightGreenAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '강화 & 추가 정보 (선택사항)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.lightGreenAccent,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CardCost?>(
                initialValue: _upgradedCost,
                decoration: const InputDecoration(
                  labelText: '강화 시 변경될 비용',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('비용 변경 없음')),
                  ...CardCost.values.map(
                      (c) => DropdownMenuItem(value: c, child: Text(c.label))),
                ],
                onChanged: (v) {
                  setState(() {
                    _upgradedCost = v;
                    if (_upgradedCost == CardCost.cost4Plus &&
                        _upgradedCustomCost == null) {
                      _upgradedCustomCost = 4;
                    }
                  });
                },
              ),
              if (_upgradedCost == CardCost.cost4Plus) ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _upgradedCustomCost?.toString() ?? '4',
                  decoration: const InputDecoration(
                    labelText: '강화 후 비용 숫자 직접 입력 (4 이상)',
                    hintText: '4, 5, 6 등 숫자 입력',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (_upgradedCost != CardCost.cost4Plus) return null;
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 4) return '4 이상의 정수를 입력할 것';
                    return null;
                  },
                  onSaved: (v) =>
                      _upgradedCustomCost = int.tryParse(v ?? '') ?? 4,
                ),
              ],
              if (_color == CardColor.regent && !_isSharedStarter) ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _upgradedStarCost?.toString() ?? '',
                  decoration: const InputDecoration(
                    labelText: '★ 강화 시 변경될 별 비용 (없으면 공백)',
                    hintText: '숫자 입력 (-1 입력 시 X로 표시)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (v) => _upgradedStarCost =
                      (v != null && v.isNotEmpty) ? int.tryParse(v) : null,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('강화 시 대체될 전체 효과',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.copy,
                        size: 14, color: Colors.amberAccent),
                    label: const Text('기본 효과 가져오기',
                        style:
                            TextStyle(fontSize: 12, color: Colors.amberAccent)),
                    onPressed: _copyBaseEffectToUpgrade,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _upgradedEffectController,
                contextMenuBuilder: (ctx, state) => _buildCustomContextMenu(
                    ctx, state, _upgradedEffectController),
                decoration: InputDecoration(
                  labelText: '강화 대체 효과',
                  hintText: dynamicUpgradeHint,
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(
                  labelText: '한마디',
                  hintText: '카드에 대한 간단한 코멘트나 설명 입력',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onSaved: (v) => _description = v,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700]),
                  onPressed: _save,
                  child: Text(
                    widget.editCard != null ? '수정 완료' : '카드 등록',
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
