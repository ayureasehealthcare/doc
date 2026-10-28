import 'package:firebase_auth/firebase_auth.dart';
import 'package:doctro/models/forgot_password.dart';
import 'package:doctro/network/base_model.dart';
import 'package:doctro/network/server_error.dart';
import 'package:doctro/widgets/osler_toast.dart';
import 'package:flutter/material.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  final TextEditingController _emailController = TextEditingController();
  TextEditingController get emailController => _emailController;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GlobalKey<FormState> get formKey => _formKey;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final String _msg = "";
  String get msg => _msg;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<BaseModel<ForgotPassword>> forgotPasswordScreenRequest(
      BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    ForgotPassword response;
    try {
      // Doctors' passwords live in Firebase Auth (email sign-in goes through
      // it first). The old forgot_password route 404s on astra.
      try {
        await FirebaseAuth.instance
            .sendPasswordResetEmail(email: _emailController.text.trim());
        response = ForgotPassword(
            success: true,
            msg: "We've sent a password reset link to your email.");
      } on FirebaseAuthException catch (e) {
        response = ForgotPassword(
            success: false,
            msg: switch (e.code) {
              'invalid-email' => "That email address doesn't look right.",
              'user-not-found' => "There's no account with that email.",
              _ => "Couldn't send the reset email. Please try again.",
            });
      }

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        if (response.success == true) {
          Navigator.pushReplacementNamed(context, "SignIn");
          if (response.msg != null && response.msg!.isNotEmpty) {
            OslerToast.success(context, response.msg!);
          }
        } else {
          if (response.msg != null && response.msg!.isNotEmpty) {
            OslerToast.error(context, response.msg!);
          }
        }
      }
      return BaseModel()..data = response;
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return BaseModel()..setException(ServerError.withError(error: error));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
