import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:flutter_langdetect/flutter_langdetect.dart' as langdetect;
import 'package:collection/collection.dart';

late RetrievalQAChain retrievalQA;
bool _isSpeaking = false;
bool _checkEm = true;

// ignore: must_be_immutable
class ChatWidget extends StatelessWidget {
  ChatWidget({super.key, required this.msg, required this.chatIndext});
  final String msg;
  FlutterTts flutterTts = FlutterTts();
  final int chatIndext;
  Map<String, String> myMap = {
    'locale': 'vi-VN',
    'name': 'vi-vn-x-vic-network',
    // Thêm các cặp key-value khác tại đây
  };

  void _speak() async {
    _isSpeaking = !_isSpeaking;
    if (_isSpeaking) {
      await langdetect.initLangDetect();
      var language = langdetect.detect(msg);
      await flutterTts.setLanguage(language);
      if (language == "vi") await flutterTts.setVoice(myMap);
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

  List<String> extractQuestions(String text) {
    List<String> questions = [];
    RegExp regex = RegExp(r"\d+\. (.+)");
    Iterable<RegExpMatch> matches = regex.allMatches(text);

    for (RegExpMatch match in matches) {
      questions.add(match.group(1)!);
    }

    return questions;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        (chatIndext == 3)
            ? Container(
                color: const Color(0xFF343541),
                padding: const EdgeInsets.all(1.0),
                child: suggest(extractQuestions(msg)))
            : Material(
                color: chatIndext == 0
                    ? const Color(0xFF444654)
                    : const Color(0xFF343541),
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        if (chatIndext == 1) ...{
                          Container(
                            height: 30,
                            alignment: Alignment.bottomRight,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: _speak,
                              icon: const Icon(Icons.volume_up),
                              color: Colors.white,
                            ),
                          )
                        },
                        Row(
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
                                  style: TextStyle(
                                      backgroundColor: Color(0xFF444654)),
                                ),
                                const PConfig(
                                    textStyle: TextStyle(
                                  // backgroundColor: Color(0xFF343541),
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                )),
                                PreConfig(
                                  styleNotMatched:
                                      const TextStyle(color: Colors.white),
                                  language: _getLanguage() ?? "",
                                  theme: atomOneDarkTheme,
                                  textStyle: GoogleFonts.sourceCodePro()
                                      .copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500),
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
                          ],
                        ),
                      ],
                    )),
              ),
      ],
    );
  }

  Widget suggest(List<String> kq) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            sendembbeding(kq[0]);
          },
          style: ButtonStyle(
            backgroundColor:
                MaterialStateProperty.all<Color>(const Color(0xFF343541)),
            side: MaterialStateProperty.all<BorderSide>(
              const BorderSide(
                color: Color(0xFF444654),
                width: 2.0,
              ),
            ),
            minimumSize: MaterialStateProperty.all<Size>(
              const Size(
                150,
                30,
              ),
            ),
          ),
          label: Text(
            kq[0],
            style: const TextStyle(color: Colors.blue, fontSize: 15),
          ),
          icon: const Icon(
            Icons.send,
            size: 20,
            color: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            sendembbeding(kq[1]);
          },
          style: ButtonStyle(
            backgroundColor:
                MaterialStateProperty.all<Color>(const Color(0xFF343541)),
            side: MaterialStateProperty.all<BorderSide>(
              const BorderSide(
                color: Color(0xFF444654),
                width: 2.0,
              ),
            ),
            minimumSize: MaterialStateProperty.all<Size>(
              const Size(
                150,
                30,
              ),
            ),
          ),
          label: Text(
            kq[1],
            style: const TextStyle(color: Colors.blue, fontSize: 15),
          ),
          icon: const Icon(
            Icons.send,
            size: 20,
            color: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            sendembbeding(kq[2]);
          },
          style: ButtonStyle(
            backgroundColor:
                MaterialStateProperty.all<Color>(const Color(0xFF343541)),
            side: MaterialStateProperty.all<BorderSide>(
              const BorderSide(
                color: Color(0xFF444654),
                width: 2.0,
              ),
            ),
            minimumSize: MaterialStateProperty.all<Size>(
              const Size(
                150,
                30,
              ),
            ),
          ),
          label: Text(
            kq[2],
            style: const TextStyle(color: Colors.blue, fontSize: 15),
          ),
          icon: const Icon(
            Icons.send,
            size: 20,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  void sendembbeding(String kq1) async {
    try {
      if (_checkEm) {
        await FirebaseFirestore.instance
            .collection("memory")
            .doc("memory")
            .update({"_checkEmbbed": true});
        _checkEm = false;
      }
      var collection = FirebaseFirestore.instance.collection('memory');
      var docSnapshot = await collection.doc('memory').get();
      Map<String, dynamic> data = docSnapshot.data()!;
      FirebaseFirestore.instance.collection("chatSummarize").add({
        "text": kq1,
        "createdAt": Timestamp.now(),
        "Indext": 0,
      });

      if (data["_checkEmbbed"] || data["APIKey"] != data["OldAPIKey"]) {
        await FirebaseFirestore.instance
            .collection("memory")
            .doc("memory")
            .update({"OldAPIKey": data["APIKey"]});
        retrievalQA =
            await readFile(data["FilePath"], data["APIKey"], data["Content"]);
        await FirebaseFirestore.instance
            .collection("memory")
            .doc("memory")
            .update({"_checkEmbbed": false});
      }

      final res = await retrievalQA(kq1);

      FirebaseFirestore.instance.collection("chatSummarize").add({
        "text": res["result"].toString(),
        "createdAt": Timestamp.now(),
        "Indext": 1,
      });
    } catch (e) {
      if (e.toString().endsWith("statusCode: 429}")) {
        FirebaseFirestore.instance.collection("chatSummarize").add({
          "text":
              "Giới hạn câu hỏi 3 câu hỏi / 1 phút. Vui lòng thêm thanh toán hoặc đợi 20 giây.",
          "createdAt": Timestamp.now(),
          "Indext": 1,
        });
      } else {
        FirebaseFirestore.instance.collection("chatSummarize").add({
          "text": e.toString(),
          "createdAt": Timestamp.now(),
          "Indext": 1,
        });
      }
    }
  }

  Future<RetrievalQAChain> readFile(
    String Path,
    String API,
    String content,
  ) async {
    FirebaseFirestore.instance
        .collection("memory")
        .doc("memory")
        .update({"FilePath": Path});
    List<Document> documents = [];
    List<String> URLs = [];
    if (content.isNotEmpty) {
      documents.add(
          Document(pageContent: content, metadata: const {"source": "local"}));
    } else {
      URLs.clear();
      URLs.add(Path);

      WebBaseLoader loader = WebBaseLoader(URLs);
      documents = await loader.load();
    }

    const textSplitter = CharacterTextSplitter(
      chunkSize: 800,
      chunkOverlap: 0,
    );
    final texts = textSplitter.splitDocuments(documents);
    final textsWithSources = texts
        .mapIndexed(
          (final i, final d) => d.copyWith(
            metadata: {
              ...d.metadata,
              'source': '$i-pl',
            },
          ),
        )
        .toList(growable: false);
    final embeddings = OpenAIEmbeddings(apiKey: API);
    final docSearch = await MemoryVectorStore.fromDocuments(
      documents: textsWithSources,
      embeddings: embeddings,
    );

    final llm = ChatOpenAI(
      apiKey: API,
      model: 'gpt-3.5-turbo-16k',
      temperature: 0.7,
    );

    final qaChain = OpenAIQAWithSourcesChain(llm: llm);
    final docPrompt = PromptTemplate.fromTemplate(
      'content: {page_content}',
    );
    final finalQAChain = StuffDocumentsChain(
      llmChain: qaChain,
      documentPrompt: docPrompt,
    );

    return RetrievalQAChain(
      retriever: docSearch.asRetriever(),
      combineDocumentsChain: finalQAChain,
    );
  }
}
