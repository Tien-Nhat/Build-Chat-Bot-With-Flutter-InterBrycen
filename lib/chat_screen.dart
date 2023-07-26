import 'package:gptbrycen/widget/chat_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:dart_openai/dart_openai.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;

  bool _isTyping = false;
  String _checkconnect = "true";
  String? ResultSPeech;
  void onListen() async {
    var collection = FirebaseFirestore.instance.collection('memory');
    var docSnapshot = await collection.doc('test1').get();
    Map<String, dynamic> data = docSnapshot.data()!;
    _checkconnect = data["CheckConnect"];
    if (!_isListening) {
      bool available = await _speech.initialize(
          onStatus: (val) {
            print("OnStatus: $val");
            if (val == "done") {
              setState(() {
                _isListening = false;
                _speech.stop();
              });
            }
          },
          onError: (val) => print("error: $val"));
      if (available) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(
            localeId: "vi_VN",
            listenFor: Duration(days: 1),
            onResult: (val) => setState(() {
                  textEditingController.text = val.recognizedWords;
                  if (_isTyping == true) {
                    textEditingController.clear();
                  }
                }));
      }
    } else {
      setState(() {
        _isListening = false;
        _speech.stop();
      });
    }
  }

  late TextEditingController textEditingController;

  @override
  void initState() {
    textEditingController = TextEditingController();
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  void _submitMessage() async {
    if (textEditingController.text.trim().isEmpty) {
      return;
    }
    final enteredMessage = textEditingController.text;
    if (_isListening) {
      setState(() {
        _isListening = false;
        _speech.stop();
      });
    }
    _isTyping = true;
    var collection = FirebaseFirestore.instance.collection('memory');
    var docSnapshot = await collection.doc('test1').get();
    Map<String, dynamic> data = docSnapshot.data()!;
    _checkconnect = data["CheckConnect"];
    OpenAI.apiKey = data["APIKey"];

    FocusScope.of(context).unfocus();

    textEditingController.clear();
    FirebaseFirestore.instance.collection("chat").add({
      "text": enteredMessage,
      "createdAt": Timestamp.now(),
      "Indext": 0,
    });

    OpenAIChatCompletionModel chatCompletion =
        await OpenAI.instance.chat.create(
      model: "gpt-3.5-turbo",
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: enteredMessage,
          role: OpenAIChatMessageRole.user,
        ),
      ],
    );
    _isTyping = false;
    FirebaseFirestore.instance.collection("chat").add({
      "text": chatCompletion.choices[0].message.content,
      "createdAt": Timestamp.now(),
      "Indext": 1,
    });

    FirebaseFirestore.instance.collection("memory").doc("test1").update({
      "History": data["History"] +
          "\nHuman:" +
          enteredMessage +
          "\nAI:" +
          chatCompletion.choices[0].message.content,
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("chat")
          .orderBy(
            "createdAt",
            descending: true,
          )
          .snapshots(),
      builder: (ctx, chatSnapshots) {
        if (chatSnapshots.connectionState == ConnectionState.waiting &&
            _checkconnect == "true") {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        final loadedMessages = chatSnapshots.data!.docs;
        return Scaffold(
          appBar: AppBar(
            elevation: 2,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset("assets/images/chatgpt-logo.png"),
            ),
            title: const Text(
              "Chat GPT",
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                  ))
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Flexible(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: loadedMessages.length,
                    itemBuilder: (context, index) {
                      final chatMessage = loadedMessages[index].data();
                      return ChatWidget(
                        msg: chatMessage["text"],
                        chatIndext: chatMessage["Indext"],
                      );
                    },
                  ),
                ),
                if (_isTyping) ...[
                  const SpinKitThreeBounce(
                    color: Colors.white,
                    size: 18,
                  ),
                ],
                const SizedBox(
                  height: 15,
                ),
                Material(
                  color: Color(0xFF444654),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            controller: textEditingController,
                            onSubmitted: (value) {
                              _submitMessage();
                            },
                            maxLines: null,
                            decoration: const InputDecoration.collapsed(
                                hintText: "Nhập text ở đây",
                                hintStyle: TextStyle(color: Colors.grey)),
                          ),
                        ),
                        IconButton(
                            onPressed: () => onListen(),
                            icon: Icon(
                              _isListening ? Icons.mic : Icons.mic_off,
                              color: _isListening
                                  ? Colors.lightBlue
                                  : Colors.white,
                            )),
                        IconButton(
                            onPressed: _submitMessage,
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                            ))
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
