import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lanthu_bot/models/token.dart';
import 'package:lanthu_bot/utils/constants.dart';

class ScreenArguments {
  final Token token;
  ScreenArguments(this.token);
}

class AddToken extends StatefulWidget {
  const AddToken({Key? key, this.token}) : super(key: key);
  @override
  _AddTokenState createState() => _AddTokenState();

  final Token? token;
}

class _AddTokenState extends State<AddToken> {
  TextEditingController nameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController slugController = TextEditingController();
  TextEditingController decimalController = TextEditingController();

  String _selectbase = "BNB";

  String _widgetText = "Add Token";

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  void initializeData() async {
    if (widget.token != null) {
      Token token = widget.token as Token;
      nameController.text = token.name.toString();
      addressController.text = token.address.toString();

      slugController.text = token.slug.toString();
      decimalController.text = token.decimal.toString();
      setState(() {
        _selectbase = token.base.toString();
        _widgetText = 'Update Trade';
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    addressController.dispose();
    slugController.dispose();
    decimalController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AlertDialog insertDialog = AlertDialog(
      title: const Text('Add new Token'),
      contentPadding: const EdgeInsets.all(24),
      content: const Text("Are you sure, you want add this token?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Nope'),
        ),
        TextButton(
          onPressed: () => insertToken(),
          child: const Text('Sure'),
        ),
      ],
    );

    final AlertDialog updateDialog = AlertDialog(
      title: const Text('Upate Token'),
      contentPadding: const EdgeInsets.all(24),
      content: const Text("Are you sure, you want to update this token?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Nope'),
        ),
        TextButton(
          onPressed: () => updateToken(),
          child: const Text('Sure'),
        ),
      ],
    );

    final AlertDialog deleteDialog = AlertDialog(
      title: const Text('Delete Token'),
      contentPadding: const EdgeInsets.all(24),
      content: const Text("Are you sure, you want to delete this token?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Nope'),
        ),
        TextButton(
          onPressed: () => deleteToken(),
          child: const Text('Sure'),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_widgetText),
        actions: <Widget>[
          widget.token != null
              ? IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    showDialog<void>(
                        context: context, builder: (context) => deleteDialog);
                  })
              : Container(),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: decimalController,
                    decoration: const InputDecoration(labelText: 'Decimal'),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 16, 8, 4),
                  child: Text("Swap with"),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButton<String>(
                    value: _selectbase,
                    icon: const Icon(Icons.arrow_downward),
                    itemHeight: 60,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectbase = newValue!;
                      });
                    },
                    items: <String>[
                      'BNB',
                      'BUSD',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: slugController,
                    decoration: const InputDecoration(labelText: 'Slug'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (widget.token != null) {
            showDialog<void>(
                context: context, builder: (context) => updateDialog);
          } else {
            showDialog<void>(
                context: context, builder: (context) => insertDialog);
          }
        },
        child: const Icon(Icons.check),
      ),
    );
  }

  insertToken() async {
    var name = nameController.text;
    var slug = slugController.text;
    var address = addressController.text;
    var decimal = int.parse(decimalController.text.toString());
    var base = _selectbase;

    var query = """mutation {
          addToken(
            name: "$name",
            slug: "$slug",
            address: "$address",
            decimal: $decimal,
            base: "$base",
          ) {
            message
            error
            result {
              _id
            }
          }
        }""";
    var dio = Dio();
    try {
      await dio.post("$graphUrl/graphql", data: {"query": query});
      Future.delayed(const Duration(milliseconds: 2000), () {
        Navigator.pop(context);
        Navigator.pop(context);
      });
    } catch (e) {
      throw Exception('Failed to add token');
    }
  }

  updateToken() async {
    var tokenId = widget.token!.id;
    var name = nameController.text;
    var slug = slugController.text;
    var address = addressController.text;
    var decimal = int.parse(decimalController.text.toString());
    var base = _selectbase;

    var query = """mutation {
          updateToken(
            _id: "$tokenId",
            name: "$name",
            slug: "$slug",
            address: "$address",
            decimal: $decimal,
            base: "$base",
          ) {
            message
            error
            result {
              _id
            }
          }
        }""";
    var dio = Dio();
    try {
      await dio.post("$graphUrl/graphql", data: {"query": query});
      Future.delayed(const Duration(milliseconds: 2000), () {
        Navigator.pop(context);
        Navigator.pop(context);
      });
    } catch (e) {
      throw Exception('Failed to update token.');
    }
  }

  deleteToken() async {
    var tokenId = widget.token!.id;
    var query = """mutation {
          removeToken(
            _id: "$tokenId",
          ) {
            message
            error
            result {
              _id
            }
          }
        }""";
    var dio = Dio();
    try {
      await dio.post("$graphUrl/graphql", data: {"query": query});
      Future.delayed(const Duration(milliseconds: 2000), () {
        Navigator.pop(context);
        Navigator.pop(context);
      });
    } catch (e) {
      throw Exception('Failed to delete token');
    }
  }
}
