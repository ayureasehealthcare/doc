import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'package:provider/provider.dart';
import 'dart:io' show Platform;

import 'package:doctro/features/consultation/chat/providers/auth_provider.dart'
    as chat;
import 'package:doctro/core/constants/common_function.dart';
import 'package:doctro/core/constants/prefConstatnt.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/models/login.dart';
import 'package:doctro/network/api_header.dart';
import 'package:doctro/network/base_model.dart';
import 'package:doctro/network/network_api.dart';
import 'package:doctro/network/server_error.dart';
import 'package:doctro/services/astra_api_service.dart';
import 'package:doctro/models/setting.dart';
import 'package:doctro/widgets/osler_toast.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/features/authentication/signup.dart';

class SignInViewModel extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  bool isOtpLoginMode = false;
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController phoneCodeController =
      TextEditingController(text: "+91");
  final TextEditingController otpCodeController = TextEditingController();

  String? verificationId;
  bool otpSent = false;
  bool isHidden = true;

  String? deviceToken;
  int? verify;

  SignInViewModel({bool autoInitialize = true}) {
    if (!autoInitialize) {
      return;
    }
    if (!kIsWeb && Platform.isAndroid) {
      SharedPreferenceHelper.setString(Preferences.device_platform, "Android");
    }
    getToken();
    settingRequest();
  }

  void toggleOtpLoginMode(bool val) {
    isOtpLoginMode = val;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    isHidden = !isHidden;
    notifyListeners();
  }

  void updatePhoneCode(String code) {
    phoneCodeController.text = code;
    notifyListeners();
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    phoneController.dispose();
    phoneCodeController.dispose();
    otpCodeController.dispose();
    super.dispose();
  }

  Future<void> getToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        SharedPreferenceHelper.setString(Preferences.messageToken, token);
      }
    } catch (_) {
      // FCM token is optional; login must proceed without it.
    }
  }

  Future<void> sendOtp(BuildContext context) async {
    final phoneNum =
        phoneCodeController.text.trim() + phoneController.text.trim();
    if (phoneController.text.trim().isEmpty) {
      OslerToast.error(context, "Please enter a valid phone number");
      return;
    }

    try {
      CommonFunction.onLoading(context);
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNum,
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (!context.mounted) return;
          CommonFunction.hideDialog(context);
          await authenticateWithCredential(credential, context);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!context.mounted) return;
          CommonFunction.hideDialog(context);
          OslerToast.error(context, "Verification failed: ${e.message}");
        },
        codeSent: (String vId, int? resendToken) {
          if (!context.mounted) return;
          CommonFunction.hideDialog(context);
          verificationId = vId;
          otpSent = true;
          notifyListeners();
          OslerToast.success(context, "Verification Code Sent via SMS!");
        },
        codeAutoRetrievalTimeout: (String vId) {
          verificationId = vId;
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      CommonFunction.hideDialog(context);
      OslerToast.error(context, "Error: $e");
    }
  }

  Future<void> verifyOtpCode(BuildContext context) async {
    final smsCode = otpCodeController.text.trim();
    if (verificationId == null || smsCode.isEmpty) {
      OslerToast.error(context, "Please enter the OTP verification code");
      return;
    }

    try {
      CommonFunction.onLoading(context);
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: smsCode,
      );

      await authenticateWithCredential(credential, context);
    } catch (e) {
      if (!context.mounted) return;
      CommonFunction.hideDialog(context);
      OslerToast.error(context, "Invalid OTP Code: $e");
    }
  }

  Future<void> authenticateWithCredential(
      PhoneAuthCredential credential, BuildContext context) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;
      if (user != null) {
        String phoneNum = user.phoneNumber ?? "";
        if (phoneNum.isEmpty) {
          phoneNum =
              phoneCodeController.text.trim() + phoneController.text.trim();
        }

        String? doctorEmail = user.email;
        if (doctorEmail == null || doctorEmail.isEmpty) {
          try {
            final client = Supabase.instance.client;
            final res = await client
                .from('doctors')
                .select('email')
                .eq('phone', phoneNum)
                .maybeSingle();
            if (res != null && res['email'] != null) {
              doctorEmail = res['email'];
            }
          } catch (_) {
            // Supabase email lookup is an optional enrichment; Firebase may still resolve it.
          }
        }

        if (doctorEmail == null || doctorEmail.isEmpty) {
          try {
            final rawPhone = phoneController.text.trim();
            final client = Supabase.instance.client;
            final res = await client
                .from('doctors')
                .select('email')
                .eq('phone', rawPhone)
                .maybeSingle();
            if (res != null && res['email'] != null) {
              doctorEmail = res['email'];
            }
          } catch (_) {
            // Supabase email lookup is an optional enrichment; Firebase may still resolve it.
          }
        }

        if (doctorEmail != null && doctorEmail.isNotEmpty) {
          try {
            final astraData = await AstraApiService().login();
            final response = LoginResponse.fromJson({
              "success": astraData['success'] ?? true,
              "msg": "Login successful",
              "token": astraData['token'],
              "data": {
                "id": astraData['data']?['id']?.toString() ?? '',
                "name": astraData['data']?['name'] ?? '',
                "phone": astraData['data']?['phone'] ?? '',
                "email": astraData['data']?['email'] ?? '',
                "image": astraData['data']?['image'] ?? '',
                "fullImage": astraData['data']?['fullImage'] ?? '',
                "is_filled": astraData['data']?['is_filled'] ?? 1,
              }
            });
            if (!context.mounted) return;
            CommonFunction.hideDialog(context);

            if (response.success == true && response.data != null) {
              saveUserData(response, context);
              SharedPreferenceHelper.setBoolean(Preferences.is_logged_in, true);
              OslerToast.success(context, "Logged in successfully!");
              Navigator.pushNamedAndRemoveUntil(
                  context, 'loginHome', (route) => false);
            }
          } catch (e) {
            if (!context.mounted) return;
            OslerToast.error(
                context, "Astra backend login failed (Missing Endpoint / 404)");
          }
        } else {
          if (!context.mounted) return;
          CommonFunction.hideDialog(context);
          OslerToast.warning(
              context, "Phone number not registered. Please sign up.");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateAccount(
                prefillData: {
                  "phone": phoneController.text.trim(),
                  "phone_code": phoneCodeController.text.trim(),
                },
              ),
            ),
          );
        }
      } else {
        if (!context.mounted) return;
        CommonFunction.hideDialog(context);
        OslerToast.error(context, "Firebase authentication failed");
      }
    } catch (e) {
      if (!context.mounted) return;
      CommonFunction.hideDialog(context);
      OslerToast.error(context, "Authentication failed: $e");
    }
  }

  Future<void> handleGoogleSignIn(BuildContext context) async {
    final authProvider = Provider.of<chat.AuthProvider>(context, listen: false);
    User? user = await authProvider.signInWithGoogle();
    if (!context.mounted) return;
    if (user != null) {
      try {
        CommonFunction.onLoading(context);
        try {
          final astraData = await AstraApiService().login();
          final response = LoginResponse.fromJson({
            "success": astraData['success'] ?? true,
            "msg": "Login successful",
            "token": astraData['token'],
            "data": {
              "id": astraData['data']?['id']?.toString() ?? '',
              "name": astraData['data']?['name'] ?? '',
              "phone": astraData['data']?['phone'] ?? '',
              "email": astraData['data']?['email'] ?? '',
              "image": astraData['data']?['image'] ?? '',
              "fullImage": astraData['data']?['fullImage'] ?? '',
              "is_filled": astraData['data']?['is_filled'] ?? 1,
            }
          });

          if (!context.mounted) return;
          CommonFunction.hideDialog(context);

          if (response.success == true && response.data != null) {
            saveUserData(response, context);
            SharedPreferenceHelper.setBoolean(Preferences.is_logged_in, true);
            Navigator.pushNamedAndRemoveUntil(
                context, 'loginHome', (route) => false);
          }
        } catch (e) {
          if (!context.mounted) return;
          // If Astra login fails (e.g. 404), maybe user doesn't exist yet on Astra
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateAccount(
                prefillData: {
                  "name": user.displayName,
                  "email": user.email,
                },
              ),
            ),
          );
        }
      } catch (outerE) {
        if (!context.mounted) return;
        CommonFunction.hideDialog(context);
        OslerToast.error(context, outerE.toString());
      }
    } else {
      String errorText = "Google Sign In Failed or Canceled";
      if (authProvider.status == chat.Status.authenticateError) {
        errorText =
            "Google Sign In Error: Please ensure:\n1. Internet connection is active\n2. Google Play Services are installed\n3. Your Google account is properly configured";
      } else if (authProvider.status == chat.Status.authenticateCanceled) {
        errorText = "Google Sign In was canceled";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorText),
          backgroundColor: AyurezeTheme.remoteRed100,
        ),
      );
    }
  }

  void saveUserData(LoginResponse response, BuildContext context) {
    SharedPreferenceHelper.setString(
        Preferences.name, response.data!.name ?? '');
    SharedPreferenceHelper.setString(
        Preferences.phone_no, response.data!.phone ?? '');
    SharedPreferenceHelper.setString(
        Preferences.email, response.data!.email ?? '');
    SharedPreferenceHelper.setString(
        Preferences.image, response.data!.image ?? '');
    SharedPreferenceHelper.setInt(
        Preferences.is_filled, response.data!.isFilled ?? 0);

    if (response.token != null) {
      SharedPreferenceHelper.setString(Preferences.auth_token, response.token!);
    }
    if (response.refreshToken != null) {
      SharedPreferenceHelper.setString(
          Preferences.refresh_token, response.refreshToken!);
    }
    if (response.expiresIn != null) {
      SharedPreferenceHelper.setInt(
          Preferences.expiresIn, int.parse('${response.expiresIn}'));
      SharedPreferenceHelper.setInt(
          'token_saved_at', DateTime.now().millisecondsSinceEpoch);
    }
    // Removed subscriptionStatus parsing due to model cleanup
    SharedPreferenceHelper.setInt(Preferences.subscription_status, -1);
    SharedPreferenceHelper.setString(
        Preferences.chat_profile, response.data!.fullImage ?? '');
    SharedPreferenceHelper.setString(
        Preferences.user_name, response.data!.name ?? '');
    SharedPreferenceHelper.setString(
        Preferences.doctorId, response.data!.id.toString());

    Provider.of<chat.AuthProvider>(context, listen: false).handleSignIn();

    // Best-effort, same pattern as getToken(): push notifications are a
    // nice-to-have, never a login blocker. AstraApiService.storeFcmToken()
    // existed with no caller anywhere in this app before this; registering
    // it right after a successful login is the earliest point both the
    // Astra-issued doctorId and a cached FCM token are available together.
    _registerFcmToken();
  }

  Future<void> _registerFcmToken() async {
    try {
      final doctorId = SharedPreferenceHelper.getString(Preferences.doctorId);
      if (doctorId.isEmpty) return;

      String? token =
          SharedPreferenceHelper.getString(Preferences.messageToken);
      if (token.isEmpty) {
        token = await FirebaseMessaging.instance.getToken();
      }
      if (token == null || token.isEmpty) return;

      await AstraApiService().storeFcmToken(token, doctorId);
    } catch (e) {
      debugPrint('Astra FCM token registration failed (non-fatal): $e');
    }
  }

  Future<BaseModel<LoginResponse>> callApiForLogin(BuildContext context) async {
    SharedPreferenceHelper.setString(Preferences.user_email, email.text);

    LoginResponse response;

    try {
      CommonFunction.onLoading(context);

      // 1. Authenticate with Firebase FIRST (so Astra API can use the token)
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          try {
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email.text.trim(),
              password: password.text.trim(),
            );
          } catch (createErr) {
            if (!context.mounted) {
              return BaseModel()
                ..setException(ServerError.withError(error: createErr));
            }
            CommonFunction.hideDialog(context);
            OslerToast.error(context, "Firebase Registration Failed");
            return BaseModel()
              ..setException(ServerError.withError(error: createErr));
          }
        } else {
          if (!context.mounted) {
            return BaseModel()..setException(ServerError.withError(error: e));
          }
          CommonFunction.hideDialog(context);
          OslerToast.error(context, "Firebase Auth Error: ${e.code}");
          return BaseModel()..setException(ServerError.withError(error: e));
        }
      } catch (e) {
        if (!context.mounted) {
          return BaseModel()..setException(ServerError.withError(error: e));
        }
        CommonFunction.hideDialog(context);
        OslerToast.error(context, "Firebase Auth Error");
        return BaseModel()..setException(ServerError.withError(error: e));
      }

      // 2. Authenticate with Astra Backend (Automatically uses Firebase Bearer Token)
      final astraData = await AstraApiService().login();
      if (!context.mounted) {
        return BaseModel()
          ..setException(ServerError.withError(error: 'unmounted'));
      }
      CommonFunction.hideDialog(context);

      response = LoginResponse.fromJson({
        "success": astraData['success'] ?? true,
        "msg": "Login successful",
        "token": astraData['token'],
        "data": {
          "id": astraData['data']?['id']?.toString() ?? '',
          "name": astraData['data']?['name'] ?? '',
          "phone": astraData['data']?['phone'] ?? '',
          "email": astraData['data']?['email'] ?? '',
          "image": astraData['data']?['image'] ?? '',
          "fullImage": astraData['data']?['fullImage'] ?? '',
          "is_filled": astraData['data']?['is_filled'] ?? 1,
        }
      });

      if (response.success == true) {
        saveUserData(response, context);
        OslerToast.success(context, response.msg ?? "Logged in successfully!");

        SharedPreferenceHelper.setBoolean(Preferences.is_logged_in, true);
        Navigator.pushReplacementNamed(context, 'loginHome');
      } else {
        OslerToast.error(context, "Backend Login Failed");
      }
    } catch (error) {
      if (!context.mounted) {
        return BaseModel()..setException(ServerError.withError(error: error));
      }
      CommonFunction.hideDialog(context);
      // Fallback message for Missing Endpoint (404)
      OslerToast.error(context,
          "Failed to connect to Astra API (404/Missing Endpoint). Please ensure the backend route exists.");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<Setting>> settingRequest() async {
    Setting response;
    try {
      response = await RestClient(RetroApi2().dioData2()).settingRequest();

      if (SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true) {
        if (response.data!.stripeSecretKey != null) {
          SharedPreferenceHelper.setString(
              Preferences.stripeSecretKey, response.data!.stripeSecretKey!);
        }
        if (response.data!.stripePublicKey != null) {
          SharedPreferenceHelper.setString(
              Preferences.stripPublicKey, response.data!.stripePublicKey!);
        }
        if (response.data!.flutterwaveEncryptionKey != null) {
          SharedPreferenceHelper.setString(
              Preferences.flutterWave_encryption_key,
              response.data!.flutterwaveEncryptionKey!);
        }
        if (response.data!.flutterwaveKey != null) {
          SharedPreferenceHelper.setString(
              Preferences.flutterWave_key, response.data!.flutterwaveKey!);
        }
        if (response.data!.paystackPublicKey != null) {
          SharedPreferenceHelper.setString(Preferences.payStack_public_key,
              response.data!.paystackPublicKey!);
        }
        if (response.data!.razorKey != null) {
          SharedPreferenceHelper.setString(
              Preferences.razor_key, response.data!.razorKey!);
        }
        if (response.data!.paypalProducationKey != null) {
          SharedPreferenceHelper.setString(Preferences.payPal_production_key,
              response.data!.paypalProducationKey!);
        }
        if (response.data!.paypalSandboxKey != null) {
          SharedPreferenceHelper.setString(
              Preferences.payPal_sandbox_key, response.data!.paypalSandboxKey!);
        }
        if (response.data!.paypalClientId != null) {
          SharedPreferenceHelper.setString(
              Preferences.paypal_client_key, response.data!.paypalClientId!);
        }
        if (response.data!.paypalSecretKey != null) {
          SharedPreferenceHelper.setString(
              Preferences.paypal_secret_key, response.data!.paypalSecretKey!);
        }
        if (response.data!.currencySymbol != null) {
          SharedPreferenceHelper.setString(
              Preferences.currency_symbol, response.data!.currencySymbol!);
        }
        if (response.data!.currencyCode != null) {
          SharedPreferenceHelper.setString(
              Preferences.currency_code, response.data!.currencyCode!);
        }
        if (response.data!.doctorAppId != null) {
          SharedPreferenceHelper.setString(
              Preferences.doctorAppId, response.data!.doctorAppId!);
          notifyListeners();
        }
      } else {
        if (response.data!.currencySymbol != null) {
          SharedPreferenceHelper.setString(
              Preferences.currency_symbol, response.data!.currencySymbol!);
        }
        if (response.data!.currencyCode != null) {
          SharedPreferenceHelper.setString(
              Preferences.currency_code, response.data!.currencyCode!);
        }
        if (response.data!.doctorAppId != null) {
          SharedPreferenceHelper.setString(
              Preferences.doctorAppId, response.data!.doctorAppId!);
          notifyListeners();
        }
      }
    } catch (error) {
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }
}
