import 'dart:async';
import 'package:doctro/core/constants/app_icons.dart';
import 'package:hugeicons/hugeicons.dart';
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctro/features/consultation/chat/constants/firestore_constants.dart';
import 'package:doctro/features/consultation/chat/models/message_chat.dart';
import 'package:doctro/features/consultation/chat/providers/auth_provider.dart';
import 'package:doctro/features/consultation/chat/providers/chat_provider.dart';
import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/osler_loader.dart';
import 'package:doctro/widgets/osler_state_view.dart';
import 'package:doctro/widgets/osler_toast.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/core/utils/safe_parse.dart';
import 'package:doctro/features/dashboard/login_home.dart';
import 'package:doctro/theme/app_motion.dart';
import 'package:firebase_auth/firebase_auth.dart' as FA;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages.dart';

class ChatPage extends StatefulWidget {
  final String peerId;
  final String peerAvatar;
  final String peerNickname;
  final String token;
  final String isNavigate;

  const ChatPage(
      {super.key,
      required this.peerId,
      required this.peerAvatar,
      required this.peerNickname,
      required this.token,
      required this.isNavigate});

  @override
  State createState() => ChatPageState(
        peerId: peerId,
        peerAvatar: peerAvatar,
        peerNickname: peerNickname,
      );
}

