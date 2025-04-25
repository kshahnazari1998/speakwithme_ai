import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 22, 124, 220)),
        useMaterial3: true,
      ),
      home: FirebaseAuth.instance.currentUser == null
          ? const MyHomePage()
          : UserScreen(),
      routes: {
        // When navigating to the "/second" route, build the SecondScreen widget.
        '/homepage': (context) => const MyHomePage(),
        '/loginpage': (context) => const LoginPage(),
        '/userscreen': (context) => UserScreen()
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(
              'assets/app_logo.jpg',
              fit: BoxFit.contain,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(
                  20.0), // You can adjust this value as per your requirements.
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                child: Text('Get Started'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      providers: [
        EmailAuthProvider(),
      ],
      actions: [
        AuthStateChangeAction<SignedIn>((context, state) {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => UserScreen()),
              (Route<dynamic> route) => false);
          print(FirebaseAuth.instance.currentUser);
        }),
        AuthStateChangeAction<UserCreated>((context, state) {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => UserScreen()),
              (Route<dynamic> route) => false);
          print(FirebaseAuth.instance.currentUser);
        }),
      ],
    );
  }
}

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Widget> messages = [];
  SpeechToText _speechToText = SpeechToText();
  FlutterTts flutterTts = FlutterTts();
  bool _speechEnabled = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  void _initTts() async {
    flutterTts.setStartHandler(() {
      setState(() {
        // Handle when TTS starts playing
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        // Handle when TTS completes
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        // Handle TTS error
      });
    });

    // You can add more handlers as required, as shown in the example above.
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize();
      setState(() {});
    } catch (e) {
      print("An error occurred: $e");
      // Handle the error or show a message.
    }
  }

  void _startListening() async {
    await _speechToText.listen(
        onResult: _onSpeechResult,
        partialResults: false,
        pauseFor: Duration(seconds: 10),
        listenFor: Duration(seconds: 30));
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      // Adding user's spoken message to the chat messages list
      messages.add(
        BubbleNormal(
          text: _lastWords,
          isSender: true,
          color: Color(0xFFE8E8EE),
          tail: true,
          sent: true,
        ),
      );
      // Responding with "Hello" from the app
      messages.add(
        BubbleNormal(
          text: 'Hello',
          isSender: false,
          color: Color(0xFF1B97F3),
          tail: true,
        ),
      );
      _speak("Bye Bye");
    });
  }

  Future<void> _speak(String message) async {
    await flutterTts.speak(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Speakwithme.AI'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () async {
              await _auth.signOut();
              Navigator.of(context).pushReplacementNamed('/');
            },
            icon: Icon(Icons.logout,
                color: const Color.fromARGB(255, 23, 19, 19)),
            label: Text('Sign Out',
                style: TextStyle(color: const Color.fromARGB(255, 64, 49, 49))),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: ListView.builder(
                itemCount: messages.length,
                reverse: true,
                itemBuilder: (context, index) =>
                    messages[messages.length - 1 - index],
              ),
            ),
          ),
          if (_speechToText.isListening)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Listening...',
                  style:
                      TextStyle(fontSize: 20.0, fontStyle: FontStyle.italic)),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onPanDown: (details) => _startListening(),
              onPanEnd: (details) => _stopListening(),
              child: FloatingActionButton(
                onPressed:
                    null, // We are handling the tap with the GestureDetector.
                tooltip: 'Listen',
                child: Icon(
                    _speechToText.isNotListening ? Icons.mic_off : Icons.mic),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: GestureDetector(
        onPanDown: (details) => _startListening(),
        onPanEnd: (details) => _stopListening(),
        child: FloatingActionButton(
          onPressed: null, // Handling the tap with the GestureDetector.
          tooltip: 'Listen',
          child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
