import 'package:flutter_tts/flutter_tts.dart';
import 'package:gptbrycen/widget/text_widget.dart';
import 'package:flutter/material.dart';

class ChatWidget extends StatelessWidget {
  ChatWidget({super.key, required this.msg, required this.chatIndext});
  final String msg;
  FlutterTts flutterTts = FlutterTts();
  final int chatIndext;
  bool _isSpeaking = false;

  void _speak() async {
    _isSpeaking = !_isSpeaking;
    if (_isSpeaking) {
      await flutterTts.speak(msg);
    } else {
      flutterTts.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: chatIndext == 0 ? Color(0xFF444654) : Color(0xFF343541),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  chatIndext == 0
                      ? "assets/images/human.png"
                      : "assets/images/chatgpt-logo.png",
                  height: 30,
                  width: 30,
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                    child: TextWidget(
                  label: msg,
                )),
                if (chatIndext == 1)
                  IconButton(
                    onPressed: _speak,
                    icon:
                        Icon(_isSpeaking ? Icons.volume_mute : Icons.volume_up),
                    color: Colors.white,
                  )
              ],
            ),
          ),
        )
      ],
    );
  }
}
