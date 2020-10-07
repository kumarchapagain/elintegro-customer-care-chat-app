import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/text.dart';
import 'services/sync-data-server.dart';
import 'services/fire-store-service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chat/chat.dart';
import 'utils/const.dart';
import 'settings.dart';
import 'widget/loading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'main.dart';

class HomeScreen extends StatefulWidget {
  final String currentUserId;
  final String role;

  HomeScreen({Key key, @required this.currentUserId, @required this.role}) : super(key: key);

  @override
  State createState() => HomeScreenState(currentUserId: currentUserId, role:role);
}

class HomeScreenState extends State<HomeScreen> {
  HomeScreenState({Key key, @required this.currentUserId, this.role});

  final String currentUserId;
  final String role;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final GoogleSignIn googleSignIn = GoogleSignIn();

  bool isLoading = false;
  List<Choice> choices = const <Choice>[
    const Choice(title: 'Settings', icon: Icons.settings),
    const Choice(title: 'Log out', icon: Icons.exit_to_app),
  ];

  @override
  void initState() {
    super.initState();
    registerNotification();
    configLocalNotification();
  }

  void registerNotification() {
    firebaseMessaging.requestNotificationPermissions();

    firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) {
      print('onMessage: $message');
      Platform.isAndroid
          ? showNotification(message['notification'])
          : showNotification(message['aps']['alert']);
      return;
    }, onResume: (Map<String, dynamic> message) {
      print('onResume: $message');
      showNotification(message['notification']);
      return;
    }, onLaunch: (Map<String, dynamic> message) {
      print('onLaunch: $message');
      showNotification(message['notification']);
      return;
    });

    firebaseMessaging.getToken().then((token) {
      print('token: $token');
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({'pushToken': token});
    }).catchError((err) {
      Fluttertoast.showToast(msg: err.message.toString());
    });
  }

  void configLocalNotification() {
    var initializationSettingsAndroid =
    new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void onItemMenuPress(Choice choice) {
    if (choice.title == 'Log out') {
      handleSignOut();
    } else {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => ChatSettings()));
    }
  }

  void showNotification(message) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      Platform.isAndroid
          ? 'com.elintegro.customerchat'
          : 'com.elintegro.customerchat',
      appBarTitle, //title
      appTitle, //description
      playSound: true,
      enableVibration: true,
      importance: Importance.Max,
      priority: Priority.High,
    );
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    print(message);
//    print(message['body'].toString());
//    print(json.encode(message));

    await flutterLocalNotificationsPlugin.show(0, message['title'].toString(),
        message['body'].toString(), platformChannelSpecifics,
        payload: json.encode(message));

