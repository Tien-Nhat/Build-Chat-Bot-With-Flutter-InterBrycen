import 'package:flutter/rendering.dart';
import 'package:gptbrycen/widget/chat_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// ignore: camel_case_types
class summarize extends StatefulWidget {
  const summarize({super.key});

  @override
  State<summarize> createState() => _summarize();
}

// ignore: camel_case_types
class _summarize extends State<summarize> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isTyping = false;
  String _checkconnect = "true";
  // ignore: prefer_typing_uninitialized_variables
  late final retrievalQA;

  late TextEditingController textEditingController;

  final ScrollController _controller = ScrollController();

// This is what you're looking for!
  void _scrollDown() {
    _controller.animateTo(
      _controller.position.minScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void initState() {
    textEditingController = TextEditingController();
    super.initState();
    _speech = stt.SpeechToText();
    _controller.addListener(() {
      if (_controller.position.atEdge) {
        bool isTop = _controller.position.pixels == 0;

        if (isTop) {
          setState(
            () {
              _checkconnect = "false";
            },
          );
          index = 1;
        }
      }
    });
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

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
            listenFor: const Duration(days: 1),
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

  void _submitMessage() async {
    _isTyping = true;
    var collection = FirebaseFirestore.instance.collection('memory');
    var docSnapshot = await collection.doc('test1').get();
    Map<String, dynamic> data = docSnapshot.data()!;
    _checkconnect = data["CheckConnect"];

    final enteredMessage = textEditingController.text;
    if (enteredMessage.trim().isEmpty) {
      return;
    }
    if (_isListening) {
      setState(() {
        _isListening = false;
        _speech.stop();
      });
    }

    // ignore: use_build_context_synchronously
    FocusScope.of(context).unfocus();

    textEditingController.clear();

    FirebaseFirestore.instance.collection("chatSummarize").add({
      "text": enteredMessage,
      "createdAt": Timestamp.now(),
      "Indext": 0,
    });
    try {
      final res = await retrievalQA(enteredMessage);
      FirebaseFirestore.instance
          .collection("memory")
          .doc("test1")
          .update({"Document": res.toString()});
      FirebaseFirestore.instance.collection("chatSummarize").add({
        "text": res["result"].toString(),
        "createdAt": Timestamp.now(),
        "Indext": 1,
      });

      _isTyping = false;
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
          "text": "Câu hỏi của bạn không có trong tài liệu",
          "createdAt": Timestamp.now(),
          "Indext": 1,
        });
      }

      _isTyping = false;
    }
  }

  int index = 1;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("chatSummarize")
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
          floatingActionButton: (index == 0)
              ? FloatingActionButton.small(
                  onPressed: _scrollDown,
                  child: const Icon(Icons.arrow_downward),
                )
              : null,
          body: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              // Kiểm tra nếu người dùng đang cuộn ListView
              if (scrollInfo is ScrollUpdateNotification) {
                if (_controller.position.pixels > 0 && index == 1) {
                  setState(() {
                    _checkconnect = "false";
                  });

                  index = 0;
                }
              }
              return true; // Trả về true để bỏ qua các thông báo khác liên quan đến cuộn
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                (loadedMessages.isEmpty)
                    ? Expanded(
                        child: Center(
                          child: ElevatedButton.icon(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  const Color(0xFF343541)),
                              side: MaterialStateProperty.all<BorderSide>(
                                const BorderSide(
                                  color: Color(0xFF444654),
                                  width: 2.0,
                                ),
                              ),
                              minimumSize: MaterialStateProperty.all<Size>(
                                const Size(
                                  400,
                                  80,
                                ),
                              ),
                            ),
                            icon: const Icon(
                              Icons.cloud_upload,
                              size: 40,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Chọn File",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 30),
                            ),
                            onPressed: () async {
                              final result = await FilePicker.platform
                                  .pickFiles(withData: true);
                              var collection = FirebaseFirestore.instance
                                  .collection('memory');
                              var docSnapshot =
                                  await collection.doc('test1').get();
                              Map<String, dynamic> data = docSnapshot.data()!;
                              if (result == null) return;
                              PlatformFile file = result.files.first;
                              TextLoader loader = TextLoader(file.path!);
                              final documents = await loader.load();
                              const textSplitter = CharacterTextSplitter(
                                chunkSize: 800,
                                chunkOverlap: 0,
                              );
                              final texts =
                                  textSplitter.splitDocuments(documents);
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
                              final embeddings =
                                  OpenAIEmbeddings(apiKey: data["APIKey"]);
                              final docSearch =
                                  await MemoryVectorStore.fromDocuments(
                                documents: textsWithSources,
                                embeddings: embeddings,
                              );

                              final llm = ChatOpenAI(
                                apiKey: data["APIKey"],
                                model: 'gpt-3.5-turbo-0613',
                                temperature: 0.7,
                              );

                              final qaChain =
                                  OpenAIQAWithSourcesChain(llm: llm);
                              final docPrompt = PromptTemplate.fromTemplate(
                                'content: {page_content}\nSource: {source}',
                              );
                              final finalQAChain = StuffDocumentsChain(
                                llmChain: qaChain,
                                documentPrompt: docPrompt,
                              );
                              retrievalQA = RetrievalQAChain(
                                retriever: docSearch.asRetriever(),
                                combineDocumentsChain: finalQAChain,
                              );
                            },
                          ),
                        ),
                      )
                    : Flexible(
                        child: ListView.builder(
                          controller: _controller,
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
                  height: 5,
                ),
              ],
            ),
          ),
          bottomNavigationBar: searchInput(),
        );
      },
    );
  }

  Widget searchInput() {
    return Container(
      color: Color(0xFF444654),
      child: Padding(
        padding: const EdgeInsets.all(1.0),
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
                    hintText: "Nhập tin nhắn...",
                    hintStyle: TextStyle(color: Colors.grey)),
              ),
            ),
            IconButton(
                onPressed: () => onListen(),
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_off,
                  color: _isListening ? Colors.lightBlue : Colors.white,
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
    );
  }
}
