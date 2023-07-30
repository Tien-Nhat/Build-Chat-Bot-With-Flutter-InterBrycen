import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

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

  String? _getLanguage() {
    RegExp regExp = RegExp(r"```(\w+)");
    Match? match = regExp.firstMatch(msg);
    String? languageName = match?.group(1);
    return languageName;
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
                    child: MarkdownBlock(
                  data: msg,
                  config: MarkdownConfig(configs: [
                    const CodeConfig(
                      style: TextStyle(backgroundColor: Color(0xFF444654)),
                    ),
                    const PConfig(
                        textStyle: TextStyle(
                      // backgroundColor: Color(0xFF343541),
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    )),
                    PreConfig(
                      styleNotMatched: const TextStyle(color: Colors.white),
                      language: _getLanguage() ?? "",
                      theme: atomOneDarkTheme,
                      textStyle: GoogleFonts.sourceCodePro()
                          .copyWith(fontSize: 15, fontWeight: FontWeight.w500),
                      decoration: BoxDecoration(
                        image: (_getLanguage() != null)
                            ? DecorationImage(
                                image: AssetImage(
                                    "assets/images/${_getLanguage()}.png"))
                            : null,
                        color: const Color(0xFF444654),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ]),
                )),
                if (chatIndext == 1)
                  IconButton(
                    padding: EdgeInsets.zero,
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