//    await flutterLocalNotificationsPlugin.show(
//        0, 'plain title', 'plain body', platformChannelSpecifics,
//        payload: 'item x');
  }

  Future<bool> onBackPress() {
    exitScreen();
    return Future.value(false);
  }

  Future<Null> exitScreen() async{
    exit(0);
  }

  Future<Null> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding:
            EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
            children: <Widget>[
              Container(
                color: Colors.blue,
                margin: EdgeInsets.all(0.0),
                padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
                height: 100.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.exit_to_app,
                        size: 30.0,
                        color: Colors.white,
                      ),
                      margin: EdgeInsets.only(bottom: 10.0),
                    ),
                    Text(
                      'Exit app',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Are you sure to exit app?',
                      style: TextStyle(color: Colors.white70, fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.cancel,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'Cancel',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.check_circle,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'Yes',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
        break;
    }
  }

  Future<Null> handleSignOut() async {
    this.setState(() {
      isLoading = true;
    });

    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    this.setState(() {
      isLoading = false;
    });

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MyApp()),
            (Route<dynamic> route) => false);
  }

  String roleInfo(DocumentSnapshot document){
    String roleInfo = 'Customer';
    String role = document.data()['role'];
    if(role == "SUPER_USER"){
      roleInfo = 'Admin';
    }else if(role == "TEAM_MEMBER"){
      roleInfo = 'Team Member';
    }
    return roleInfo;
  }

  String getGroupChatId(String peerId){
    String groupChatId = '';
    if (currentUserId.hashCode <= peerId.hashCode) {
      groupChatId = '$currentUserId-$peerId';
    } else {
      groupChatId = '$peerId-$currentUserId';
    }
    return groupChatId;
  }

  Stream<QuerySnapshot> getLastSeenMessage(String peerId){
    String groupChatId = getGroupChatId(peerId);
    return FirestoreService.getLastSeenMessage(peerId, currentUserId, groupChatId);
  }

  updateMessageSeenInfo(String peerId){
    String groupChatId = getGroupChatId(peerId);
    FirestoreService.updateMessageSeen(peerId, currentUserId, groupChatId);
    SyncDataToServer.updateMessageSeen(peerId, currentUserId);
  }

  isOnline(String peerId){
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Elintegro: Customer Care',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: <Widget>[
          PopupMenuButton<Choice>(
            onSelected: onItemMenuPress,
            itemBuilder: (BuildContext context) {
              return choices.map((Choice choice) {
                return PopupMenuItem<Choice>(
                    value: choice,
                    child: Row(
                      children: <Widget>[
                        Icon(
                          choice.icon,
                          color: primaryColor,
                        ),
                        Container(
                          width: 10.0,
                        ),
                        Text(
                          choice.title,
                          style: TextStyle(color: primaryColor),
                        ),
                      ],
                    ));
              }).toList();
            },
          ),
        ],
      ),
      body: WillPopScope(
        child: Stack(
          children: <Widget>[
            // List
            Container(
              child: StreamBuilder(
                stream:FirestoreService.getChatUsers(role),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                      ),
                    );
                  } else {
                    return ListView.builder(
                      padding: EdgeInsets.all(10.0),
                      itemBuilder: (context, index) =>
                          buildItem(context, snapshot.data.documents[index]),
                      itemCount: snapshot.data.documents.length,
                    );
                  }
                },
              ),
            ),

            // Loading
            Positioned(
              child: isLoading ? const Loading() : Container(),
            )
          ],
        ),
        onWillPop: onBackPress,
      ),
    );
  }

  Widget buildItem(BuildContext context, DocumentSnapshot document) {
    String role = roleInfo(document);
    if (document.data()['id'] == currentUserId) {
      return Container();
    } else {
      return Container(
        child: FlatButton(
          child: Row(
            children: <Widget>[
              Material(
                child: document.data()['photoUrl'] != null
                    ? CachedNetworkImage(
                  placeholder: (context, url) => Container(
                    child: CircularProgressIndicator(
                      strokeWidth: 1.0,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(themeColor),
                    ),
                    width: 50.0,
                    height: 50.0,
                    padding: EdgeInsets.all(15.0),
                  ),
                  imageUrl: document.data()['photoUrl'],
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                )
                    : Icon(
                  Icons.account_circle,
                  size: 50.0,
                  color: greyColor,
                ),
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
                clipBehavior: Clip.hardEdge,
              ),
              // Container(
              //   child: Padding(
              //     padding: EdgeInsets.only(top: 20.0),
              //     child: isOnline(document.data()['id'])?Icon(
              //       Icons.add_circle,
              //       size: 15.0,
              //       color: Colors.green,
              //     ):Icon(
              //       Icons.add_circle,
              //       size: 15.0,
              //       color: Colors.white,
              //     ),
              //   ),
              // ),
              Flexible(
                child: Container(
                  child: Column(
                    children: <Widget>[
                      Container(
                        child: Text(
                          '$role: ${document.data()['nickname']}',
                          style: TextStyle(color: primaryColor),
                        ),
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                      ),
                      StreamBuilder(
                        stream: getLastSeenMessage(document.data()['id']), // function where you call your api
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data.documents.length > 0){
                            var docm = snapshot.data.documents.first;
                            Map<String, dynamic> data = docm.data();
                            String content = data['content'];
                            if(data['type'] != 0){
                              content = messageAttachment;
                            }
                            return Container(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      content,
                                      style: data['lastSeen'] ? TextStyle(color: greyColor, fontSize: 14.0) : TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16.0),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 1.0),
                                    child: Text(
                                      DateFormat('dd MMM kk:mm').format(
                                          DateTime.fromMillisecondsSinceEpoch(
                                              int.parse(data['timestamp']))),
                                      style: TextStyle(
                                          color: greyColor,
                                          fontSize: 12.0,
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ),
                              alignment: Alignment.centerLeft,
                              margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                            );
                          }else
                            return Container();
                        },
                      ),
                    ],
                  ),
                  margin: EdgeInsets.only(left: 20.0),
                ),
              ),
            ],
          ),
          onPressed: () {
            updateMessageSeenInfo(document.id);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Chat(
                        peerId: document.id,
                        peerAvatar: document.data()['photoUrl'],
                        peerRole:role,
                        peerName:document.data()['nickname']
                    )));
          },
          color: greyColor2,
          padding: EdgeInsets.fromLTRB(25.0, 10.0, 25.0, 10.0),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
        margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
      );
    }
  }
}

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}
