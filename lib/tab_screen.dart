import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:gptbrycen/chat_screen.dart';
import 'package:gptbrycen/summarize.dart';
import 'package:url_launcher/src/url_launcher_uri.dart' as url_launcher;

import 'package:http/http.dart' as http;

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});
  @override
  State<TabsScreen> createState() {
    return _TabsScreenState();
  }
}

class _TabsScreenState extends State<TabsScreen> {
  final _advancedDrawerController = AdvancedDrawerController();
  final _apiController = TextEditingController();
  String item = "chat";
  var _enteredAPI = "";
  final _form = GlobalKey<FormState>();
  bool _isAPI = false;
  BuildContext? dcontext;
  dismissDailog() {
    if (dcontext != null) {
      Navigator.pop(dcontext!);
    }
  }

  Future<bool> checkApiKey(String apiKey) async {
    final response = await http.get(
      Uri.parse("https://api.openai.com/v1/models"),
      headers: {"Authorization": "Bearer $apiKey"},
    );
    if (response.statusCode == 200) {
      _isAPI = true;
      return true;
    }
    return false;
  }

  Future<void> _submit() async {
    final isValid = _form.currentState!.validate();

    if (isValid) {
      _form.currentState!.save();
    }

    var collection = FirebaseFirestore.instance.collection('memory');
    if (_isAPI == true) {
      dismissDailog();
      collection.doc("memory").update({"APIKey": _enteredAPI});
      _apiController.clear();
      _isAPI = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdvancedDrawer(
      backdrop: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blueGrey, Colors.blueGrey.withOpacity(0.2)],
          ),
        ),
      ),
      controller: _advancedDrawerController,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
      animateChildDecoration: true,
      rtlOpening: false,
      // openScale: 1.0,
      disabledGestures: false,
      childDecoration: const BoxDecoration(
        // NOTICE: Uncomment if you want to add shadow behind the page.
        // Keep in mind that it may cause animation jerks.
        // boxShadow: <BoxShadow>[
        //   BoxShadow(
        //     color: Colors.black12,
        //     blurRadius: 0.0,
        //   ),
        // ],
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      drawer: SafeArea(
        child: ListTileTheme(
          textColor: Colors.white,
          iconColor: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 128.0,
                height: 128.0,
                margin: const EdgeInsets.only(
                  top: 24.0,
                  bottom: 64.0,
                ),
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/brycen.png',
                ),
              ),
              ListTile(
                onTap: () {
                  setState(() {
                    item = "chat";
                  });
                },
                leading: const Icon(Icons.chat),
                title: const Text('Chat'),
              ),
              ListTile(
                onTap: () {
                  setState(() {
                    item = "summarize";
                  });
                },
                leading: const Icon(Icons.summarize),
                title: const Text('Summarize'),
              ),
              const Divider(
                height: 50,
              ),
              ListTile(
                onTap: openDialog,
                leading: const Icon(Icons.key),
                title: const Text('Thay đổi API Key'),
              ),
              ListTile(
                onTap: () {
                  FirebaseFirestore.instance
                      .collection("memory")
                      .doc("memory")
                      .update({
                    "isConnect": false,
                  });
                },
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Đăng Xuất'),
              ),
              const Spacer(),
              DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 16.0,
                  ),
                  child: const Text('Terms of Service | Privacy Policy'),
                ),
              ),
            ],
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: (item == "chat")
              ? const Text(
                  'Chat với AI',
                  style: TextStyle(color: Colors.white),
                )
              : const Text(
                  'Tóm Tắt File',
                  style: TextStyle(color: Colors.white),
                ),
          actions: [
            (item == "chat")
                ? IconButton(
                    onPressed: () async {
                      final instance = FirebaseFirestore.instance;
                      final batch = instance.batch();
                      var collection = instance.collection("chat");
                      var snapshots = await collection.get();
                      for (var doc in snapshots.docs) {
                        batch.delete(doc.reference);
                      }
                      await batch.commit();
                    },
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ))
                : IconButton(
                    onPressed: () async {
                      final instance = FirebaseFirestore.instance;
                      final batch = instance.batch();
                      var collection = instance.collection("chatSummarize");
                      var snapshots = await collection.get();
                      for (var doc in snapshots.docs) {
                        batch.delete(doc.reference);
                      }
                      await batch.commit();
                      await FirebaseFirestore.instance
                          .collection("memory")
                          .doc("memory")
                          .update({"SummarizeHistory": ""});
                    },
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ))
          ],
          leading: IconButton(
            onPressed: _handleMenuButtonPressed,
            icon: ValueListenableBuilder<AdvancedDrawerValue>(
              valueListenable: _advancedDrawerController,
              builder: (_, value, __) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    value.visible
                        ? ((item == "chat") ? Icons.chat : Icons.summarize)
                        : Icons.menu,
                    key: ValueKey<bool>(value.visible),
                  ),
                );
              },
            ),
          ),
        ),
        body: _ChangePage(),
      ),
    );
  }

  void _handleMenuButtonPressed() {
    // NOTICE: Manage Advanced Drawer state through the Controller.
    // _advancedDrawerController.value = AdvancedDrawerValue.visible();
    _advancedDrawerController.showDrawer();
  }

  // ignore: non_constant_identifier_names
  Widget _ChangePage() {
    if (item == "summarize") {
      return const summarize();
    }
    return const ChatScreen();
  }

  Future openDialog() => showDialog(
      context: context,
      builder: (context) {
        dcontext = context;
        return AlertDialog(
          title: const Text("Nhập API Key mới"),
          content: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _apiController,
                  cursorColor: Colors.blueAccent,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                          borderRadius: BorderRadius.all(Radius.circular(100))),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(100))),
                      hintText: "Nhập API Key ở đây",
                      hintStyle: TextStyle(fontSize: 15, color: Colors.grey)),
                  onChanged: (value) async {
                    final check = await checkApiKey(value);
                    setState(() => _isAPI = check);
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Không được để trống API key.";
                    }

                    if (value.trim().length != 51) {
                      return "Độ dài API Key không hợp lệ.";
                    }

                    if (!_isAPI) {
                      return "API Key không tồn tại.";
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _enteredAPI = value!;
                  },
                ),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: const Text("Sumbit"),
                ),
                TextButton(
                    onPressed: () {
                      url_launcher.launchUrl(Uri.parse(
                          "https://platform.openai.com/account/api-keys"));
                    },
                    child: const Text("Bạn chưa có API Key hãy nhấn vào đây."))
              ],
            ),
          ),
        );
      });
}
