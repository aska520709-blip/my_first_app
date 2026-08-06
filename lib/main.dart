import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'シエロのクスッと笑える事件簿',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      home: const StoryListPage(),
    );
  }
}

class Story {
  String id;
  String title;
  String date;
  String dogBreed;
  String content;
  int likes;

  Story({
    required this.id,
    required this.title,
    required this.date,
    required this.dogBreed,
    required this.content,
    this.likes = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'dogBreed': dogBreed,
        'content': content,
        'likes': likes,
      };

  factory Story.fromJson(Map<String, dynamic> json) => Story(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        date: json['date'] ?? '',
        dogBreed: json['dogBreed'] ?? 'トイプードル',
        content: json['content'] ?? '',
        likes: json['likes'] ?? 0,
      );
}

class StoryListPage extends StatefulWidget {
  const StoryListPage({super.key});

  @override
  State<StoryListPage> createState() => _StoryListPageState();
}

class _StoryListPageState extends State<StoryListPage> {
  bool isAdminMode = false;
  String searchQuery = '';
  List<Story> stories = [];

  final List<Story> initialStories = [
    Story(
      id: "1",
      title: "【初めての自動掃除機】",
      date: "2026/08/04",
      dogBreed: "トイプードル",
      content: "リビングに突如あらわれたブーンと鳴る丸い物体。シエロは「我が家の平和を守らねば！」と果敢にワンワン吠えて威嚇を開始。しかし、自動掃除機が一切動じずにスーッと自分に向かって進んでくると、一瞬で敗北を悟り、ソファの上に避難。上から必死に「こっち来るな！」と前足でチョップを繰り出していました。最終的に掃除機が壁に当たってターンしたのを見て、「よし、追い払ったぞ」と言いたげなドヤ顔を決めていました。",
    ),
    Story(
      id: "2",
      title: "【初めてのサマーカット】",
      date: "2026/08/04",
      dogBreed: "トイプードル",
      content: "トリミングから帰宅し、すっかり首回りがスッキリしたシエロ。ふと姿見の鏡の前に立った瞬間、「え、誰……？」という顔でピタッとフリーズ。一度後ずさりしてから、もう一度鏡を覗き込み、自分の体の匂いをクンクン。間違いなく自分だと理解した途端、急に自分のしっぽや胴体を不思議そうに追いかけ回し始めました。しばらくの間、「僕の毛皮、どこやったの？」と言いたげな瞳でこちらを見つめていました。",
    ),
    Story(
      id: "3",
      title: "【初めての焼き芋】",
      date: "2026/08/04",
      dogBreed: "トイプードル",
      content: "普段はおやつを見ても「お上品」にお座りするシエロ。しかし、ほくほくの焼き芋を小さくちぎって鼻気に近づけた瞬間、目が限界まで見開かれました。ひと口食べた瞬間、雷が落ちたような衝撃を受けたようで、未だかつてない素早さで「おかわり！」のお手・おかわり・ハイタッチをノータイムで高速連打。食べ終わったあとも、焼き芋が入っていた袋の「空気」をずっと吸い込んでいました。",
    ),
    Story(
      id: "4",
      title: "【初めてのお風呂】",
      date: "2026/08/04",
      dogBreed: "トイプードル",
      content: "お風呂場に連れていかれ、シャワーの音が響いた瞬間、すべてを悟ったシエロ。「僕は今、人生最大の危機に瀕している」と言わんばかりに、風呂場の隅で虚無の表情を浮かべて完全にフリーズ。ぬるま湯がかかると「たすけて……」という目で見つめてくるものの、シャンプーが終わってバスタオルで包んだ瞬間、スイッチが完全に切り替わりました。「お風呂から生還したぞーーー！」と言わんばかりにテンションが爆発し、リビングのカーペットに顔を擦り付けながら猛スピードで猛ダッシュ。乾かし終わる頃には自分の達成感に酔いしれて、ドヤ顔でぐっすり眠っていました。",
    ),
    Story(
      id: "5",
      title: "【初めてのドッグラン】",
      date: "2026/08/04",
      dogBreed: "トイプードル",
      content: "「広いところで思いっきり走れるぞ！」とワクワクでドッグランに足をふみ入れたシエロ。しかし、入口をくぐった瞬間に元気いっぱいの大型犬たちが「いらっしゃい！」と一斉に駆け寄ってくると、一瞬で顔がひきつりました。そのまま飼い主の足の間にスポッとハマり、「ここが僕の安全地帯です」と言わんばかりに頑固な要塞を建築。他のわんちゃんが去ったあと、ぽつんと貸切状態になった端っこのエリアでだけ、小さく「トタトタ…」とドヤ顔で走っていました。",
    ),
    Story(
      id: "6",
      title: "【初めての服】",
      date: "2026/08/04",
      dogBreed: "トイプードル",
      content: "寒さ対策のために、可愛らしいおしゃれな洋服を着せられたシエロ。を着た瞬間、「え……体が重くて動けないシステム……？」と勘違いしたのか、ロボットのように関節を一切曲げずにカチコチに固まってしまいました。一歩も歩こうとせず、そのまま横に「コテン」と倒れて置物と化す始末。しかし、大好物のおやつの袋をカサッと鳴らした瞬間、服を着ていることも忘れて「シャキーン！」と素早く起き上がり、完璧なお座りを決めていました。",
    ),
    Story(
      id: "7",
      title: "【初めての雪】",
      date: "2026/08/04",
      dogBreed: "トイプードル",
      content: "朝起きて庭一面が真っ白になっているのを見て、大興奮で外へ飛び出したシエロ。最初は「冷たくてフワフワだー！」と跳ね回っていたものの、足裏に冷たさが染み込んできた瞬間にフリーズ。「聞いてない、こんなに冷たいなんて聞いてない」と言わんばかりに、片足をあげたまま固まってしまいました。抱っこで部屋に戻すと、こたつの中に吸い込まれるように潜り込み、鼻先だけをひょっこり出して二度と出てこなくなりました。",
    ),
    Story(
      id: "8",
      title: "【初めての散歩】",
      date: "2026/08/04",
      dogBreed: "トイプードル",
      content: "ワクワクでハーネスを装着し、いざ外の世界へ足を踏み出したシエロ。「これが世界か…！」と目を輝かせたのも束の間、カサッと揺れた落ち葉ひとつに飛び上がり、風で舞ったレジ袋を謎の巨大生命体と勘違いしてパニックに。10メートル進むのに5分かかり、歩道橋の下を通る時は「天井が落ちてくるかもしれない」と言わんばかりに姿勢を限界まで低くしてほふくぜんしん。結局、全体の8割は抱っこされて移動し、家に戻った瞬間に「外は危険がいっぱいだった…」と満足げな顔で爆睡していました。",
    ),
    Story(
      id: "9",
      title: "【初めてのお留守番】",
      date: "2026/08/04",
      dogBreed: "トイプードル",
      content: "飼い主が「すぐ戻るからね」と声をかけてドアを閉めた瞬間、シエロの単独ミッションがスタート。最初の5分間はドアの前で「本当に帰ってくる……？」と耳を澄ませてたたずんでいましたが、静けさに慣れてくると「さて、自由時間だな」と言わんばかりにリビングのパトロールを開始。クッションにダイブしたり、自分のハウスからおもちゃを総動員して床一面に並べたりと大忙し。カギが開く音がした瞬間、慌てて「ずっと良い子で待ってましたけど？」という顔でドアの前に駆け寄り、お利口さんアピールを決めていました。（※足元には散らかったおもちゃが転がっていました）",
    ),
    Story(
      id: "10",
      title: "【初めての雨】",
      date: "2026/08/04",
      dogBreed: "トイプードル",
      content: "ポツポツと音が鳴り始め、外の景色が一変した日。抱っこされて玄関から外を覗き込んだシエロは、空から降ってくる大量の「水滴」に大混乱。「空からお水が降ってくるなんて聞いてない…！」と言わんばかりに目を丸くし、自分の鼻気に一滴ぽたんと落ちた瞬間、ヒヤッとした冷たさに「ひゃん！」と小さく跳ね上がりました。水たまりを見つめては「踏んだら底なしnumaに沈むのでは…？」と警戒し、一歩も足をつけようとしません。結局、雨の音をバックに飼い主の腕の中でカチコチに固まったまま、初めての雨見学は終了しました。",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    final prefs = await SharedPreferences.getInstance();
    final String? version = prefs.getString('data_version');
    if (version != '2026_pass_v99') {
      await prefs.clear();
      await prefs.setString('data_version', '2026_pass_v99');
    }

    final String? storiesJson = prefs.getString('saved_stories');
    if (storiesJson != null && storiesJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(storiesJson);
      setState(() {
        stories = decoded.map((item) => Story.fromJson(item)).toList();
      });
    } else {
      setState(() {
        stories = List.from(initialStories);
      });
      _saveStories();
    }
  }

  Future<void> _saveStories() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(stories.map((s) => s.toJson()).toList());
    await prefs.setString('saved_stories', encoded);
  }

