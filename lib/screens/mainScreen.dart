/*
  privacyIDEA Authenticator

  Authors: Timo Sturm <timo.sturm@netknights.it>

  Copyright (c) 2017-2019 NetKnights GmbH

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

import 'dart:developer';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:privacyidea_authenticator/model/tokens.dart';
import 'package:privacyidea_authenticator/screens/addManuallyScreen.dart';
import 'package:privacyidea_authenticator/utils/LicenseUtils.dart';
import 'package:privacyidea_authenticator/utils/storageUtils.dart';
import 'package:privacyidea_authenticator/utils/util.dart';
import 'package:privacyidea_authenticator/widgets/token_widgets.dart';

class MainScreen extends StatefulWidget {
  MainScreen({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Token> _tokenList = List<Token>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  _MainScreenState() {
    _loadAllTokens();
  }

  _loadAllTokens() async {
    List<Token> list = await StorageUtil.loadAllTokens();
    setState(() {
      this._tokenList = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.title,
        ),
        actions: _buildActionMenu(),
        leading: Padding(
          padding: EdgeInsets.all(4.0),
          child: Image.asset('res/logo/app_logo.png'),
        ),
      ),
      body: _buildTokenList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onAddButtonPressed(context),
        child: Icon(Icons.add),
      ),
    );
  }

  _onAddButtonPressed(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: new Wrap(
              children: <Widget>[
                new ListTile(
                    leading: new Icon(Icons.assignment),
                    // TODO search for good icons
                    title: new Text(
                      'Add token manually',
                      style: Theme.of(context).textTheme.button,
                    ),
                    onTap: () => {
                          Navigator.pop(context), // Close this bottom sheet.
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddTokenManuallyScreen(),
                              )).then((newToken) => _addNewToken(newToken))
                        }),
                new ListTile(
                  leading: new Icon(Icons.scanner),
                  // TODO search for good qrcode icon and add license -> http://fluttericon.com/
                  title: new Text(
                    'Scan QR-Code',
                    style: Theme.of(context).textTheme.button,
                  ),
                  onTap: () => {
                    Navigator.pop(context), // Close this bottom sheet.
                    _scanQRCode()
                  },
                ),
              ],
            ),
          );
        });
  }

  _scanQRCode() async {
    try {
      String barcode = await BarcodeScanner.scan();
      log(
        "Barcode scanned:",
        name: "mainScreen.dart",
        error: barcode,
      );

      Token newToken = parseQRCodeToToken(barcode);
      setState(() {
        log(
          "Adding new token from qr-code:",
          name: "mainScreen.dart",
          error: newToken,
        );
        _tokenList.add(newToken);
      });
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        //  Camera access was denied
      } else {
        //  Unknown error
      }
    } on FormatException {
      //  User returned by pressing the back button
    } on ArgumentError catch (e) {
      // Show the error message to the user.
      _showMessage(
          "${e.message}\n Please inform the creator of this qr code about the problem.",
          Duration(seconds: 8));
      log(
        "Malformed QR code:",
        name: "mainScreen.dart",
        error: e.toString(),
      );
    } catch (e) {
      //  Unknown error
    }
  }

  ListView _buildTokenList() {
    return ListView.separated(
        itemBuilder: (context, index) {
          Token token = _tokenList[index];
          return TokenWidget(
            key: ObjectKey(token),
            token: token,
            onDeleteClicked: () => _deleteClicked(token),
          );
        },
        separatorBuilder: (context, index) {
          return Divider();
        },
        itemCount: _tokenList.length);
  }

  void _deleteClicked(Token token) {
    setState(() {
      print("Remove: $token");
      _tokenList.remove(token);
      StorageUtil.deleteToken(token);
    });
  }

  List<Widget> _buildActionMenu() {
    return <Widget>[
      PopupMenuButton<String>(
        onSelected: (String value) => {
          if (value == "about")
            {
//              clearLicenses(), // This is used for testing purposes.
              addAllLicenses(),
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LicensePage(
                            applicationName: "privacyIDEA Authenticator",
                            applicationVersion: "0.0.1",
                            applicationIcon:
                                Image.asset('res/logo/app_logo.png'),
                            applicationLegalese: "Apache License 2.0",
                          )))
            }
          else
            {
              // TODO if we have settings at some point, open them
            }
        },
        elevation: 5.0,
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: "about",
            child: Text("About"),
          ),
          PopupMenuDivider(),
          PopupMenuItem<String>(
            value: null, // TODO add value as key for navigation
            child: Text("Settings"),
          ),
        ],
      ),
    ];
  }

  _addNewToken(Token newToken) {
    log("Adding new token:", name: "mainScreen.dart", error: newToken);
    if (newToken != null) {
      setState(() {
        _tokenList.add(newToken);
      });
    }
  }

  _showMessage(String message, Duration duration) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: duration,
    ));
  }
}
