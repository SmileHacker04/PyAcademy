import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: AuthScreen());
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;

  Future<void> _authenticate() async {
    setState(() => isLoading = true);
    try {
      if (isLogin) {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (userCredential.user?.email == "admin@gmail.com") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminScreen()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UserScreen()),
          );
        }
      } else {
        if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
          _showSnackbar("Құпия сөздер сәйкес келмейді!");
          return;
        }

        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'fullname': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'dob': _dobController.text.trim(),
          'level': 1,
          'medals': [],
          'role': 'user',
        });

        _showSnackbar("Тіркелу сәтті аяқталды! Енді кіріңіз.");
        setState(() => isLogin = true);
      }
    } catch (e) {
      _showSnackbar(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserScreen()),
      );
    } catch (e) {
      _showSnackbar(e.toString());
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 80, color: Colors.deepPurple),
                  SizedBox(height: 10),
                  Text(
                    isLogin ? 'Қош келдіңіз!' : 'Тіркелу',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 10),
                  if (!isLogin) _buildTextField(_nameController, 'Аты-жөні', Icons.person),
                  _buildTextField(_emailController, 'Email', Icons.email),
                  _buildTextField(_passwordController, 'Құпия сөз', Icons.lock, obscureText: true),
                  if (!isLogin) _buildTextField(_confirmPasswordController, 'Құпия сөзді растау', Icons.lock, obscureText: true),
                  if (!isLogin) _buildTextField(_dobController, 'Туған күні', Icons.calendar_today),
                  SizedBox(height: 20),
                  isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _authenticate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                          ),
                          child: Text(isLogin ? 'Кіру' : 'Тіркелу', style: TextStyle(fontSize: 18), selectionColor: Colors.red,),
                        ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setState(() => isLogin = !isLogin),
                    child: Text(isLogin ? 'Тіркелу' : 'Бұрыннан бар аккаунтпен кіру'),
                  ),
                  Divider(height: 20, thickness: 1),
                  ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: Icon(Icons.login),
                    label: Text('Google арқылы кіру'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool obscureText = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white
        ),
      ),
    );
  }
}

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _addCourse() async {
    if (_titleController.text.isNotEmpty && _videoUrlController.text.isNotEmpty) {
      await _firestore.collection('courses').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'videoUrl': _videoUrlController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      _titleController.clear();
      _descriptionController.clear();
      _videoUrlController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Курс қосылды!')));
    }
  }

  void _deleteCourse(String docId) async {
    await _firestore.collection('courses').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Курс жойылды!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Курстарды басқару'), backgroundColor: Colors.deepPurple,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text(
                'Мәзір',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            _buildMenuItem(
              context,
              'Курстарды басқару',
              Icons.book,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminScreen()),
              ),
            ),
            _buildMenuItem(
              context,
              'Тапсырма',
              Icons.code,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InteractiveTasksScreen(),
                ),
              ),
            ),
            _buildMenuItem(
              context,
              'Пайдаланушыларды басқару',
              Icons.emoji_events,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminUserManagementScreen()),
              ),
            ),
            _buildMenuItem(
              context,
              'Чат',
              Icons.chat,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ForumChatScreen()),
              ),
            ),
            _buildMenuItem(
              context,
              'Статистика',
              Icons.bar_chart,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StatisticsScreen()),
              ),
            ),
            _buildMenuItem(
              context,
              'Шығу',
              Icons.output,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AuthScreen()),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Курс атауы'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Сипаттама'),
            ),
            TextField(
              controller: _videoUrlController,
              decoration: InputDecoration(labelText: 'YouTube видео сілтемесі'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addCourse,
              child: Text('Курс қосу'),
            ),
            Expanded(
              child: StreamBuilder(
                stream: _firestore.collection('courses').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['title'] ?? 'Атауы жоқ'),
                        subtitle: Text(data['videoUrl'] ?? ''),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCourse(doc.id),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }
}

