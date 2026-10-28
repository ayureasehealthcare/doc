import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/constants/pref_constant.dart';
import 'package:doctro/services/astra_api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

/// Finds the doctor id astra's `api/doctors/{id}` actually knows.
///
/// Sign-in stores the id from astra's session `user`, which can be the
/// Firebase account id rather than the doctor record's id; astra then
/// answers "Doctor not found" (404) and the profile can't load. Doctor
/// records are also kept in Supabase's `doctors` table (keyed by
/// `unique_id`, e.g. DOC-2026-AB12), so the candidates are the stored id,
/// the Firebase uid and that row's ids, tried in order against astra.
class DoctorIdResolver {
  DoctorIdResolver._();

  /// The first candidate [exists] confirms, or null if none does. Errors
  /// other than "not found" (no network, server down) propagate.
  static Future<String?> resolve(
    Iterable<String?> candidates,
    Future<bool> Function(String id) exists,
  ) async {
    final seen = <String>{};
    for (final raw in candidates) {
      final id = raw?.trim();
      if (id == null || id.isEmpty || id == 'N_A' || !seen.add(id)) continue;
      if (await exists(id)) return id;
    }
    return null;
  }

  static Future<bool> _astraKnows(String id) async {
    try {
      await AstraApiService().getDoctorProfile(id);
      return true;
    } on AstraApiException catch (e) {
      if (e.statusCode == 404) return false;
      rethrow;
    }
  }

  /// The signed-in doctor's row in Supabase's `doctors` table, by email.
  static Future<Map<String, dynamic>?> _supabaseRow() async {
    try {
      final email = FirebaseAuth.instance.currentUser?.email ??
          SharedPreferenceHelper.getStringOrNull(Preferences.email);
      if (email == null || email.isEmpty) return null;
      return await Supabase.instance.client
          .from('doctors')
          .select()
          .eq('email', email)
          .maybeSingle();
    } catch (e) {
      debugPrint('Supabase doctor lookup failed: $e');
      return null;
    }
  }

  /// Resolves and stores the doctor id; returns it, or null when astra has
  /// no record for this doctor under any known id.
  static Future<String?> ensure() async {
    final stored = SharedPreferenceHelper.getStringOrNull(Preferences.doctorId);
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      // Firebase not initialised (tests); the other candidates still apply.
    }
    final row = await _supabaseRow();
    final found = await resolve([
      stored,
      row?['doctor_id']?.toString(),
      row?['id']?.toString(),
      row?['unique_id']?.toString(),
      SharedPreferenceHelper.getStringOrNull(Preferences.uniqueId),
      uid,
    ], _astraKnows);
    if (found != null && found != stored) {
      await SharedPreferenceHelper.setString(Preferences.doctorId, found);
    }
    return found;
  }
}
