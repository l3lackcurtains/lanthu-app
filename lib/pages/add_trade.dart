import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lanthu_bot/models/token.dart';
import 'package:lanthu_bot/models/token_info.dart';
import 'package:lanthu_bot/models/trade.dart';
import 'package:http/http.dart' as http;
import 'package:lanthu_bot/utils/constants.dart';

class AddTrade extends StatefulWidget {
  const AddTrade({Key? key, this.trade}) : super(key: key);
  @override
  _AddTradeState createState() => _AddTradeState();

  final Trade? trade;
}

class _AddTradeState extends State<AddTrade> {
  final _formKey = GlobalKey<FormState>();

  List<Token> tokens = [];
  Token _selectedToken = const Token(name: "BNB");
  int _typeIndex = 0;
  final List<String> _status = ["BUYING", "SELLING", "COMPLETED", "ERROR"];
  String _widgetText = "Add Trade";

  String _amount = "0.0";
  String _buyLimit = "0.0";
  String _sellLimit = "0.0";
  String _stopLossLimit = "0.0";

  Key _amountKey = GlobalKey();
  Key _buyLimitKey = GlobalKey();
  Key _sellLimitKey = GlobalKey();
  Key _stopLossLimitKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<List<Token>> getTokens() async {
    var client = http.Client();
    var query = """query {
                  getTokens{
                    error
                    message
                    result {
                      _id
                      name
                      address
                      base
                    }
                  }
                }
              """;

    try {
      var uri = Uri.parse('$graphUrl/?query=$query');

      var response = await client.get(
        uri,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        if (resData["data"]["getTokens"]["result"] != null) {
          final List<dynamic> message = resData["data"]["getTokens"]["result"];
          tokens.addAll(message.map((m) => Token.fromMap(m)).toList());
        }
      }
    } on SocketException {
      client.close();
      throw 'No Internet connection';
    }
    return tokens;
  }

  Future<TokenInfo> getTokenInfo(String tokenId) async {
    var client = http.Client();
    TokenInfo tokenInfo = const TokenInfo();

    var query = """query {
                  getTokenInfo(tokenId: "$tokenId"){
                    error
                    message
                    result {
                      balance
                      busdBalance
                      bnbPrice
                      price
                      bnbBalance
                      token
                    }
                  }
                }
              """;

    try {
      var uri = Uri.parse('$graphUrl/?query=$query');
      var response = await client.get(
        uri,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        if (resData["data"]["getTokenInfo"]["result"] != null) {
          final Map<String, dynamic> message =
              resData["data"]["getTokenInfo"]["result"];
          tokenInfo = TokenInfo.fromMap(message);
        }
      }
    } on SocketException {
      client.close();
      throw 'No Internet connection';
    }

    return tokenInfo;
  }