class StatisticsScreen extends StatefulWidget {
  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int userCount = 0;
  int taskCount = 0;
  int answerCount = 0;
  Map<String, int> userProgress = {};

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    int users = (await _firestore.collection('users').get()).docs.length;
    if (users < 0) users = 0; 
    int tasks = (await _firestore.collection('tasks').get()).docs.length;

    int answers =
        (await _firestore.collection('task_answers').get()).docs.length;

    Map<String, int> progress = {};
    var answersDocs = await _firestore.collection('task_answers').get();
    for (var doc in answersDocs.docs) {
      String email = doc['userEmail'];
      progress[email] = (progress[email] ?? 0) + 1;
    }

    setState(() {
      userCount = users;
      taskCount = tasks;
      answerCount = answers;
      userProgress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Статистика'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📊 Жалпы статистика",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text("👥 Қолданушылар саны: ${userCount}"),
            Text("📌 Тапсырмалар саны: $taskCount"),
            Text("✉️ Жіберілген жауаптар саны: $answerCount"),
            SizedBox(height: 20),
            Text(
              "📈 Пайдаланушылардың прогресі:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child:
                  userProgress.isEmpty
                      ? Center(child: Text("Әзірге ешқандай жауап жоқ"))
                      : ListView.builder(
                        itemCount: userProgress.length,
                        itemBuilder: (context, index) {
                          String email = userProgress.keys.elementAt(index);
                          int progress = userProgress[email]!;
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 5),
                            child: ListTile(
                              title: Text(email),
                              subtitle: Text("Жауаптар: $progress"),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  _AdminUserManagementScreenState createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _updateUserLevel(String userId, int newLevel) {
    _firestore.collection('users').doc(userId).update({'level': newLevel});
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Деңгей жаңартылды!")));
  }

  void _addMedal(String userId, String medal) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    List<String> medals = List<String>.from(userDoc['medals'] ?? []);

    if (!medals.contains(medal)) {
      medals.add(medal);
      await _firestore.collection('users').doc(userId).update({'medals': medals});
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Медаль қосылды!")));
    }
  }

  void _removeUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Пайдаланушы жойылды!")));
  }

  Widget _buildMedal(String title, IconData icon, bool achieved) {
    return Chip(
      avatar: Icon(icon, color: achieved ? Colors.amber : Colors.grey),
      label: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: achieved ? Colors.black : Colors.grey,
        ),
      ),
      backgroundColor: achieved ? Colors.amber[200] : Colors.grey[300],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Пайдаланушыларды басқару"), backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              String userId = user.id;
              String name = user['fullname'] ?? "Аты белгісіз";
              int level = user['level'] ?? 1;
              List<String> medals = List<String>.from(user['medals'] ?? []);

              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Деңгей: $level"),
                      SizedBox(height: 5),
                      Text("Марапаттар:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 5,
                        children: [
                          _buildMedal("🥇 Алтын медаль", Icons.emoji_events, medals.contains("gold_medal")),
                          _buildMedal("🥈 Күміс медаль", Icons.emoji_events, medals.contains("silver_medal")),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    onSelected: (value) {
                      if (value == 'increase_level') {
                        _updateUserLevel(userId, level + 1);
                      } else if (value == 'add_gold') {
                        _addMedal(userId, 'gold_medal');
                      } else if (value == 'add_silver') {
                        _addMedal(userId, 'silver_medal');
                      } else if (value == 'delete') {
                        _removeUser(userId);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'increase_level',
                        child: Text("Деңгейді жоғарылату"),
                      ),
                      PopupMenuItem(
                        value: 'add_gold',
                        child: Text("Алтын медаль беру"),
                      ),
                      PopupMenuItem(
                        value: 'add_silver',
                        child: Text("Күміс медаль беру"),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text("Пайдаланушыны жою"),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Python курстары'),
        backgroundColor: Colors.deepPurple,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text(
                'Мәзір',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            _buildMenuItem(
              context,
              'Python курстары',
              Icons.book,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserScreen()),
              ),
            ),
            _buildMenuItem(
              context,
              'Интерактивті тапсырмалар',
              Icons.code,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InteractiveTasksScreen(),
                ),
              ),
            ),
            _buildMenuItem(
              context,
              'Жетістіктер жүйесі',
              Icons.emoji_events,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AchievementsScreen()),
              ),
            ),
            _buildMenuItem(
              context,
              'Чат',
              Icons.chat,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ForumChatScreen()),
              ),
            ),
            _buildMenuItem(
              context,
              'Профиль',
              Icons.person_outline,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserProfileScreen()),
              ),
            ),
            _buildMenuItem(
              context,
              'Шығу',
              Icons.output,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AuthScreen()),
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('courses').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var courses = snapshot.data!.docs;
          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              var course = courses[index];
              return _buildCourseCard(
                course['title'],
                course['description'],
                course['videoUrl'],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }


  Widget _buildCourseCard(String title, String description, String videoUrl) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.play_arrow, color: Colors.red),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoScreen(videoUrl: videoUrl),
            ),
          );
        },
      ),
    );
  }
}