  void _incrementLike(Story story) {
    setState(() {
      story.likes++;
    });
    _saveStories();
  }

  void _toggleAdminMode(bool value) {
    if (value) {
      final passController = TextEditingController();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('🔒 管理者パスワード入力'),
          content: TextField(
            controller: passController,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'パスワードを入力 (初期: 1234)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  isAdminMode = false;
                });
                Navigator.pop(context);
              },
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                if (passController.text == '1234') {
                  setState(() {
                    isAdminMode = true;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('管理者モードに切り替えました')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('パスワードが違います')),
                  );
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        isAdminMode = false;
      });
    }
  }

  void _addOrEditStory({Story? story}) {
    final titleController = TextEditingController(text: story?.title ?? '');
    final dateController = TextEditingController(text: story?.date ?? '2026/08/04');
    final breedController = TextEditingController(text: story?.dogBreed ?? 'トイプードル');
    final contentController = TextEditingController(text: story?.content ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(story == null ? '新しい事件を投稿' : '事件を編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'タイトル'),
              ),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: '日付 (例: 2026/08/04)'),
              ),
              TextField(
                controller: breedController,
                decoration: const InputDecoration(labelText: '犬種'),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: '本文'),
                maxLines: 5,
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
              if (titleController.text.isNotEmpty) {
                setState(() {
                  if (story == null) {
                    stories.insert(
                      0,
                      Story(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleController.text,
                        date: dateController.text,
                        dogBreed: breedController.text,
                        content: contentController.text,
                      ),
                    );
                  } else {
                    story.title = titleController.text;
                    story.date = dateController.text;
                    story.dogBreed = breedController.text;
                    story.content = contentController.text;
                  }
                });
                _saveStories();
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _deleteStory(Story story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除の確認'),
        content: Text('「${story.title}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                stories.removeWhere((s) => s.id == story.id);
              });
              _saveStories();
              Navigator.pop(context);
            },
            child: const Text('削除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredStories = stories.where((story) {
      return story.title.contains(searchQuery) ||
          story.content.contains(searchQuery) ||
          story.dogBreed.contains(searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🐾 シエロのクスッと笑える事件簿 🐾'),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
        actions: [
          Row(
            children: [
              Text(
                isAdminMode ? '管理者' : '読者',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Switch(
                value: isAdminMode,
                onChanged: _toggleAdminMode,
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'キーワードで検索...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: Colors.lightBlue.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.lightBlueAccent.shade100, width: 1.5),
            ),
            child: Column(
              children: [
                const Text(
                  '🐶 こんにちは！トイプードルのシエロです！',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.lightBlue),
                ),
                const SizedBox(height: 4),
                Text(
                  'ボクの日常のちょっと笑える事件をあつめたよ。\n読んだあと「クスッ」としたら、ぜひ右側の ❤️（いいね）を押してね！',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.7), height: 1.4),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredStories.isEmpty
                ? const Center(child: Text('該当する記事がありません'))
                : ListView.builder(
                    itemCount: filteredStories.length,
                    itemBuilder: (context, index) {
                      final story = filteredStories[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.pets, color: Colors.lightBlue),
                          title: Text(
                            story.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${story.date}   ❤️ ${story.likes}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.favorite, color: Colors.pinkAccent),
                                onPressed: () => _incrementLike(story),
                              ),
                              if (isAdminMode) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () => _addOrEditStory(story: story),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteStory(story),
                                ),
                              ] else
                                const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StoryDetailPage(
                                  story: story,
                                  onLike: () => _incrementLike(story),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: isAdminMode
          ? FloatingActionButton(
              onPressed: () => _addOrEditStory(),
              backgroundColor: Colors.lightBlueAccent,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class StoryDetailPage extends StatefulWidget {
  final Story story;
  final VoidCallback onLike;

  const StoryDetailPage({super.key, required this.story, required this.onLike});

  @override
  State<StoryDetailPage> createState() => _StoryDetailPageState();
}

class _StoryDetailPageState extends State<StoryDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.story.title),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.story.date,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      widget.onLike();
                    });
                  },
                  icon: const Icon(Icons.favorite, color: Colors.pinkAccent),
                  label: Text('いいね！ (${widget.story.likes})'),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  widget.story.content,
                  style: const TextStyle(fontSize: 16, height: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
