import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

class Incident {
  final String id;
  final String title;
  final String date;
  final String content;
  int likes;

  Incident({
    required this.id,
    required this.title,
    required this.date,
    required this.content,
    this.likes = 0,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      content: json['content'] ?? '',
      likes: json['likes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'content': content,
      'likes': likes,
    };
  }
}

class IncidentListPage extends StatefulWidget {
  const IncidentListPage({super.key});

  @override
  State<IncidentListPage> createState() => _IncidentListPageState();
}

class _IncidentListPageState extends State<IncidentListPage> {
  List<Incident> _allIncidents = [];
  List<Incident> _filteredIncidents = [];
  final TextEditingController _searchController = TextEditingController();
  Set<String> _likedIncidentIds = {};
  bool _isAdminMode = false;

  @override
  void initState() {
    super.initState();
    _loadLikedStatus();
    _loadIncidents();
  }

  Future<void> _loadLikedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _likedIncidentIds = (prefs.getStringList('liked_incidents') ?? []).toSet();
    });
  }

  Future<void> _toggleLike(Incident incident) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_likedIncidentIds.contains(incident.id)) {
        _likedIncidentIds.remove(incident.id);
        incident.likes = max(0, incident.likes - 1);
      } else {
        _likedIncidentIds.add(incident.id);
        incident.likes += 1;
      }
    });
    await prefs.setStringList('liked_incidents', _likedIncidentIds.toList());
    await prefs.setInt('likes_${incident.id}', incident.likes);
  }

  Future<void> _loadIncidents() async {
    try {
      final String response = await rootBundle.loadString('assets/incidents.json');
      final List<dynamic> data = json.decode(response);
      final incidents = data.map((json) => Incident.fromJson(json)).toList();
      
      final prefs = await SharedPreferences.getInstance();
      for (var inc in incidents) {
        int storedLikes = prefs.getInt('likes_${inc.id}') ?? inc.likes;
        inc.likes = storedLikes;
      }

      setState(() {
        _allIncidents = incidents;
        _filteredIncidents = incidents;
      });
    } catch (e) {
      debugPrint('Error loading incidents: $e');
    }
  }

  void _filterIncidents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredIncidents = _allIncidents.where((incident) {
        final matchesSearch = incident.title.toLowerCase().contains(query) ||
            incident.content.toLowerCase().contains(query);
        return matchesSearch;
      }).toList();
    });
  }

  void _deleteIncident(Incident incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('事件の削除'),
        content: Text('「${incident.title}」を本当に削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _allIncidents.removeWhere((item) => item.id == incident.id);
                _filterIncidents();
              });
              Navigator.pop(context); // アラート閉じる
              Navigator.pop(context); // 詳細ダイアログ閉じる
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('事件を削除しました')),
              );
            },
            child: const Text('削除する', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRandomIncident() {
    if (_allIncidents.isEmpty) return;
    final random = Random();
    final randomIncident = _allIncidents[random.nextInt(_allIncidents.length)];
    _showIncidentDetail(randomIncident);
  }

  void _showAddIncidentDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新しい事件を追加 🐾'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'タイトル'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: '事件内容'),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty || contentController.text.isEmpty) return;
              final newIncident = Incident(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleController.text,
                date: "${DateTime.now().year}/${DateTime.now().month}/${DateTime.now().day}",
                content: contentController.text,
                likes: 0,
              );
              setState(() {
                _allIncidents.insert(0, newIncident);
                _filterIncidents();
              });
              Navigator.pop(context);
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  void _showIncidentDetail(Incident incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isLiked = _likedIncidentIds.contains(incident.id);
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(incident.date, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  incident.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
                const Divider(height: 32),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      incident.content,
                      style: const TextStyle(fontSize: 16, height: 1.6, color: Color(0xFF34495E)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    InkWell(
                      onTap: () async {
                        await _toggleLike(incident);
                        setModalState(() {});
                      },
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey,
                            size: 28,
                          ),
                          const SizedBox(width: 6),
                          Text('${incident.likes}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (_isAdminMode) ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _deleteIncident(incident),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('削除'),
                      ),
                      const SizedBox(width: 12),
                    ],
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('閉じる', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, color: Colors.pinkAccent, size: 22),
            SizedBox(width: 8),
            Text(
              'シエロのクスッと笑える事件簿',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(width: 8),
            Icon(Icons.pets, color: Colors.pinkAccent, size: 22),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1E88E5),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _filterIncidents(),
                  decoration: InputDecoration(
                    hintText: 'キーワードで検索...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF1E88E5)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _showRandomIncident,
                  icon: const Icon(Icons.casino, color: Colors.white),
                  label: const Text('ランダムで事件を読む！', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF29B6F6),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isAdminMode = !_isAdminMode;
                    });
                  },
                  icon: Icon(
                    _isAdminMode ? Icons.admin_panel_settings : Icons.person_outline,
                    color: _isAdminMode ? Colors.orange[800] : const Color(0xFF1E88E5),
                  ),
                  label: Text(
                    _isAdminMode ? '👑 管理者モード中' : '👤 読者モード中',
                    style: TextStyle(
                      color: _isAdminMode ? Colors.orange[800] : const Color(0xFF1E88E5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _isAdminMode ? Colors.orange[50] : Colors.white,
                    side: BorderSide(
                      color: _isAdminMode ? Colors.orange : const Color(0xFF1E88E5),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredIncidents.length,
              itemBuilder: (context, index) {
                final incident = _filteredIncidents[index];
                final isLiked = _likedIncidentIds.contains(incident.id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE3F2FD),
                      child: Icon(Icons.pets, color: Color(0xFF1E88E5)),
                    ),
                    title: Text(
                      incident.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C3E50)),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => _toggleLike(incident),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    size: 16,
                                    color: isLiked ? Colors.red : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text('${incident.likes}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(incident.date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => _showIncidentDetail(incident),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isAdminMode
          ? FloatingActionButton.extended(
              onPressed: _showAddIncidentDialog,
              backgroundColor: const Color(0xFF1E88E5),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('新規事件を追加', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}
// update url base to cielo-incidents
// trigger rebuild
// force rebuild timestamp: 1785671804
// update: Sun Aug  2 21:22:21 JST 2026
