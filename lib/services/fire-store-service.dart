import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService{

  static Stream<QuerySnapshot> getChatUsers(String role){
    List<String> whereClause = ['SUPER_USER','TEAM_MEMBER'];
    if(role == "SUPER_USER" || role == "TEAM_MEMBER"){
      whereClause = ['SUPER_USER','TEAM_MEMBER', 'ROLE_CUSTOMER'];
    }
    return FirebaseFirestore.instance.collection('users').where('role', whereIn: whereClause).snapshots();
  }

  static Stream<QuerySnapshot> getLastSeenMessage(String peerId, String currentUserId, String groupChatId){
    return FirebaseFirestore.instance
        .collection('messages')
        .doc(groupChatId)
        .collection(groupChatId)
        .where('idFrom', isEqualTo: peerId)
        .where('idTo', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots();
  }

  static updateMessageSeen(String peerId, String currentUserId, String groupChatId) async{
    CollectionReference collectionReference = FirebaseFirestore.instance
        .collection('messages')
        .doc(groupChatId)
        .collection(groupChatId);
    QuerySnapshot querySnapshot = await collectionReference.where('idFrom', isEqualTo: peerId)
        .where('idTo', isEqualTo: currentUserId)
        .where('lastSeen', isEqualTo: false)
        .get();
    if(querySnapshot.docs.length > 0){
      var batch = FirebaseFirestore.instance.batch();
      querySnapshot.docs.forEach((doc) {
        DocumentReference docRef = collectionReference.doc(doc.id);
        batch.update(docRef, {'lastSeen':true});
      });
      batch.commit().then((a) {
        print('updated all documents inside Collection');
      });
    }
  }

  getLastMessage(String peerId, String currentUserId) async{
    String groupChatId = "";
    Map<String, dynamic> messageData = new Map();
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('messages')
        .doc(groupChatId)
        .collection(groupChatId)
        .where('idFrom', isEqualTo: peerId)
        .where('idTo', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    var length = querySnapshot.docs.length;
    if(length > 0){
      QueryDocumentSnapshot queryDocumentSnapshot = querySnapshot.docs.first;
      Map<String, dynamic> data = queryDocumentSnapshot.data();
      messageData['count'] = length;
      messageData['lastMessage'] = data['content'];
      messageData['lastSeen'] = data['lastSeen'];
      messageData['timestamp'] = data['timestamp'];
    }
    return messageData;
  }

}