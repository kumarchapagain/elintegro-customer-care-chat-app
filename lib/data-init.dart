import 'dart:convert';

import 'login/system-user.dart';
import 'package:http/http.dart' as http;

class DataInit{

  static Future<Null> init() async{

  }

  static Future<Null> getSystemUsers() async{
    try{
      final http.Response response =  await http.get('');
      if (response.statusCode == 200) {
        SystemUser.setSystemUsers(json.decode(response.body));
      }
    }catch(e){
      print("Error getting system users");
    }
  }

}