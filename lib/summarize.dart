import 'dart:convert';

import 'package:gptbrycen/widget/chat_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';

class summarize extends StatefulWidget {
  const summarize({super.key});

  @override
  State<summarize> createState() => _summarize();
}

class _summarize extends State<summarize> {
  bool _isTyping = false;
  String _checkconnect = "true";

  late TextEditingController textEditingController;
  @override
  void initState() {
    textEditingController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  void _submitMessage() async {
    _isTyping = true;
    var collection = FirebaseFirestore.instance.collection('memory');
    var docSnapshot = await collection.doc('test1').get();
    Map<String, dynamic> data = docSnapshot.data()!;
    _checkconnect = data["CheckConnect"];
    final embeddings = OpenAIEmbeddings(apiKey: data["APIKey"]);

    final enteredMessage = textEditingController.text;
    if (enteredMessage.trim().isEmpty) {
      return;
    }
    FocusScope.of(context).unfocus();

    textEditingController.clear();

    List<Document> documents = [Document(pageContent: data["Document"])];
    FirebaseFirestore.instance.collection("chatSummarize").add({
      "text": enteredMessage,
      "createdAt": Timestamp.now(),
      "Indext": 0,
    });
    final docSearch = await MemoryVectorStore.fromDocuments(
      documents: documents,
      embeddings: embeddings,
    );
    final llm = ChatOpenAI(
      apiKey: data["APIKey"],
      model: 'gpt-3.5-turbo-0613',
      temperature: 0,
    );
    final qaChain = OpenAIQAWithSourcesChain(llm: llm);
    final docPrompt = PromptTemplate.fromTemplate(
      'Content: {page_content}\nSource: {source}',
    );
    final finalQAChain = StuffDocumentsChain(
      llmChain: qaChain,
      documentPrompt: docPrompt,
    );
    final retrievalQA = RetrievalQAChain(
      retriever: docSearch.asRetriever(),
      combineDocumentsChain: finalQAChain,
    );
    final res = await retrievalQA(enteredMessage);
    FirebaseFirestore.instance.collection("chatSummarize").add({
      "text": res,
      "createdAt": Timestamp.now(),
      "Indext": 0,
    });

    _isTyping = false;
  }

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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                (loadedMessages.length == 0)
                    ? Expanded(
                        child: Center(
                          child: ElevatedButton.icon(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF343541)),
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

                              if (result == null) return;
                              PlatformFile file = await result.files.first;
                              FirebaseFirestore.instance
                                  .collection("memory")
                                  .doc("test1")
                                  .update({
                                "Document": utf8.decode(file.bytes!),
                              });
                            },
                          ),
                        ),
                      )
                    : Flexible(
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
                            decoration: const InputDecoration.collapsed(
                                hintText: "Nhập text ở đây",
                                hintStyle: TextStyle(color: Colors.grey)),
                          ),
                        ),
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