  void initializeData() async {
    List<Token> allTokens = await getTokens();
    setState(() {
      tokens = allTokens;
      _selectedToken = tokens[0];
    });

    if (widget.trade != null) {
      Trade trade = widget.trade as Trade;

      setState(() {
        _widgetText = 'Update Trade';
        _amount = trade.amount.toString();
        _buyLimit = trade.buyLimit.toString();
        _sellLimit = trade.sellLimit.toString();
        _stopLossLimit = trade.stopLossLimit.toString();

        _amountKey = Key(_amount);
        _buyLimitKey = Key(_buyLimit);
        _sellLimitKey = Key(_sellLimit);
        _stopLossLimitKey = Key(_stopLossLimit);
      });

      final index = tokens.indexWhere((element) =>
          element.name == trade.token?.name.toString().toUpperCase());
      setState(() {
        if (index >= 0 && index < tokens.length) {
          _selectedToken = tokens[index];
        }
        for (var stat = 0; stat < _status.length; stat++) {
          if (trade.status == _status[stat]) _typeIndex = stat;
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AlertDialog insertDialog = AlertDialog(
      title: const Text('Add new Trade'),
      contentPadding: const EdgeInsets.all(24),
      content: const Text("Are you sure, you want to add this token?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Nope'),
        ),
        TextButton(
          onPressed: () => insertTrade(),
          child: const Text('Sure'),
        ),
      ],
    );

    final AlertDialog updateDialog = AlertDialog(
      title: const Text('Upate Trade'),
      contentPadding: const EdgeInsets.all(24),
      content: const Text("Are you sure, you want to update this trade?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Nope'),
        ),
        TextButton(
          onPressed: () => updateTrade(),
          child: const Text('Sure'),
        ),
      ],
    );

    final AlertDialog deleteDialog = AlertDialog(
      title: const Text('Delete Trade'),
      contentPadding: const EdgeInsets.all(24),
      content: const Text("Are you sure, you want to delete this trade?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Nope'),
        ),
        TextButton(
          onPressed: () => deleteTrade(),
          child: const Text('Sure'),
        ),
      ],
    );

    String totalBuy = "0.00000000";
    String totalSell = "0.00000000";
    String totalProfit = "0.00000000";
    String totalStopLoss = "0.00000000";

    if (double.tryParse(_amount) != null &&
        double.tryParse(_buyLimit) != null &&
        double.parse(_buyLimit) > 0) {
      totalBuy =
          (double.parse(_amount) * double.parse(_buyLimit)).toStringAsFixed(8);
    }
    if (double.tryParse(_amount) != null &&
        double.tryParse(_sellLimit) != null &&
        double.parse(_sellLimit) > 0) {
      totalSell =
          (double.parse(_amount) * double.parse(_sellLimit)).toStringAsFixed(8);
    }

    if (double.tryParse(_amount) != null &&
        double.tryParse(_buyLimit) != null &&
        double.tryParse(_sellLimit) != null &&
        double.parse(_buyLimit) > 0 &&
        double.parse(_sellLimit) > 0) {
      totalProfit =
          (double.parse(totalSell) - double.parse(totalBuy)).toStringAsFixed(8);
    }

    if (double.tryParse(_amount) != null &&
        double.tryParse(_buyLimit) != null &&
        double.tryParse(_stopLossLimit) != null &&
        double.parse(_buyLimit) > 0 &&
        double.parse(_stopLossLimit) > 0) {
      totalStopLoss = (double.parse(totalBuy) -
              double.parse(_amount) * double.parse(_stopLossLimit))
          .toStringAsFixed(8);
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_widgetText),
        actions: <Widget>[
          widget.trade != null
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
          Container(
            color: Theme.of(context).canvasColor,
            height: 100,
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("BUY"),
                    Text("\$" + totalBuy),
                  ],
                ),
                const SizedBox(
                  height: 4,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("SELL"),
                    Text("\$" + totalSell),
                  ],
                ),
                const SizedBox(
                  height: 4,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("PROFIT"),
                    Text("\$" + totalProfit),
                  ],
                ),
                const SizedBox(
                  height: 4,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("STOP LOSS"),
                    Text("\$" + totalStopLoss),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(0, 100, 0, 0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ActionChip(
                              backgroundColor: _typeIndex == 0
                                  ? const Color(0xFF5f27cd)
                                  : Colors.grey.shade700,
                              label: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 4, 8, 4),
                                  child: const Text('BUYING')),
                              onPressed: () {
                                setState(() {
                                  _typeIndex = 0;
                                });
                              }),
                          ActionChip(
                              backgroundColor: _typeIndex == 1
                                  ? const Color(0xFF5f27cd)
                                  : Colors.grey.shade700,
                              label: Container(
                                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                                child: const Text('SELLING'),
                              ),
                              onPressed: () {
                                setState(() {
                                  _typeIndex = 1;
                                });
                              }),
                          ActionChip(
                              backgroundColor: _typeIndex == 2
                                  ? const Color(0xFF44bd32)
                                  : Colors.grey.shade700,
                              label: Container(
                                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                                child: const Text('COMPLETED'),
                              ),
                              onPressed: () {
                                setState(() {
                                  _typeIndex = 2;
                                });
                              }),
                          ActionChip(
                              backgroundColor: _typeIndex == 3
                                  ? Colors.red.shade500
                                  : Colors.grey.shade700,
                              label: Container(
                                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                                child: const Text('ERROR'),
                              ),
                              onPressed: () {
                                setState(() {
                                  _typeIndex = 3;
                                });
                              }),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
                      child: DropdownButton<Token>(
                        value: _selectedToken,
                        icon: const Icon(Icons.arrow_downward),
                        iconSize: 18,
                        itemHeight: 60,
                        isExpanded: true,
                        onChanged: (Token? newValue) {
                          setState(() {
                            _selectedToken = newValue!;
                          });
                        },
                        items: tokens.map((tkn) {
                          return DropdownMenuItem<Token>(
                            value: tkn,
                            child: Text(
                                "${tkn.name!.toUpperCase()} (${tkn.base})"),
                          );
                        }).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
                      child: Focus(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                          ),
                          key: _amountKey,
                          initialValue: _amount,
                          onChanged: (String val) {
                            if (mounted) {
                              setState(() {
                                _amount = val;
                              });
                            }
                          },
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Empty amount";
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
                      child: Focus(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Buy Limit'),
                          key: _buyLimitKey,
                          initialValue: _buyLimit,
                          onChanged: (String val) {
                            if (mounted) {
                              setState(() {
                                _buyLimit = val;
                              });
                            }
                          },
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Empty buy limit";
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
                      child: Focus(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Sell Limit'),
                          key: _sellLimitKey,
                          initialValue: _sellLimit,
                          onChanged: (String val) {
                            if (mounted) {
                              setState(() {
                                _sellLimit = val;
                              });
                            }
                          },
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Empty sell limit";
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
                      child: Focus(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Stop Loss Limit'),
                          key: _stopLossLimitKey,
                          initialValue: _stopLossLimit,
                          onChanged: (String val) {
                            if (mounted) {
                              setState(() {
                                _stopLossLimit = val;
                              });
                            }
                          },
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Empty stop loss limit";
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    Container(height: 16),
                    FutureBuilder(
                        future: getTokenInfo(_selectedToken.id.toString()),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(height: 160);
                          } else {
                            if (snapshot.hasData) {
                              final tokenInfo = snapshot.data as TokenInfo;
                              final balanceUsd = double.parse((double.parse(
                                              tokenInfo.balance.toString()) *
                                          double.parse(
                                              tokenInfo.price.toString()))
                                      .toString())
                                  .toStringAsFixed(8);

                              final bnbUsd = double.parse((double.parse(
                                              tokenInfo.bnbBalance.toString()) *
                                          double.parse(
                                              tokenInfo.bnbPrice.toString()))
                                      .toString())
                                  .toStringAsFixed(8);

                              return Material(
                                child: Container(
                                  height: 160,
                                  padding: const EdgeInsets.all(8.0),
                                  child: ListTile(
                                    title: Text(
                                        "${tokenInfo.token} (\$${tokenInfo.price.toString()})"),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 8,
                                        ),
                                        Text(
                                            "${double.parse(tokenInfo.balance.toString()).toStringAsFixed(8)} ${tokenInfo.token} (\$$balanceUsd)"),
                                        Container(
                                          height: 8,
                                        ),
                                        Text(
                                            "${double.parse(tokenInfo.bnbBalance.toString()).toStringAsFixed(8)} BNB (\$$bnbUsd)"),
                                        Container(
                                          height: 8,
                                        ),
                                        Text(
                                            "${double.parse(tokenInfo.busdBalance.toString()).toStringAsFixed(8)} BUSD"),
                                        Container(
                                          height: 8,
                                        ),
                                        TextButton(
                                          child: const Text('INSERT MAX'),
                                          onPressed: () {
                                            setState(() {
                                              _amount =
                                                  tokenInfo.balance.toString();
                                              _amountKey = Key(
                                                  tokenInfo.balance.toString());
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            return Container(
                              color: Colors.black,
                              child: const LinearProgressIndicator(
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (widget.trade != null) {
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

  insertTrade() async {
    final formState = _formKey.currentState;
    if (formState!.validate()) {
      var amount = double.parse(_amount.toString());
      var buyLimit = double.parse(_buyLimit.toString());
      var sellLimit = double.parse(_sellLimit.toString());
      var stopLossLimit = double.parse(_stopLossLimit.toString());
      var status = _status[_typeIndex];
      var tokenId = _selectedToken.id;

      var query = """mutation {
          addTrade(
            amount: $amount,
            buyLimit: $buyLimit,
            sellLimit: $sellLimit,
            stopLossLimit: $stopLossLimit,
            status: "$status",
            tokenId: "$tokenId"
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
        throw Exception('Failed to add trade');
      }
    }
  }

  updateTrade() async {
    final formState = _formKey.currentState;
    if (formState!.validate()) {
      var tradeId = widget.trade!.id;
      var amount = double.parse(_amount.toString());
      var buyLimit = double.parse(_buyLimit.toString());
      var sellLimit = double.parse(_sellLimit.toString());
      var stopLossLimit = double.parse(_stopLossLimit.toString());
      var status = _status[_typeIndex];
      var tokenId = _selectedToken.id;

      var query = """mutation {
          updateTrade(
            _id: "$tradeId",
            amount: $amount,
            buyLimit: $buyLimit,
            sellLimit: $sellLimit,
            stopLossLimit: $stopLossLimit,
            status: "$status",
            tokenId: "$tokenId"
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
        throw Exception('Failed to update trade');
      }
    }
  }

  deleteTrade() async {
    var tradeId = widget.trade!.id;
    var query = """mutation {
          removeTrade(
            _id: "$tradeId",
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
      throw Exception('Failed to delete trade');
    }
  }
}
