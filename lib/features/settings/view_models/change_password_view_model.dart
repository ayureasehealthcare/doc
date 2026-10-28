import 'package:flutter/material.dart';
import 'package:doctro/models/change_password.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordViewModel extends ChangeNotifier {
  bool isLoading = false;
  bool isHidden = true;
  bool isHidden1 = true;
  bool isHidden2 = true;

  void togglePasswordVisibility() {
    isHidden = !isHidden;
    notifyListeners();
  }

  void toggleNewPasswordVisibility() {
    isHidden1 = !isHidden1;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    isHidden2 = !isHidden2;
    notifyListeners();
  }

  Future<ChangePasswordModel?> passwordChange(BuildContext context,
      String oldPassword, String newPassword, String confirmPassword) async {
    isLoading = true;
    notifyListeners();

    // Doctors' passwords live in Firebase Auth; the old
    // doctor_change_password route 404s on astra. Firebase needs a recent
    // sign-in to change a password, so re-authenticate with the old one.
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    try {
      if (user == null || email == null) {
        return ChangePasswordModel(
            success: false,
            data: "Please sign in again before changing your password.");
      }
      if (newPassword != confirmPassword) {
        return ChangePasswordModel(
            success: false, data: "The new passwords don't match.");
      }
      if (!user.providerData.any((p) => p.providerId == 'password')) {
        return ChangePasswordModel(
            success: false,
            data: "This account signs in with Google, so it has no password "
                "to change.");
      }
      await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: oldPassword));
      await user.updatePassword(newPassword);
      return ChangePasswordModel(
          success: true, data: "Your password has been changed.");
    } on FirebaseAuthException catch (e) {
      return ChangePasswordModel(
          success: false,
          data: switch (e.code) {
            'wrong-password' ||
            'invalid-credential' =>
              "Your current password is incorrect.",
            'weak-password' => "Choose a stronger new password.",
            _ => "Couldn't change your password. Please try again.",
          });
    } catch (_) {
      return ChangePasswordModel(
          success: false,
          data: "Couldn't change your password. Please try again.");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