class ChatPageState extends State<ChatPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late SharedPreferences prefs;

  ChatPageState(
      {Key? key,
      required this.peerId,
      required this.peerAvatar,
      required this.peerNickname});

  String peerId;
  String peerAvatar;
  String peerNickname;
  late String currentUserId;

  File? galleryImageFile;
  File? cameraImageFile;
  String imageUrlCamera = "";
  String imageUrlGallery = "";

  List<QueryDocumentSnapshot> listMessage = [];
  int _limit = 20;
  final int _limitIncrement = 20;
  String groupChatId = "";

  bool isLoading = false;
  bool isShowSticker = false;

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  late ChatProvider chatProvider;
  late AuthProvider authProvider;

  void init() async {
    prefs = await _prefs;
  }

  @override
  void initState() {
    super.initState();

    init();
    chatProvider = context.read<ChatProvider>();
    authProvider = context.read<AuthProvider>();
    focusNode.addListener(onFocusChange);
    listScrollController.addListener(_scrollListener);
    readLocal();
  }

  _scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange &&
        _limit <= listMessage.length) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      setState(() {
        isShowSticker = false;
      });
    }
  }

  @override
  void dispose() {
    focusNode.removeListener(onFocusChange);
    listScrollController.removeListener(_scrollListener);
    focusNode.dispose();
    listScrollController.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  void readLocal() {
    currentUserId = FA.FirebaseAuth.instance.currentUser?.uid ?? "";
    if (authProvider.getUserFirebaseId()?.isNotEmpty == true) {
      currentUserId = authProvider.getUserFirebaseId()!;
    } else {}
    if (currentUserId.compareTo(peerId) > 0) {
      groupChatId = '$currentUserId-$peerId';
    } else {
      groupChatId = '$peerId-$currentUserId';
    }
    chatProvider.updateDataFirestore(
      FirestoreConstants.pathUserCollection,
      currentUserId,
      {FirestoreConstants.chattingWith: peerId},
    );
  }

  void getSticker() {
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  void _modalBottomSheetMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Padding(
          padding: const EdgeInsets.all(AyurezeTheme.spaceXl),
          child: Container(
            height: 150,
            width: 200,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AyurezeTheme.radiusXl),
                color: AyurezeTheme.surface),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AyurezeTheme.spaceXl, AyurezeTheme.spaceXs, 0, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      getImageCamera();
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.06,
                      color: AyurezeTheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AyurezeTheme.spaceXl, 0, 0, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            getTranslated(
                                    context, AppString.choose_image_camera)
                                .toString(),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AyurezeTheme.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      getImageGallery();
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.06,
                      color: AyurezeTheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AyurezeTheme.spaceXl, 0, 0, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            getTranslated(
                                    context, AppString.choose_image_gallery)
                                .toString(),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AyurezeTheme.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onSendMessage(String content, int type) {
    if (content.trim().isNotEmpty) {
      textEditingController.clear();
      chatProvider.sendMessage(
          content, type, groupChatId, currentUserId, peerId);
      chatProvider.sendNotification(
          content, widget.token, currentUserId, type, peerAvatar, peerNickname);
      listScrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      OslerToast.warning(
          context, getTranslated(context, AppString.nothing_send).toString());
    }
  }

  Widget buildItem(int index, DocumentSnapshot? document) {
    if (document != null) {
      MessageChat messageChat = MessageChat.fromDocument(document);
      if (messageChat.idFrom == currentUserId) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            messageChat.type == TypeMessage.text
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AyurezeTheme.spaceLg,
                        vertical: AyurezeTheme.spaceMd),
                    width: 200,
                    decoration: BoxDecoration(
                        color: AyurezeTheme.border,
                        borderRadius:
                            BorderRadius.circular(AyurezeTheme.radiusSm)),
                    margin: EdgeInsets.only(
                        bottom: isLastMessageRight(index) ? 20 : 10, right: 10),
                    child: Text(
                      messageChat.content,
                      style: TextStyle(color: AyurezeTheme.textPrimary),
                    ),
                  )
                : messageChat.type == TypeMessage.image
                    ? Container(
                        margin: EdgeInsets.only(
                            bottom: isLastMessageRight(index) ? 20 : 10,
                            right: 10),
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullPhotoPage(
                                  url: messageChat.content,
                                ),
                              ),
                            );
                          },
                          style: ButtonStyle(
                              padding: WidgetStateProperty.all<EdgeInsets>(
                                  EdgeInsets.zero)),
                          child: Material(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8)),
                            clipBehavior: Clip.hardEdge,
                            child: Image.network(
                              messageChat.content,
                              loadingBuilder: (BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  decoration: BoxDecoration(
                                    color: AyurezeTheme.border,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                  width: 200,
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: AyurezeTheme.healingGreen50,
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                      null &&
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, object, stackTrace) {
                                return Material(
                                  child: Image.asset(
                                    'images/img_not_available.jpeg',
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                );
                              },
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                    // Sticker
                    : Container(
                        margin: EdgeInsets.only(
                            bottom: isLastMessageRight(index) ? 20 : 10,
                            right: 10),
                        child: Image.asset(
                          'images/${messageChat.content}.gif',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
          ],
        );
      } else {
        return Container(
          margin: const EdgeInsets.only(bottom: AyurezeTheme.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  isLastMessageLeft(index)
                      ? Material(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(18),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Image.network(
                            peerAvatar,
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  color: AyurezeTheme.healingGreen50,
                                  value: loadingProgress.expectedTotalBytes !=
                                              null &&
                                          loadingProgress.expectedTotalBytes !=
                                              null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, object, stackTrace) {
                              return HugeIcon(
                                icon: HugeIcons.strokeRoundedUserCircle,
                                size: 35,
                                color: AyurezeTheme.textSecondary,
                              );
                            },
                            width: 35,
                            height: 35,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(width: 35),
                  messageChat.type == TypeMessage.text
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AyurezeTheme.spaceLg,
                              vertical: AyurezeTheme.spaceMd),
                          width: 200,
                          decoration: BoxDecoration(
                              color: AyurezeTheme.forestDeep,
                              borderRadius:
                                  BorderRadius.circular(AyurezeTheme.radiusSm)),
                          margin:
                              const EdgeInsets.only(left: AyurezeTheme.spaceMd),
                          child: Text(
                            messageChat.content,
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : messageChat.type == TypeMessage.image
                          ? Container(
                              margin: const EdgeInsets.only(
                                  left: AyurezeTheme.spaceMd),
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FullPhotoPage(
                                          url: messageChat.content),
                                    ),
                                  );
                                },
                                style: ButtonStyle(
                                    padding:
                                        WidgetStateProperty.all<EdgeInsets>(
                                            EdgeInsets.zero)),
                                child: Material(
                                  child: Image.network(
                                    messageChat.content,
                                    loadingBuilder: (BuildContext context,
                                        Widget child,
                                        ImageChunkEvent? loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: AyurezeTheme.border,
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(8),
                                          ),
                                        ),
                                        width: 200,
                                        height: 200,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: AyurezeTheme.healingGreen50,
                                            value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null &&
                                                    loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder:
                                        (context, object, stackTrace) =>
                                            Material(
                                      child: Image.asset(
                                        'images/img_not_available.jpeg',
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                    ),
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(8)),
                                  clipBehavior: Clip.hardEdge,
                                ),
                              ),
                            )
                          : Container(
                              margin: EdgeInsets.only(
                                  bottom: isLastMessageRight(index) ? 20 : 10,
                                  right: 10),
                              child: Image.asset(
                                'images/${messageChat.content}.gif',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                ],
              ),
              isLastMessageLeft(index) &&
                      safeIntOrNull(messageChat.timestamp) != null
                  ? Container(
                      margin: const EdgeInsets.only(
                          left: AyurezeTheme.space3xl + AyurezeTheme.spaceLg,
                          top: AyurezeTheme.spaceXs,
                          bottom: AyurezeTheme.spaceXs),
                      child: Text(
                        DateFormat('dd MMM kk:mm').format(
                            DateTime.fromMillisecondsSinceEpoch(
                                safeIntOrNull(messageChat.timestamp)!)),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AyurezeTheme.textSecondary,
                            fontStyle: FontStyle.italic),
                      ),
                    )
                  : const SizedBox.shrink()
            ],
          ),
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 &&
            listMessage[index - 1].get(FirestoreConstants.idFrom) ==
                currentUserId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
            listMessage[index - 1].get(FirestoreConstants.idFrom) !=
                currentUserId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  void _handlePop(bool didPop, dynamic result) {
    if (didPop) return;
    if (widget.isNavigate == 'chatHome') {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => LoginHomeScreen(
                    chat: "chat",
                  )));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AyurezeTheme.border,
        title: Text(
          peerNickname,
          style: TextStyle(color: AyurezeTheme.textPrimary),
        ),
        centerTitle: true,
        leading: InkWell(
            onTap: () {
              if (widget.isNavigate == 'chatHome') {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LoginHomeScreen(chat: "chat")));
              }
            },
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: AyurezeTheme.textPrimary,
            )),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: _handlePop,
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                buildListMessage(),
                buildInput(),
              ],
            ),
            buildLoading()
          ],
        ),
      ),
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? const OslerOverlayLoader(message: 'Loading workspace...')
          : const SizedBox.shrink(),
    );
  }

  Widget buildInput() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
          border:
              Border(top: BorderSide(color: AyurezeTheme.border, width: 0.5)),
          color: AyurezeTheme.surface),
      child: Row(
        children: <Widget>[
          Material(
            color: AyurezeTheme.surface,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                icon: HugeIcon(icon: AppIcons.image),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _modalBottomSheetMenu();
                },
                color: AyurezeTheme.iconPrimary,
              ),
            ),
          ),
          Flexible(
            child: TextField(
              onSubmitted: (value) {
                onSendMessage(textEditingController.text, TypeMessage.text);
              },
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AyurezeTheme.textPrimary),
              controller: textEditingController,
              decoration: InputDecoration.collapsed(
                hintText:
                    getTranslated(context, AppString.type_message).toString(),
                hintStyle: TextStyle(color: AyurezeTheme.textSecondary),
              ),
              focusNode: focusNode,
            ),
          ),
          Material(
            color: AyurezeTheme.surface,
            child: Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: AyurezeTheme.spaceSm),
              child: IconButton(
                icon: HugeIcon(icon: AppIcons.send),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onSendMessage(textEditingController.text, TypeMessage.text);
                },
                color: AyurezeTheme.iconPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId.isNotEmpty
          ? StreamBuilder<QuerySnapshot>(
              stream: chatProvider.getChatStream(groupChatId, _limit),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  listMessage = snapshot.data!.docs;

                  if (listMessage.isNotEmpty) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(AyurezeTheme.spaceMd),
                      itemBuilder: (context, index) =>
                          buildItem(index, snapshot.data?.docs[index]),
                      itemCount: snapshot.data?.docs.length,
                      reverse: true,
                      controller: listScrollController,
                    );
                  } else {
                    return ScreenEntrance(
                      child: OslerStateView(
                        icon: HugeIcons.strokeRoundedMessage01,
                        title: getTranslated(context, AppString.no_message)
                            .toString(),
                      ),
                    );
                  }
                } else {
                  return const OslerLoadingView();
                }
              },
            )
          : const OslerLoadingView(),
    );
  }

  Future getImageGallery() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile;

    // pickedFile = await imagePicker.getImage(source: ImageSource.gallery);
    pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (pickedFile != null) {
      galleryImageFile = File(pickedFile.path);
      if (galleryImageFile != null) {
        setState(() {
          isLoading = true;
        });
        uploadFileFromGallery();
      }
    }
  }

  Future getImageCamera() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFileForCamera;

    // pickedFileForCamera = await imagePicker.getImage(source: ImageSource.camera);
    pickedFileForCamera =
        await imagePicker.pickImage(source: ImageSource.camera);
    if (!mounted) return;
    if (pickedFileForCamera != null) {
      cameraImageFile = File(pickedFileForCamera.path);
      if (cameraImageFile != null) {
        setState(() {
          isLoading = true;
        });
        uploadFileFromCamera();
      }
    }
  }

  Future uploadFileFromGallery() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    UploadTask uploadTask =
        chatProvider.uploadFile(galleryImageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrlGallery = await snapshot.ref.getDownloadURL();
      if (!mounted) return;
      setState(() {
        isLoading = false;
        onSendMessage(imageUrlGallery, TypeMessage.image);
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      OslerToast.error(context, e.message ?? e.toString());
    }
  }

  Future uploadFileFromCamera() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    UploadTask uploadTask = chatProvider.uploadFile(cameraImageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrlCamera = await snapshot.ref.getDownloadURL();
      if (!mounted) return;
      setState(() {
        isLoading = false;
        onSendMessage(imageUrlCamera, TypeMessage.image);
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      OslerToast.error(context, e.message ?? e.toString());
    }
  }
}
