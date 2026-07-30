import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'シエロのクスッと笑える事件簿🐾',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          background: const Color(0xFFF0F4F8),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
      ),
      home: const IncidentListPage(),
    );
  }
}

class IncidentListPage extends StatefulWidget {
  const IncidentListPage({super.key});

  @override
  State<IncidentListPage> createState() => _IncidentListPageState();
}

class _IncidentListPageState extends State<IncidentListPage> {
  List<Map<String, dynamic>> _incidents = [
    {
      'title': '勢い余ってベッドの下に吸い込まれた男',
      'detail': '「おやつ！？」の言葉に反応し、リビングの端から時速40kmほどの猛スピードでダッシュしてきたワンコ。\n\nしかしフローリングのワックスが効きすぎていたためブレーキが効かず、そのままドリフト状態で滑り込み……ベッドの下のすき間にスポッと綺麗に吸い込まれていきました。\n\n「……キュン？」とベッドの奥から困惑した声だけが聞こえてきたのがツボでした。',
      'likes': 24,
      'date': '2026/07/28',
      'dogTag': 'ポメラニアン（シエロ）',
      'isLiked': false,
    },
    {
      'title': '15分間の無言の圧力と「虚無の顔」',
      'detail': 'お気に入りの音の鳴るぬいぐるみを、なぜかあごの下にしっかり敷き詰めた状態でフリーズしているワンコ。\n\n声をかけても一切動かず、瞳の焦点を完全に遠くへ合わせたまま「虚無」の顔で15分間固まっていました。\n\n呼吸しているお腹だけがフワフワ動いていて、まるで精巧な置物のよう。急に我に返って「ワン！」と吠えて立ち去っていったのが謎すぎます。',
      'likes': 31,
      'date': '2026/07/29',
      'dogTag': 'トイプードル',
      'isLiked': false,
    },
    {
      'title': '棚の前の無言捜索隊と熱視線',
      'detail': 'おやつの袋が入っているキッチンの棚の前で、まるで「私はここに美味しいものがあることを完全に把握している」と主張するかのように無言で立ち尽くすワンコ。\n\nこちらが視線を向けると、首を斜め45度に傾けながら「チラッ……チラッ……」と棚とこちらの顔を交互に見てアピール。\n\n何も言わないからこそ伝わってくる圧力がすごくて、思わず負けておやつをあげそうになりました。',
      'likes': 19,
      'date': '2026/07/29',
      'dogTag': 'ポメラニアン（シエロ）',
      'isLiked': false,
    },
    {
      'title': 'トリミングで毛が消え、家族全員「誰…？」',
      'detail': '夏場に向けて全体的にすっきりカットしてもらったワンコ。\n\nふわふわの毛で覆われていた体がひと回り小さくなり、まるで別の生き物のようなシルエットになって帰宅しました。\n\n玄関で迎えた家族全員が言葉を失い「……どちら様ですか？」という視線を送ってしまったところ、「えっ、僕だよ！？」と言いたげに首をかしげて尻尾をブンブン振っていました。',
      'likes': 28,
      'date': '2026/07/30',
      'dogTag': '柴犬',
      'isLiked': false,
    },
  ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _sortOption = 'newest';
  String _selectedFilterTag = 'すべて';
  bool _isAdminMode = false;

  String _selectedDogTag = 'ポメラニアン（シエロ）';

  // ★ 最後のタグを「その他のわんちゃん」に変更！
  final List<String> _dogTags = [
    'ポメラニアン（シエロ）',
    'トイプードル',
    '柴犬',
    'チワワ',
    'その他のわんちゃん',
  ];

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _saveIncidents() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_incidents);
    await prefs.setString('saved_incidents', encodedData);
  }

  Future<void> _loadIncidents() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('saved_incidents');
    if (savedData != null) {
      List<dynamic> loadedList = jsonDecode(savedData);
      setState(() {
        _incidents = loadedList.map((item) {
          Map<String, dynamic> map = Map<String, dynamic>.from(item);
          if (map['title'] != null) {
            map['title'] = map['title'].toString().replaceAll('【事件】', '');
          }
          map['dogTag'] ??= 'ポメラニアン（シエロ）';
          map['isLiked'] ??= false;
          return map;
        }).toList();
      });
    }
  }

  String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> _getFilteredAndSortedIncidents() {
    List<Map<String, dynamic>> filtered = _incidents.where((item) {
      final title = item['title'].toString().toLowerCase();
      final detail = item['detail'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      final tag = item['dogTag'] ?? '';

      bool matchesQuery = title.contains(query) || detail.contains(query);
      bool matchesTag = (_selectedFilterTag == 'すべて') || (tag == _selectedFilterTag);

      return matchesQuery && matchesTag;
    }).toList();

    if (_sortOption == 'newest') {
      filtered = filtered.reversed.toList();
    } else if (_sortOption == 'likes') {
      filtered.sort((a, b) => (b['likes'] as int).compareTo(a['likes'] as int));
    }

    return filtered;
  }

  void _toggleAdminMode() {
    setState(() {
      _isAdminMode = !_isAdminMode;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isAdminMode ? '🔧 管理者モードに切り替えました' : '👀 読者モードに切り替えました'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 本文をクリップボードにコピーしました！'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> item, int originalIndex) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isLiked = item['isLiked'] ?? false;
          return AlertDialog(
            backgroundColor: const Color(0xFFEBF3FA),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E88E5).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🐶 ${item['dogTag'] ?? 'わんこ'}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF1565C0), fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(item['date'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0D47A1))),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['detail'], style: TextStyle(color: Colors.grey[900], fontSize: 15, height: 1.6)),
                  const SizedBox(height: 15),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _copyToClipboard('${item['title']}\n\n${item['detail']}'),
                      icon: const Icon(Icons.copy, size: 16, color: Color(0xFF1976D2)),
                      label: const Text('本文をコピー', style: TextStyle(color: Color(0xFF1976D2), fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1976D2)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.pinkAccent : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            if (isLiked) {
                              _incidents[originalIndex]['likes']--;
                              _incidents[originalIndex]['isLiked'] = false;
                            } else {
                              _incidents[originalIndex]['likes']++;
                              _incidents[originalIndex]['isLiked'] = true;
                            }
                          });
                          setDialogState(() {});
                          _saveIncidents();
                        },
                      ),
                      Text('${item['likes']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('閉じる', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  void _showRandomIncident() {
    if (_incidents.isEmpty) return;
    final random = Random();
    final index = random.nextInt(_incidents.length);
    _showDetailDialog(_incidents[index], index);
  }

  void _openAddModal() {
    _titleController.clear();
    _detailController.clear();
    _selectedDogTag = 'ポメラニアン（シエロ）';

    _showFormModal(
      modalTitle: '✍️ 新しい事件を記録する',
      buttonText: '事件簿に登録する',
      onSubmit: () {
        if (_titleController.text.isEmpty || _detailController.text.isEmpty) return;
        setState(() {
          _incidents.add({
            'title': _titleController.text,
            'detail': _detailController.text,
            'likes': 0,
            'date': _getTodayDate(),
            'dogTag': _selectedDogTag,
            'isLiked': false,
          });
        });
        _saveIncidents();
        Navigator.pop(context);
      },
    );
  }

  void _openEditModal(int originalIndex) {
    final currentItem = _incidents[originalIndex];

    _titleController.text = currentItem['title'].toString().replaceAll('【事件】', '');
    _detailController.text = currentItem['detail'];
    _selectedDogTag = _dogTags.contains(currentItem['dogTag']) ? currentItem['dogTag'] : 'ポメラニアン（シエロ）';

    _showFormModal(
      modalTitle: '✏️ 事件を修正・書き直す',
      buttonText: '修正内容を保存する',
      onSubmit: () {
        if (_titleController.text.isEmpty || _detailController.text.isEmpty) return;
        setState(() {
          _incidents[originalIndex]['title'] = _titleController.text;
          _incidents[originalIndex]['detail'] = _detailController.text;
          _incidents[originalIndex]['dogTag'] = _selectedDogTag;
        });
        _saveIncidents();
        Navigator.pop(context);
      },
    );
  }

  void _deleteIncident(int originalIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFEBF3FA),
        title: const Text('🗑️ 事件の削除'),
        content: const Text('この事件記録を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
            onPressed: () {
              setState(() {
                _incidents.removeAt(originalIndex);
              });
              _saveIncidents();
              Navigator.pop(context);
            },
            child: const Text('削除する', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFormModal({
    required String modalTitle,
    required String buttonText,
    required VoidCallback onSubmit,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFEBF3FA),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 25,
            left: 25,
            right: 25,
            bottom: MediaQuery.of(context).viewInsets.bottom + 25,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(modalTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
              const SizedBox(height: 15),
              const Text('主役のワンコ:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
              const SizedBox(height: 5),
              DropdownButton<String>(
                value: _selectedDogTag,
                isExpanded: true,
                items: _dogTags.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setModalState(() {
                    _selectedDogTag = newValue!;
                  });
                },
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '事件のタイトル',
                  hintText: '例：ベッドの下に吸い込まれた',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E88E5))),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _detailController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: '事件の詳細',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1E88E5))),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5)),
                  child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _getFilteredAndSortedIncidents();
    final filterOptions = ['すべて', ..._dogTags];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        toolbarHeight: 70,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: const Icon(Icons.pets, color: Color(0xFF1E88E5), size: 24),
            ),
            const SizedBox(width: 10),
            const Text(
              'シエロのクスッと笑える事件簿🐾',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 19,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 3,
        actions: [
          IconButton(
            icon: Icon(
              _isAdminMode ? Icons.admin_panel_settings : Icons.lock_outline,
              color: Colors.white,
            ),
            tooltip: _isAdminMode ? '読者モードに戻る' : '管理者モードを開く',
            onPressed: _toggleAdminMode,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'キーワードで検索...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF1976D2)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort, color: Color(0xFF1976D2), size: 28),
                  tooltip: '並び替え',
                  onSelected: (value) {
                    setState(() {
                      _sortOption = value;
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'newest', child: Text('🆕 新しい順')),
                    const PopupMenuItem(value: 'oldest', child: Text('📜 古い順')),
                    const PopupMenuItem(value: 'likes', child: Text('❤️ いいねが多い順')),
                  ],
                ),
              ],
            ),
          ),
          // ★ 幅いっぱいに伸びて横スクロールする修正版タグバー！
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: filterOptions.map((tag) {
                  final isSelected = _selectedFilterTag == tag;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: RawChip(
                      label: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF1565C0),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF1E88E5),
                      backgroundColor: Colors.white,
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF1E88E5) : const Color(0xFFBBDEFB),
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilterTag = tag;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            child: ElevatedButton.icon(
              onPressed: _showRandomIncident,
              icon: const Icon(Icons.casino, color: Colors.white),
              label: const Text('ランダムで事件を読む！', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                elevation: 2,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFBBDEFB)),
          Expanded(
            child: displayList.isEmpty
                ? const Center(child: Text('該当する事件が見つかりません 🐾'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final item = displayList[index];
                      final originalIndex = _incidents.indexOf(item);

                      return Card(
                        color: Colors.white,
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 10.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                          leading: const Icon(Icons.pets, color: Color(0xFF1E88E5)),
                          title: Text(
                            item['title'],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Row(
                            children: [
                              Text('❤️ ${item['likes']} ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(width: 8),
                              Text('📅 ${item['date'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E88E5).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item['dogTag'] ?? 'わんこ',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF1565C0)),
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _showDetailDialog(item, originalIndex),
                          trailing: _isAdminMode
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                                      tooltip: '編集',
                                      onPressed: () => _openEditModal(originalIndex),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                      tooltip: '削除',
                                      onPressed: () => _deleteIncident(originalIndex),
                                    ),
                                  ],
                                )
                              : const Icon(Icons.chevron_right, color: Colors.grey),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _isAdminMode
          ? FloatingActionButton.extended(
              onPressed: _openAddModal,
              backgroundColor: const Color(0xFF1E88E5),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('事件を記録', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}