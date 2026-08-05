import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'シエロのクスッと笑える事件簿',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
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
  List<Incident> _incidents = [];
  List<Incident> _filteredIncidents = [];
  final TextEditingController _searchController = TextEditingController();

  final List<Incident> _initialData = [
    Incident(id: "1", title: "【初めての自動掃除機】謎の動きをする箱に必死の威嚇", date: "2024/08/01", content: "家に自動掃除機がやってきた日のこと。ボタンを押して動き出した瞬間、シエロは耳をピーンと立てて警戒モードに！「ワンワン！」と必死に吠えて威嚇していました。", likes: 5),
    Incident(id: "2", title: "【初めてのカミナリ】へそ天からの一瞬で潜り込み", date: "2024/08/02", content: "大きな雷の音に驚き、爆睡状態から跳び起きて飼い主の膝と布団の隙間に頭だけ突っ込んで震えていました。", likes: 8),
    Incident(id: "3", title: "【初めての鏡】鏡に映る自分とお友達になりたくて…", date: "2024/08/03", content: "姿見の鏡に映った自分を見て大興奮！しっぽをぶんぶん振りながら「あそぼう！」とお辞儀のポーズを取っていました。", likes: 12),
    Incident(id: "4", title: "【初めての水たまり】歩道を歩いていたらまさかの深さに驚愕", date: "2024/08/04", content: "水たまりに前足を突っ込んだところ深さにびっくり。そこからは見つけるたびにジャンプして飛び越えていました。", likes: 10),
    Incident(id: "5", title: "【初めてのプール】足がつかない！エア水泳を披露", date: "2024/08/05", content: "水に入る前から足がシャカシャカ動き出し、見事なエア犬かきを披露してくれました。", likes: 15),
    Incident(id: "6", title: "【初めてのコスプレ】ライオンのたてがみでフリーズ", date: "2024/08/06", content: "ライオンのたてがみを被せられた瞬間、一歩も動けなくなりロボットのような歩みになりました。", likes: 9),
    Incident(id: "7", title: "【初めてのドッグラン】他の犬に圧倒されて飼い主の足元に避難", date: "2024/08/07", content: "元気に走り回ると思いきや、大きなワンちゃんに挨拶されてすかさず飼い主の後ろに隠れていました。", likes: 11),
    Incident(id: "8", title: "【初めての雪】冷たさに驚いて三本足立ち", date: "2024/08/08", content: "積もった雪に足をのせた瞬間「つめたっ！」と言わんばかりに片足を上げて固まっていました。", likes: 14),
    Incident(id: "9", title: "【初めての焼き芋】美味しすぎて目がこぼれそうに", date: "2024/08/09", content: "甘い香りに誘われて身乗り出し、一口食べた瞬間に目を丸くして輝かせていました。", likes: 20),
    Incident(id: "10", title: "【初めてのお留守番】カメラ越しに話しかけたら大混乱", date: "2024/08/10", content: "見守りカメラから声をかけると、姿が見えないのに声がするので首をかしげまくっていました。", likes: 18),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterIncidents);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _incidents = _initialData.map((inc) {
        inc.likes = prefs.getInt('likes_' + inc.id) ?? inc.likes;
        return inc;
      }).toList();
      _filteredIncidents = _incidents;
    });
  }

  void _filterIncidents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredIncidents = _incidents.where((inc) {
        return inc.title.toLowerCase().contains(query) ||
               inc.content.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showRandomIncident() {
    if (_incidents.isEmpty) return;
    final random = Random();
    final incident = _incidents[random.nextInt(_incidents.length)];
    _showIncidentDialog(incident);
  }

  void _showIncidentDialog(Incident incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(incident.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(incident.date, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Text(incident.content),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🐾 シエロのクスッと笑える事件簿 🐾'),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'キーワードで検索...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showRandomIncident,
            icon: const Icon(Icons.casino),
            label: const Text('ランダムで事件を読む！'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredIncidents.length,
              itemBuilder: (context, index) {
                final incident = _filteredIncidents[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.pets, color: Colors.lightBlue),
                    title: Text(incident.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(incident.date),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showIncidentDialog(incident),
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
