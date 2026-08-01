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
  final String dogBreed;
  final String content;
  int likes;

  Incident({
    required this.id,
    required this.title,
    required this.date,
    required this.dogBreed,
    required this.content,
    this.likes = 0,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      dogBreed: json['dogBreed'] ?? '',
      content: json['content'] ?? '',
      likes: json['likes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'dogBreed': dogBreed,
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

  void _showRandomIncident() {
    if (_allIncidents.isEmpty) return;
    final random = Random();
    final randomIncident = _allIncidents[random.nextInt(_allIncidents.length)];
    _showIncidentDetail(randomIncident);
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        incident.dogBreed,
                        style: const TextStyle(color: Color(0xFF1976D2), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    Text(incident.date, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                        size: 28,
                      ),
                      onPressed: () async {
                        await _toggleLike(incident);
                        setModalState(() {});
                      },
                    ),
                    Text('${incident.likes}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'シエロのクスッと笑える事件簿🐾',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
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
            child: ElevatedButton.icon(
              onPressed: _showRandomIncident,
              icon: const Icon(Icons.casino, color: Colors.white),
              label: const Text('ランダムで事件を読む！', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF29B6F6),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
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
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 14,
                            color: isLiked ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text('${incident.likes}', style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 12),
                          const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(incident.date, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                          Text(
                            incident.dogBreed,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF1E88E5)),
                          ),
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
    );
  }
}