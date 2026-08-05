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
  String content;
  int likes;

  Story({
    required this.id,
    required this.title,
    required this.date,
    required this.content,
    this.likes = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'content': content,
        'likes': likes,
      };

  factory Story.fromJson(Map<String, dynamic> json) => Story(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        date: json['date'] ?? '',
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
      id: '1',
      title: '【初めての自動掃除機】謎の動きをする箱に必死の威嚇',
      date: '2026/08/01',
      content: '''我が家にやってきた自動掃除機（ルンバ）。
ウィーンと音を立てて動き出した瞬間、シエロの目が点になりました。

「な、なんだこの生き物は…！？」

低い姿勢をとって「ウゥ〜ッ」と威嚇を開始。
掃除機が近づいてくると、脱兎のごとくソファの上に避難！
ソファの上から必死に前足パンチ（届いていない）を繰り出して戦っていました。

今ではすっかり慣れて、動く掃除機の後ろをドヤ顔でストーカーのように追跡しています。''',
    ),
    Story(
      id: '2',
      title: '【初めてのカミナリ】へそ天からの瞬時に潜り込み',
      date: '2026/08/02',
      content: '''ヘソ天（仰向け）で爆睡していた夏の日。
突如「ゴロゴロ…ドカン！」と大きな雷鳴が轟きました。

その瞬間、シエロは目にも留まらぬ速さで跳ね起き、飼い主の膝掛けブランケットの中に一直線！
完全に頭から潜り込んで、お尻だけが丸見え状態に。

「頭隠して尻隠さず」を地で行くシエロ。
しばらくの間、ブランケットの中でプルプル震えながら飼い主の手に鼻先を押し付けて甘えていました。''',
    ),
    Story(
      id: '3',
      title: '【初めての鏡】鏡に映る自分とお友達になりたくて…',
      date: '2026/08/03',
      content: '''姿見の鏡を部屋に置いた日のこと。
ふと鏡の前に立ったシエロは、そこに写る自分（イケメン犬）と遭遇しました。

「あ！新しいお友達だ！」と言わんばかりに尻尾をぶんぶん振り回し、お気に入りのオモチャを咥えて鏡の前へ持っていきます。

ポトンとオモチャを置いて「遊ぼうよ！」とワンワン吠えるものの、鏡の中のお友達は一向にオモチャを拾ってくれません。
最後は「なんで遊んでくれないの？」という顔で鏡の後ろを覗き込んで首をかしげていました。''',
    ),
    Story(
      id: '4',
      title: '【初めての水たまり】歩道を歩いていたらまさかの深さに驚愕',
      date: '2026/08/04',
      content: '''雨上がりの散歩道。
楽しそうに先頭を歩いていたシエロは、アスファルトにある浅い水たまりを見つけました。

豪快にバシャバシャ踏み込んで遊ぶのかと思いきや…
足先が少し濡れた瞬間、「ひゃんっ！？」と奇声を上げて垂直ジャンプ！

想像以上に冷たかったのか、足が濡れたのが嫌だったのか、そこからは水たまりを一つ一つ丁寧に回避する「慎重派シエロ」に変身しました。''',
    ),
    Story(
      id: '5',
      title: '【初めてのプール】足がつかない！エア水泳を披露',
      date: '2026/08/05',
      content: '''暑い夏の日、ドッグランの小型犬用プールに初挑戦。
水が怖くないように抱っこして、ゆっくりと水面に近づけていくと…

水に入る前から、足が空中でバタバタバタ！！
見事な「エア犬かき」を披露してくれました。

実際に足がつく浅瀬に着地すると、「あれ？足届くじゃん」と気づいた様子。
そこからはパシャパシャと気持ちよさそうに歩き回っていました。''',
    ),
    Story(
      id: '6',
      title: '【初めてのコスプレ】ライオンのたてがみでフリーズ',
      date: '2026/08/06',
      content: '''ハロウィン用に買ったライオンのたてがみウィッグ。
シエロにかぶせてみると…ぴったり！可愛すぎる百獣の王の誕生です！

しかし、当の本人は違和感からか「ピタッ」と微動だにせずフリーズ。
ロボットのようにカチコチになったまま、目だけをキョロキョロさせて救いを求めてきました。

「かっこいいよー！」と褒めちぎると、調子に乗って尻尾を振り始めましたが、歩くときはやっぱりロボット歩きでした。''',
    ),
    Story(
      id: '7',
      title: '【初めてのドッグラン】他の犬に圧倒されて飼い主の足元に避難',
      date: '2026/08/07',
      content: '''広大なドッグランにデビュー！
家では威勢のいいシエロですが、大きなワンちゃんや元気なワンちゃんたちが一斉に挨拶（クンクン）しに集まってくると…

目が泳ぎ始め、そのまま飼い主の足の間にスポッと挟まって避難！
「ボクはいません、ただの置物です」と言わんばかりに存在感を消そうとしていました。

慣れてくると自分と同じサイズのワンちゃんとおっかけっこを楽しんでいました。''',
    ),
    Story(
      id: '8',
      title: '【初めてのエレベーター】床が動く謎の部屋に困惑',
      date: '2026/08/08',
      content: '''マンションのエレベーターに初めて乗った時。
扉が閉まり、「ウィーン」と浮遊感が襲うと、シエロは不思議そうに足元をジッと見つめました。

「床が動いている…！？」とペタッと伏せの姿勢をとって警戒態勢に。

目的の階に着いて「チン♪」と音が鳴り扉が開くと、弾丸のようなスピードで外へダッシュ！
「ふぅ、あやうく閉じ込められるところだったワン…」と胸をなでおろしていました。''',
    ),
    Story(
      id: '9',
      title: '【初めてのシャンプー】お風呂場で別の生き物に変身',
      date: '2026/08/09',
      content: '''お風呂の時間。シャワーで体が濡れると…
普段のフワフワな毛ぶきが嘘のようにしぼんで、まるで「細身の宇宙人」のような姿に！

「誰ですか！？」と思わず突っ込みたくなる変身ぶりです。

ドライヤーで乾かしてもらうと、再びフワフワの綿あめシエロに復活。
自分の体の変わりように、鏡を見て自分でもびっくりしているようでした。''',
    ),
    Story(
      id: '10',
      title: '【初めての雪】冷たい白い粉にテンション爆発',
      date: '2026/08/10',
      content: '''冬の朝、庭にうっすらと雪が積もりました。
外に出たシエロは、足元に広がる真っ白な景色に大興奮！

鼻先を雪に突っ込んで「ズボッ」、そのまま前足で雪を掘って「バシャバシャ！」。
顔中を真っ白にして大はしゃぎしていました。

家に入った後は、暖かいこたつの前でポカポカになりながら爆睡。
夢の中でも雪の中で走っていたのか、足をピクピク動かしていました。''',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    final prefs = await SharedPreferences.getInstance();
    // 日付更新用のバージョンチェック
    final String? version = prefs.getString('data_version');
    if (version != '2026_v1') {
      await prefs.clear();
      await prefs.setString('data_version', '2026_v1');
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

  void _addOrEditStory({Story? story}) {
    final titleController = TextEditingController(text: story?.title ?? '');
    final dateController = TextEditingController(text: story?.date ?? '');
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
                decoration: const InputDecoration(labelText: '日付 (例: 2026/08/01)'),
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
                        content: contentController.text,
                      ),
                    );
                  } else {
                    story.title = titleController.text;
                    story.date = dateController.text;
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
      return story.title.contains(searchQuery) || story.content.contains(searchQuery);
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
                onChanged: (value) {
                  setState(() {
                    isAdminMode = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
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
