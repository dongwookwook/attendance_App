import 'dart:io';
import 'dart:math' hide log;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:db_package/db_package.dart';
import 'package:nfc_package/nfc_package.dart';
import 'dart:developer';

bool isUidMatched = false;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Login App',
      home: LoginPage(),
    );
  }
}

class NfcScreen extends StatefulWidget {
  const NfcScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NfcScreenState createState() => _NfcScreenState();
}

class _NfcScreenState extends State<NfcScreen> {
  final NfcPackage nfcPackage = NfcPackage();
  bool isUidMatched = false;

  @override
  void initState() {
    super.initState();
    _startNfcSession();
  }

  Future<bool> _startNfcSession() async {
  try {
    bool isresult = await nfcPackage.startNfcSession();
    if (isresult) {
      setState(() {
        isUidMatched = true; // UID 일치 확인
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          content: Text('UID 불일치'),
        ),
      );
    }
  } catch (e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text('오류 발생: $e'),
      ),
    );
  }
  return isUidMatched;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NFC CHECKING')),
      body: Center(
        child:
            Text(isUidMatched ? 'UID가 일치합니다.' : 'NFC 스캔을 위해 기기를 태그에 가까이 대주세요.'),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController studentIDController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final DBPackage _dbPackage = DBPackage();
  final List<Map<String, dynamic>> _dataList = [];
  late final Map<String, String> testCredentials;

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그인 결과'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchStudentData(String studentId) async {
    try {
      await _dbPackage.connect();
      Map<String, dynamic>? data =
          await _dbPackage.getDataByStudentId(studentId);
      if (data != null) {
        setState(() {
          _dataList.add(data); //TODO: 데이터 리스트 추가 부분, 변경 가능, 활용법 모색
        });
      }
      await _dbPackage.close();
    } catch (e) {
      log('e');
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BU NFC check-in'),
        backgroundColor: Colors.blue[700],
      ),
      body: Stack(
        children: <Widget>[
          // 배경 이미지
          Positioned.fill(
            child: Opacity(
              opacity: 0.25, // 투명도 조절 (0.0: 완전 투명, 1.0: 완전 불투명)
              child: Image.asset(
                'assets/bucam.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 로그인 UI
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ClipOval(
                  child: Image.asset(
                    'assets/bu.jpg',
                    width: 150,
                    height: 150,
                  ),
                ),
                // 입력 칸 등 로그인 UI
                const SizedBox(height: 20.0),
                TextField(
                  controller: studentIDController,
                  decoration: const InputDecoration(
                    labelText: '학번',
                  ),
                ),
                const SizedBox(height: 20.0),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                  ),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () async {
                    String studentID = studentIDController.text;
                    String password = passwordController.text;

                    for (final entry in testCredentials.entries) {
                      if (entry.key == studentID && entry.value == password) {
                        await fetchStudentData(studentID); // DB 호출 예시
                        Navigator.pushReplacement(
                          context, // FIXME: 사용되지 않은 매개변수
                          MaterialPageRoute(
                              builder: (context) => MainPage(
                                  studentID: studentID, dataList: _dataList)),
                        );
                        return;
                      }
                    }

                    _showMessage('학번 또는 비밀번호가 올바르지 않습니다.');
                  },
                  child: const Text('로그인'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  //BUG: 연결 과정 누락
  final String studentID;
  final List<Map<String, dynamic>> dataList;

  MainPage(
      {super.key, required this.studentID, required List<Map<String, dynamic>> dataList});

  @override
  MainPage({super.key, required this.studentID, required this.dataList});
}

class _MainPageState extends State<MainPage> //FIXME: 버그 파트
    with
        SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _currentTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _updateTime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BU NFC Check-in'),
        backgroundColor: Colors.blue[700],
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '메인 화면'),
            Tab(text: '학교 게시판'),
            Tab(text: '마이 페이지'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if isUidMatched = true{ (Icon(Icons.account_circle, size: 150, Colors.blue[700]))}, 
                //FIXME: return부 연결
                Text(
                  '${widget.studentID} ${getStudentName()}님 안녕하세요!', //BUG: 연결부 오류
                  style: const TextStyle(fontSize: 20),
                ),
                const Text(
                  '좌석번호: E 137', //FIXME: 좌석 테이블 student: 4, seat_id
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 20),
                Text(
                  '현재 시간: $_currentTime', //FIXME: attendence_record 3, attence_time date_time
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
          ),
          const SchoolNoticePage(),
          MyPage(studentID: widget.studentID),
        ],
      ),
    );
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    });
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class SchoolNoticePage extends StatelessWidget {
  const SchoolNoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WebView(
      initialUrl: 'https://www.bu.ac.kr/web/index.do',
      javascriptMode: JavascriptMode.unrestricted,
    );
  }
}

class MyPage extends StatefulWidget {
  final String studentID;

  const MyPage({super.key, required this.studentID});

  @override
  // ignore: library_private_types_in_public_api
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  File? _profileImage;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final List<bool> _attendance =
      List.generate(3, (index) => Random().nextBool());
  final List<String> _attendanceTimes =
      List.generate(3, (index) => _generateRandomTime(10, 50, 11));

  @override
  void initState() {
    super.initState();
    _nameController.text = getStudentName(widget.studentID);
    _emailController.text = '${widget.studentID}@bu.ac.kr';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : const AssetImage('assets/default_profile.png')
                      as ImageProvider,
              child: _profileImage == null
                  ? const Icon(Icons.account_circle, size: 50)
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: '이름'),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: '이메일'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('정보 수정'),
                    content: Text(
                        '이름: ${_nameController.text}\n이메일: ${_emailController.text}'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('확인'),
                      ),
                    ],
                  );
                },
              );
            },
            child: const Text('정보 수정'),
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            itemCount: 3,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('출석 여부: ${_attendance[index] ? '출석' : '미출석'}'),//FIXME: attendance_status 
                subtitle: Text('출석 시간: ${_attendanceTimes[index]}'),
              );
            },
          ),
        ],
      ),
    );
  }

  static String _generateRandomTime(int minHour, int minMinute, int maxHour) {
    final hour = minHour + Random().nextInt(maxHour - minHour);
    final minute = minMinute + Random().nextInt(60 - minMinute);
    return '$hour:${minute.toString().padLeft(2, '0')}';
  }
}


// total:
//   fix: 17, 
//   Bug: 2