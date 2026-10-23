import 'dart:async';
import 'package:hugeicons/hugeicons.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctro/features/consultation/chat/constants/firestore_constants.dart';
import 'package:doctro/features/consultation/chat/providers/auth_provider.dart';
import 'package:doctro/features/consultation/chat/providers/home_provider.dart';
import 'package:doctro/features/consultation/chat/utils/debouncer.dart';
import 'package:doctro/features/consultation/chat/utils/utilities.dart';
import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/theme/app_motion.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/osler_card.dart';
import 'package:doctro/widgets/osler_loader.dart';
import 'package:doctro/widgets/osler_state_view.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/features/dashboard/login_home.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'pages.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  HomePageState({Key? key});

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController listScrollController = ScrollController();

  late Future<SharedPreferences> prefs = SharedPreferences.getInstance();

  var lastMessage;

  int _limit = 20;
  final int _limitIncrement = 20;

  bool isLoading = false;

  late AuthProvider authProvider;
  String? currentUserId;
  late HomeProvider homeProvider;
  Debouncer searchDebouncer = Debouncer(milliseconds: 300);
  StreamController<bool> btnClearController = StreamController<bool>();

  String data = '';

  @override
  void initState() {
    super.initState();

    authProvider = context.read<AuthProvider>();
    homeProvider = context.read<HomeProvider>();

    if (authProvider.getUserFirebaseId()?.isNotEmpty == true) {
      currentUserId = authProvider.getUserFirebaseId()!;
    }

    listScrollController.addListener(scrollListener);
  }

  @override
  void dispose() {
    listScrollController.removeListener(scrollListener);
    listScrollController.dispose();
    btnClearController.close();
    super.dispose();
  }

  void scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void onBackPress(bool didPop, dynamic result) {
    if (didPop) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => LoginHomeScreen(chat: "")));
  }

  Future<void> handleSignOut() async {
    authProvider.handleSignOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 40,
        elevation: 1,
        leading: InkWell(
            onTap: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LoginHomeScreen(chat: "")));
            },
            child: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01)),
        backgroundColor: AyurezeTheme.surface,
        title: Text(
          getTranslated(context, AppString.chats).toString(),
          style: TextStyle(color: AyurezeTheme.textPrimary),
        ),
        centerTitle: true,
        foregroundColor: AyurezeTheme.textPrimary,
      ),
      body: Container(
        color: AyurezeTheme.canvas,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: onBackPress,
          child: Stack(
            children: <Widget>[
              Column(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: homeProvider.getStreamFireStore(
                          FirestoreConstants.pathUserCollection, _limit),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasData) {
                          if ((snapshot.data?.docs.length ?? 0) > 0) {
                            return ListView.builder(
                              padding:
                                  const EdgeInsets.all(AyurezeTheme.spaceMd),
                              itemBuilder: (context, index) => buildItem(
                                  context,
                                  snapshot.data?.docs[index],
                                  index % 8),
                              itemCount: snapshot.data?.docs.length,
                              controller: listScrollController,
                            );
                          } else {
                            return OslerStateView(
                              icon: HugeIcons.strokeRoundedUserGroup,
                              title: getTranslated(context, AppString.no_user)
                                  .toString(),
                            );
                          }
                        } else {
                          return const OslerLoadingView();
                        }
                      },
                    ),
                  ),
                ],
              ),
              Positioned(
                child: isLoading
                    ? const OslerOverlayLoader(message: 'Loading workspace...')
                    : const SizedBox.shrink(),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildItem(
      BuildContext context, DocumentSnapshot? document, int index) {
    if (document != null) {
      UserChat userChat = UserChat.fromDocument(document);
      if (currentUserId == null && userChat.id == currentUserId) {
        return const SizedBox.shrink();
      } else {
        final item = OslerCard(
          margin: const EdgeInsets.only(
              bottom: AyurezeTheme.spaceMd,
              left: AyurezeTheme.spaceXs,
              right: AyurezeTheme.spaceXs),
          padding: const EdgeInsets.all(AyurezeTheme.spaceMd),
          backgroundColor: AyurezeTheme.surfaceMuted,
          // OslerCard adds the press scale and haptic tick itself.
          onTap: () {
            if (Utilities.isKeyboardShowing()) {
              Utilities.closeKeyboard(context);
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  peerId: userChat.id,
                  peerAvatar: userChat.photoUrl,
                  peerNickname: userChat.nickname,
                  token: userChat.token,
                  isNavigate: 'chatHome',
                ),
              ),
            );
          },
          child: Row(
            children: <Widget>[
              Material(
                borderRadius: const BorderRadius.all(
                    Radius.circular(AyurezeTheme.radiusPill)),
                clipBehavior: Clip.hardEdge,
                child: userChat.photoUrl.isNotEmpty
                    ? Image.network(
                        userChat.photoUrl,
                        fit: BoxFit.cover,
                        width: 50,
                        height: 50,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            width: 50,
                            height: 50,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AyurezeTheme.healingGreenFill,
                                value: loadingProgress.expectedTotalBytes !=
                                            null &&
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, object, stackTrace) {
                          return HugeIcon(
                            icon: HugeIcons.strokeRoundedUserCircle,
                            size: 50,
                            color: AyurezeTheme.textSecondary,
                          );
                        },
                      )
                    : HugeIcon(
                        icon: HugeIcons.strokeRoundedUserCircle,
                        size: 50,
                        color: AyurezeTheme.textSecondary,
                      ),
              ),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.only(left: AyurezeTheme.spaceXl),
                  child: Column(
                    children: <Widget>[
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.fromLTRB(
                            AyurezeTheme.spaceMd, 0, 0, AyurezeTheme.spaceXs),
                        child: Text(
                          userChat.nickname,
                          maxLines: 1,
                          style: TextStyle(color: AyurezeTheme.textPrimary),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.fromLTRB(
                            AyurezeTheme.spaceMd, 0, 0, 0),
                        child: Text(
                          userChat.content,
                          maxLines: 1,
                          style: TextStyle(color: AyurezeTheme.textPrimary),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        return ScreenEntrance(index: index, child: item);
      }
    } else {
      return const SizedBox.shrink();
    }
  }
}
