import 'package:gptbrycen/widget/text_widget.dart';
import 'package:flutter/material.dart';

class ChatWidget extends StatelessWidget {
  const ChatWidget({super.key, required this.msg, required this.chatIndext});
  final String msg;
  final int chatIndext;
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
                ))
              ],
            ),
          ),
        )
      ],
    );
  }
}
