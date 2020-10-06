
import 'dart:convert';
import '../utils/config-params.dart';
import 'package:http/http.dart' as http;

class SyncDataToServer{

   static syncChatUsersData(Map<String, dynamic> userData){
     sendToServer(saveUserEndpoint, userData);
   }

   static syncChatMessage(Map<String, dynamic> message){
      sendToServer(saveMessageEndpoint, message);
   }

   static updateProfile(Map<String, dynamic> profileData, String id){
      profileData['id'] = id;
      sendToServer(saveUserEndpoint, profileData);
   }

   static updateMessageSeen(String peerId, String currentUserId){

   }

   static void sendToServer(String url, Map<String, dynamic> data) async{
      String body = json.encode(data);
      http.post(
         url,
         headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
         },
         body: body,
      );
   }
}