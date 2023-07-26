import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
// This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ), // ThemeData
      home: MyWidget(),
      debugShowCheckedModeBanner: false,
    ); // MaterialApp
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _textSpeech = "snhjasb";
  void onListen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
          onStatus: (val) => print("ónta$val"),
          onError: (val) => print("eror$val"));
      if (available) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(
            localeId: "vi_VN",
            listenFor: Duration(days: 1),
            onResult: (val) => setState(() {
                  _textSpeech = val.recognizedWords;
                }));
      }
    } else {
      setState(() {
        _isListening = false;
        _speech.stop();
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("sáuhdha"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AvatarGlow(
        glowColor: Colors.red,
        animate: _isListening,
        endRadius: 80,
        duration: Duration(milliseconds: 2000),
        repeatPauseDuration: Duration(milliseconds: 100),
        child: FloatingActionButton(
          onPressed: () => onListen(),
          child: Icon(_isListening ? Icons.mic : Icons.mic_off),
        ),
      ),
      body: SingleChildScrollView(
        reverse: true,
        child: Container(
          padding: EdgeInsets.fromLTRB(30, 30, 30, 150),
          child: Text(
            _textSpeech,
            style: TextStyle(
              fontSize: 32,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