class VideoScreen extends StatefulWidget {
  final String videoUrl;

  const VideoScreen({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    String? videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? "",
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
        ),
      ),
    );
  }
}

class InteractiveTasksScreen extends StatefulWidget {
  @override
  _InteractiveTasksScreenState createState() => _InteractiveTasksScreenState();
}

class _InteractiveTasksScreenState extends State<InteractiveTasksScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  Future<void> _addTask() async {
    if (_taskController.text.isNotEmpty) {
      await _firestore.collection('tasks').add({
        'task': _taskController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      _taskController.clear();
    }
  }

  Future<void> _submitAnswer(String taskId) async {
    if (_answerController.text.trim().isEmpty) return;

    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('task_answers').add({
        'taskId': taskId,
        'answer': _answerController.text.trim(),
        'userId': user.uid,
        'userEmail': user.email ?? "Белгісіз пайдаланушы",
        'timestamp': FieldValue.serverTimestamp(),
      });
      _answerController.clear();
      Navigator.pop(context);
    }
  }

  void _showAnswerDialog(String taskId) {
    _answerController.clear();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Тапсырмаға жауап беру"),
            content: TextField(
              controller: _answerController,
              decoration: InputDecoration(hintText: "Жауабыңызды енгізіңіз..."),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Болдырмау"),
              ),
              ElevatedButton(
                onPressed: () => _submitAnswer(taskId),
                child: Text("Жіберу"),
              ),
            ],
          ),
    );
  }

  void _showAdminAnswersDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Пайдаланушы жауаптары"),
            content: StreamBuilder(
              stream:
                  _firestore
                      .collection('task_answers')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var answers = snapshot.data!.docs;
                if (answers.isEmpty) {
                  return Text("Әзірге ешқандай жауап жоқ.");
                }
                return Container(
                  width: double.maxFinite,
                  height: 300,
                  child: ListView.builder(
                    itemCount: answers.length,
                    itemBuilder: (context, index) {
                      var answer = answers[index];
                      return ListTile(
                        title: Text(
                          answer['answer'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Пайдаланушы: ${answer['userEmail']}"),
                      );
                    },
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Жабу"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    bool isAdmin = user?.email == 'admin@gmail.com';

    return Scaffold(
      appBar: AppBar(
        title: Text('Интерактивті тапсырмалар'),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (isAdmin)
            IconButton(
              icon: Icon(Icons.list),
              onPressed: _showAdminAnswersDialog,
              tooltip: "Жауаптарды қарау",
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream:
                  _firestore
                      .collection('tasks')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var tasks = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index];
                    return Card(
                      elevation: 5,
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        title: Text(
                          task['task'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Тапсырманы орындаңыз'),
                        trailing: Icon(Icons.edit),
                        onTap: () => _showAnswerDialog(task.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taskController,
                      decoration: InputDecoration(
                        labelText: 'Жаңа тапсырма',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(onPressed: _addTask, child: Text('Қосу')),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  _AchievementsScreenState createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int userLevel = 1;
  List<String> awards = [];

  @override
  void initState() {
    super.initState();
    _loadUserAchievements();
  }

  Future<void> _loadUserAchievements() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      setState(() {
        userLevel = userDoc['level'];
        awards = List<String>.from(userDoc['medals']);
      });
    }
  }

  Widget _buildAwardCard(String title, IconData icon, bool earned) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: earned ? 4 : 1,
      color: earned ? Colors.deepPurpleAccent : Colors.grey[300],
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 50, color: earned ? Colors.white : Colors.black54),
            SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: earned ? Colors.white : Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Жетістіктер"), backgroundColor: Colors.deepPurple,
      ),
      backgroundColor: Colors.deepPurple[50],
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.star, color: Colors.amber, size: 40),
                title: Text(
                  "Деңгей: $userLevel",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 20),

            Text(
              "Медальдар мен Кубоктар:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildAwardCard("🥇 Алтын медаль", Icons.emoji_events, awards.contains("gold_medal")),
                  _buildAwardCard("🥈 Күміс медаль", Icons.emoji_events, awards.contains("silver_medal")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ForumChatScreen extends StatefulWidget {
  const ForumChatScreen({super.key});

  @override
  _ForumChatScreenState createState() => _ForumChatScreenState();
}

class _ForumChatScreenState extends State<ForumChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('forum_messages').add({
        'text': _messageController.text.trim(),
        'userId': user.uid,
        'userName': user.email == "admin@gmail.com" ? "Куратор" : (user.email ?? "Белгісіз пайдаланушы"),
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    }
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isMe = data['userId'] == _auth.currentUser?.uid;

    String _formatTimestamp(Timestamp? timestamp) {
      if (timestamp == null) return "Белгісіз уақыт"; // Если нет времени
      DateTime date = timestamp.toDate();
      return "${DateFormat('HH:mm, dd/MM/yyyy').format(date)}";
    }


    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              data['userName'] ?? "Куратор",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black, 
              ),
            ),
            SizedBox(height: 5),
            Text(
              data['text'],
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
            SizedBox(height: 5),
            Text(
              _formatTimestamp(data['timestamp']),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600], 
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Чат"), backgroundColor: Colors.deepPurple,),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('forum_messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                
                var messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) => _buildMessageItem(messages[index]),
                );
              },
            ),
          ),

          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Жазыңыз...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  User? _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_user!.uid).get();

      if (userDoc.exists) {
        setState(() {
          _nameController.text = userDoc['fullname'] ?? '';
          _dobController.text = userDoc['dob'] ?? '';
        });
      } else {
        await _firestore.collection('users').doc(_user!.uid).set({
          'fullname':
              _nameController.text.trim().isNotEmpty
                  ? _nameController.text.trim()
                  : _user!.displayName ?? '',
          'email': _user!.email,
          'dob': '',
          'level': 1,
          'medals': [],
          'role': 'user',
        });
      }
    }
  }

  Future<void> _saveUserData() async {
    if (_user != null) {
      await _firestore.collection('users').doc(_user!.uid).set({
        'fullname': _nameController.text.trim(),
        'dob': _dobController.text.trim(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ақпарат сақталды!")));
    }
  }

  void _resetPassword() async {
    if (_user != null && _user!.email != null) {
      await _auth.sendPasswordResetEmail(email: _user!.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Құпиясөзді өзгерту сілтемесі жіберілді!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Пайдаланушы профилі"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Аты-жөніңіз"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _dobController,
              decoration: InputDecoration(labelText: "Туған күніңіз"),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _saveUserData, child: Text("Сақтау")),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetPassword,
              child: Text("Құпиясөзді өзгерту"),
            ),
          ],
        ),
      ),
    );
  }
}