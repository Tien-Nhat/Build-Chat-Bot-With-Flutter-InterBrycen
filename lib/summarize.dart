import 'dart:convert';
import 'dart:io';

// ignore: library_prefixes
import 'package:dart_openai/dart_openai.dart' as dartOpenAI;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:gptbrycen/widget/chat_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
// import 'package:url_launcher/url_launcher.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:mime/mime.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:syncfusion_flutter_pdf/pdf.dart';

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
  bool _checkconnect = true;
  bool _checkReload = true;
  List<String> kq = [];
  int? chatMessage;
  bool _isReadFile = true;

  // ignore: prefer_typing_uninitialized_variables
  late RetrievalQAChain retrievalQA;

  late TextEditingController textEditingController;
  late TextEditingController URLEditingController;

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
    URLEditingController = TextEditingController();
    super.initState();

    _speech = stt.SpeechToText();
    _controller.addListener(() {
      if (_controller.position.atEdge) {
        bool isTop = _controller.position.pixels == 0;
        if (isTop) {
          setState(
            () {
              _checkconnect = false;
            },
          );
          indexScroll = 1;
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
    var docSnapshot = await collection.doc('memory').get();
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

  String cutDialogue(String dialogue, {int maxLength = 2000}) {
    if (dialogue.length <= maxLength) {
      return dialogue;
    } else {
      // Tìm vị trí của ký tự xuống dòng gần nhất trước maxLength
      int lastNewlineIndex =
          dialogue.lastIndexOf("Human:", dialogue.length - maxLength);
      if (lastNewlineIndex == -1) {
        return dialogue.substring(0, maxLength);
      } else {
        // Cắt phần đầu chuỗi từ ký tự xuống dòng gần nhất
        return dialogue.substring(lastNewlineIndex - 1);
      }
    }
  }

  void _submitMessage() async {
    _isTyping = true;
    var collection = FirebaseFirestore.instance.collection('memory');
    var docSnapshot = await collection.doc('memory').get();
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
      if (_checkReload || data["APIKey"] != data["OldAPIKey"]) {
        await FirebaseFirestore.instance
            .collection("memory")
            .doc("memory")
            .update({"OldAPIKey": data["APIKey"]});
        RetrievalQAChain temp;
        temp =
            await readFile(data["FilePath"], data["APIKey"], data["Content"]);
        setState(() {
          retrievalQA = temp;
        });
        setState(() {
          _checkReload = false;
        });
      }

      final res = await retrievalQA(
          data["SummarizeHistory"] + "\nHuman: " + enteredMessage + "\nAI: ");
      await FirebaseFirestore.instance
          .collection("memory")
          .doc("memory")
          .update({
        "SummarizeHistory": cutDialogue(data["SummarizeHistory"]) +
            "\nHuman: " +
            enteredMessage +
            "\nAI: " +
            res["result"].toString()
      });
      FirebaseFirestore.instance
          .collection("memory")
          .doc("memory")
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
          "text": e.toString(),
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

      _isTyping = false;
    }
  }

  int indexScroll = 1;
  bool isLoading = false;
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
            _checkconnect == true) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        final loadedMessages = chatSnapshots.data!.docs;
        if (loadedMessages.isEmpty) {
          indexScroll = 1;
        }

        return Scaffold(
          floatingActionButton: (indexScroll == 0 && loadedMessages.isNotEmpty)
              ? FloatingActionButton.small(
                  onPressed: _scrollDown,
                  child: const Icon(Icons.arrow_downward),
                )
              : null,
          body: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              // Kiểm tra nếu người dùng đang cuộn ListView
              if (scrollInfo is ScrollUpdateNotification) {
                if (_controller.position.pixels > 0 && indexScroll == 1) {
                  setState(() {
                    _checkconnect = false;
                  });

                  indexScroll = 0;
                }
              }
              return true; // Trả về true để bỏ qua các thông báo khác liên quan đến cuộn
            },
            child: AbsorbPointer(
              absorbing: isLoading,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  (loadedMessages.isEmpty)
                      ? Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                            const Color(0xFF343541)),
                                    side: MaterialStateProperty.all<BorderSide>(
                                      const BorderSide(
                                        color: Color(0xFF444654),
                                        width: 2.0,
                                      ),
                                    ),
                                    minimumSize:
                                        MaterialStateProperty.all<Size>(
                                      const Size(
                                        400,
                                        80,
                                      ),
                                    ),
                                  ),
                                  icon: (_isReadFile)
                                      ? const Icon(
                                          Icons.cloud_upload,
                                          size: 40,
                                          color: Colors.white,
                                        )
                                      : const Icon(
                                          Icons.send,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                  label: (_isReadFile)
                                      ? const Text(
                                          "Chọn File",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 30),
                                        )
                                      : TextField(
                                          maxLines: null,
                                          controller: URLEditingController,
                                          style: const TextStyle(
                                              color: Colors.white),
                                          decoration: const InputDecoration
                                                  .collapsed(
                                              focusColor: Colors.white,
                                              hintText:
                                                  "Nhập URL các trang báo điện tử(vnexpress, cnn...)...",
                                              hintStyle: TextStyle(
                                                  color: Colors.grey)),
                                        ),
                                  onPressed:
                                      (_isReadFile) ? uploadFile : uploadURL,
                                ),
                                ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _checkconnect = false;
                                        _isReadFile = !_isReadFile;
                                      });
                                    },
                                    icon: const Icon(Icons.swap_horiz_rounded),
                                    label: (_isReadFile)
                                        ? const Text("Đổi sang URL")
                                        : const Text("Đổi sang upload File"))
                              ],
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
                  if (loadedMessages.isNotEmpty) ...[
                    if (_isTyping ||
                        loadedMessages[0].data()["Indext"] == 0) ...[
                      const SpinKitThreeBounce(
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ],
                  const SizedBox(
                    height: 5,
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: AbsorbPointer(
            absorbing: isLoading,
            child: searchInput(),
          ),
        );
      },
    );
  }

  Widget searchInput() {
    return Container(
      color: const Color(0xFF444654),
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

  String splitAndFormatString(String input) {
    List<String> sentences = input
        .split(RegExp(r'(?<=[.!?])')); // Tách chuỗi thành danh sách các câu

    List<String> lines = [];
    String currentLine = '';

    for (String sentence in sentences) {
      String updatedSentence = sentence.trim();

      if (currentLine.isEmpty) {
        currentLine = updatedSentence;
      } else if ((currentLine.length + 1 + updatedSentence.length) <= 1650) {
        currentLine += ' ' + updatedSentence;
      } else {
        lines.add(currentLine);
        currentLine = updatedSentence;
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines.join('\n\n'); // Trả về chuỗi kết quả đã cắt và xuống dòng
  }

  Future<void> uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null) {
        return;
      }
      EasyLoading.showProgress(0,
          maskType: EasyLoadingMaskType.black,
          status: '${(0 * 100).toStringAsFixed(0)}%');
      setState(() {
        isLoading = true;
      });

      PlatformFile file = result.files.first;

      final TypePath = lookupMimeType(file.path!);
      setState(() {
        _checkconnect = false;
        _checkReload = true;
      });
      var collection = FirebaseFirestore.instance.collection('memory');
      var docSnapshot = await collection.doc('memory').get();
      Map<String, dynamic> data = docSnapshot.data()!;
      dartOpenAI.OpenAI.apiKey = data["APIKey"];

      await FirebaseFirestore.instance
          .collection("memory")
          .doc("memory")
          .update({
        "Content": "",
        "_checkEmbbed": true,
        "OldAPIKey": data["APIKey"]
      });

      if (TypePath == ("text/plain")) {
        String convertedValue = utf8.decode(file.bytes!);
        await FirebaseFirestore.instance
            .collection("memory")
            .doc("memory")
            .update({"Content": splitAndFormatString(convertedValue)});
      }

      if (TypePath == "application/pdf") {
        final PdfDocument document =
            PdfDocument(inputBytes: File(file.path!).readAsBytesSync());
        String text = PdfTextExtractor(document).extractText();
        await FirebaseFirestore.instance
            .collection("memory")
            .doc("memory")
            .update({"Content": splitAndFormatString(text)});
      }

      if (TypePath == "audio/mpeg") {
        dartOpenAI.OpenAIAudioModel transcription =
            await dartOpenAI.OpenAI.instance.audio.createTranscription(
          file: File(file.path!),
          model: "whisper-1",
          responseFormat: dartOpenAI.OpenAIAudioResponseFormat.json,
        );
        await FirebaseFirestore.instance
            .collection("memory")
            .doc("memory")
            .update({"Content": splitAndFormatString(transcription.text)});
      }

      EasyLoading.showProgress(0.1,
          maskType: EasyLoadingMaskType.black,
          status: '${(0.1 * 100).toStringAsFixed(0)}%');

      var docSnapshot1 = await collection.doc('memory').get();
      Map<String, dynamic> data1 = docSnapshot1.data()!;

      EasyLoading.showProgress(0.3,
          maskType: EasyLoadingMaskType.black,
          status: '${(0.3 * 100).toStringAsFixed(0)}%');

      EasyLoading.showProgress(0.4,
          maskType: EasyLoadingMaskType.black,
          status: '${(0.4 * 100).toStringAsFixed(0)}%');

      final sug = await getSuggest(data1["Content"], data1["APIKey"], "");
      EasyLoading.showProgress(0.6,
          maskType: EasyLoadingMaskType.black,
          status: '${(0.6 * 100).toStringAsFixed(0)}%');

      print(sug);

      EasyLoading.showProgress(1,
          maskType: EasyLoadingMaskType.black,
          status: '${(1 * 100).toStringAsFixed(0)}%');

      FirebaseFirestore.instance.collection("chatSummarize").add({
        "text": sug,
        "createdAt": Timestamp.now(),
        "Indext": 3,
      });

      FirebaseFirestore.instance
          .collection("memory")
          .doc("memory")
          .update({"Document": sug});

      setState(() {
        isLoading = false;
      });

      EasyLoading.dismiss();
    } catch (e) {
      EasyLoading.showError(e.toString());
      print(e.toString());
      setState(() {
        isLoading = false;
      });
      EasyLoading.dismiss();
    }
  }

  Future<void> uploadURL() async {
    final enteredMessage = URLEditingController.text;
    if (enteredMessage.isEmpty) {
      return;
    }
    try {
      http.Response response = await http.get(Uri.parse(enteredMessage));
      if (response.statusCode != 200) {
        EasyLoading.showError(
            'Không thể truy cập URL, vui lòng kiểm tra lại URL');
        return;
      } else {
        await FirebaseFirestore.instance
            .collection("memory")
            .doc("memory")
            .update({"Content": ""});
      }
    } catch (e) {
      EasyLoading.showError("Định dạng URL không đúng vui lòng nhập lại!");
      return;
    }
    var collection = FirebaseFirestore.instance.collection('memory');
    var docSnapshot = await collection.doc('memory').get();
    Map<String, dynamic> data = docSnapshot.data()!;

    FirebaseFirestore.instance
        .collection("memory")
        .doc("memory")
        .update({"_checkEmbbed": true});
    FocusScope.of(context).unfocus();

    URLEditingController.clear();
    try {
      EasyLoading.showProgress(0.1,
          maskType: EasyLoadingMaskType.black,
          status: '${(0.1 * 100).toStringAsFixed(0)}%');
      setState(() {
        isLoading = true;
      });

      EasyLoading.showProgress(0.3,
          maskType: EasyLoadingMaskType.black,
          status: '${(0.3 * 100).toStringAsFixed(0)}%');
      setState(() {
        _checkconnect = false;
        _checkReload = true;
      });
      final sug =
          await getSuggest(data["Content"], data["APIKey"], enteredMessage);
      EasyLoading.showProgress(0.6,
          maskType: EasyLoadingMaskType.black,
          status: '${(0.6 * 100).toStringAsFixed(0)}%');
      print(sug);

      EasyLoading.showProgress(0.8,
          maskType: EasyLoadingMaskType.black,
          status: '${(0.8 * 100).toStringAsFixed(0)}%');
      FirebaseFirestore.instance.collection("chatSummarize").add({
        "text": sug,
        "createdAt": Timestamp.now(),
        "Indext": 3,
      });
      FirebaseFirestore.instance
          .collection("memory")
          .doc("memory")
          .update({"Document": sug.toString()});

      setState(() {
        isLoading = false;
      });
      EasyLoading.dismiss();
    } catch (e) {
      if (e.toString() == "[output_parser] No function message returned") {
        EasyLoading.showError(
            "Không thể tạo câu hỏi gợi ý, nhưng bạn vẫn có thể hỏi về nội dung file");
      } else {
        EasyLoading.showError(e.toString());
      }

      print(e.toString());
      setState(() {
        isLoading = false;
      });
      EasyLoading.dismiss();
    }
  }

  String template = '''
Khi tôi truy vấn: 'đưa ra 3 câu hỏi' \nVui lòng dựa vào đoạn văn bản sau đây: {page_content} \nSau đó, hiển thị 3 câu hỏi liên quan đến đoạn văn bản theo định dạng sau:
1.
2.
3.

''';

  Future<String> getSuggest(String content, String apiKey, String url) async {
    List<String> urls = [];
    List<Document> documents = [];
    if (url.isNotEmpty) {
      FirebaseFirestore.instance
          .collection("memory")
          .doc("memory")
          .update({"FilePath": url});
      urls.clear();
      urls.add(url);

      WebBaseLoader loader = WebBaseLoader(urls);
      documents = await loader.load();
    } else {
      documents.clear();
      documents.add(
          Document(pageContent: content, metadata: const {"source": "local"}));
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
    final embeddings = OpenAIEmbeddings(apiKey: apiKey);
    final docSearch = await MemoryVectorStore.fromDocuments(
      documents: textsWithSources,
      embeddings: embeddings,
    );

    final llm = ChatOpenAI(
      apiKey: apiKey,
      model: 'gpt-3.5-turbo-16k',
      maxTokens: 4000,
      temperature: 0.0,
    );

    final qaChain = OpenAIQAWithSourcesChain(llm: llm);
    final docPrompt = PromptTemplate.fromTemplate(
      template,
    );
    final finalQAChain = StuffDocumentsChain(
      llmChain: qaChain,
      documentPrompt: docPrompt,
    );
    RetrievalQAChain ketrievalQA = RetrievalQAChain(
      retriever: docSearch.asRetriever(),
      combineDocumentsChain: finalQAChain,
    );
    var resul = await ketrievalQA("đưa ra 3 câu hỏi");
    String resul2 = resul["result"].toString();

    return resul2;
  }
}
