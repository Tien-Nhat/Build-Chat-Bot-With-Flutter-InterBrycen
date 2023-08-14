import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class home_screen extends StatefulWidget {
  const home_screen({super.key});
  @override
  State<StatefulWidget> createState() {
    return _home_screen();
  }
}

class _home_screen extends State<home_screen> {
  final _form = GlobalKey<FormState>();
  var _enteredAPI = "";
  var _enterUserName = "";
  bool _isAPI = true;
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
    if (_isAPI == true && _enterUserName.trim().length >= 4) {
      collection
          .doc("memory")
          .update({"APIKey": _enteredAPI, "isConnect": true});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                width: 500,
                child: Image.asset("assets/images/brycen.png"),
              ),
              Card(
                margin: EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            decoration: InputDecoration(labelText: "UserName"),
                            enableSuggestions: false,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value.trim().length < 4) {
                                return "please enter at least 4 character.";
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enterUserName = value!;
                            },
                          ),
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: "Api Key"),
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            onChanged: (value) async {
                              final check = await checkApiKey(value);
                              print(check);
                              setState(() => _isAPI = check);
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Không được để trống API key.";
                              }

                              if (value.trim().length != 51) {
                                return "Độ dài API Key không hợp lệ.";
                              }
                              if (!_isAPI!) {
                                return "API Key không tồn tại.";
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredAPI = value!;
                            },
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            ),
                            child: const Text("Sumbit"),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
