import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/booking/domain/entities/payment_method.dart';
import 'package:bookme_summative_project/features/booking/domain/repositories/payment_repository.dart';

/// Remembers the last payment method and phone number on the device, so the
/// Pay screen is pre-filled after the app is closed and opened again.
class PaymentPreferencesDataSource {
  PaymentPreferencesDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const String methodKey = 'payment.lastMethod';
  static const String phoneKey = 'payment.lastPhone';

  PaymentPreference? load() {
    final method = _prefs.getString(methodKey);
    if (method == null) return null;
    return PaymentPreference(
      method: PaymentMethod.fromName(method),
      phone: _prefs.getString(phoneKey) ?? '',
    );
  }

  Future<void> save(PaymentMethod method, String phone) async {
    await _prefs.setString(methodKey, method.name);
    await _prefs.setString(phoneKey, phone);
  }
}
