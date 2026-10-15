import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctro/features/consultation/chat/constants/firestore_constants.dart';
import 'package:doctro/features/consultation/chat/models/message_chat.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatProvider {
  final SharedPreferences prefs;
  final FirebaseFirestore firebaseFirestore;
  final FirebaseStorage firebaseStorage;

  ChatProvider(
      {required this.firebaseFirestore,
      required this.prefs,
      required this.firebaseStorage});

  String? getPref(String key) {
    return prefs.getString(key);
  }

  UploadTask uploadFile(File image, String fileName) {
    Reference reference = firebaseStorage.ref().child(fileName);
    UploadTask uploadTask = reference.putFile(image);
    return uploadTask;
  }

  Future<void> updateDataFirestore(String collectionPath, String docPath,
      Map<String, dynamic> dataNeedUpdate) {
    return firebaseFirestore
        .collection(collectionPath)
        .doc(docPath)
        .update(dataNeedUpdate);
  }

  Stream<QuerySnapshot> getChatStream(String groupChatId, int limit) {
    return firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId)
        .orderBy(FirestoreConstants.timestamp, descending: true)
        .limit(limit)
        .snapshots();
  }

  void sendMessage(String content, int type, String groupChatId,
      String currentUserId, String peerId) {
    DocumentReference documentReference = firebaseFirestore
        .collection(FirestoreConstants.pathMessageCollection)
        .doc(groupChatId)
        .collection(groupChatId)
        .doc(DateTime.now().millisecondsSinceEpoch.toString());

    MessageChat messageChat = MessageChat(
      idFrom: currentUserId,
      idTo: peerId,
      timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: type,
    );

    FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(
        documentReference,
        messageChat.toJson(),
      );
    });
  }

  /// Push notifications for a new chat message are intentionally not sent
  /// from the client. This used to POST directly to
  /// https://fcm.googleapis.com/fcm/send with the legacy FCM server key
  /// (Env.firebaseServerKey) as a bearer credential - that key can push to
  /// every device in the Firebase project, so embedding it in a client
  /// binary at all is the risk, regardless of whether a build's
  /// --dart-define actually sets one today. Per this app's own build
  /// docs (Env's server-authority keys must never reach a client build),
  /// sending this notification needs to move to the backend - e.g. a
  /// `POST /chat/notify` the backend calls FCM from - which doesn't exist
  /// yet. No-ops until that's built; the chat message itself still sends
  /// via Firestore in sendMessage() above regardless.
  void sendNotification(String content, String token, String userId, int type,
      String userImage, String userName) {}
}

class TypeMessage {
  static const text = 0;
  static const image = 1;
  static const sticker = 2;
}
