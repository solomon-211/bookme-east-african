/// Ways a traveller can pay. The [name] of each value is what we store in
/// Firestore, so do not rename values without migrating data.
enum PaymentMethod {
  mtnMomo('MTN MoMo', 'Rwanda · Approve on your phone'),
  mpesa('M-Pesa', 'Kenya & Tanzania'),
  airtelMoney('Airtel Money', 'Rwanda, Uganda, Kenya & Tanzania'),
  card('Visa / Mastercard', 'Debit or credit card');

  const PaymentMethod(this.label, this.subtitle);

  final String label;
  final String subtitle;

  /// Mobile money needs a phone number to send the PIN prompt to.
  bool get needsPhone => this != PaymentMethod.card;

  static PaymentMethod fromName(String? name) => PaymentMethod.values
      .firstWhere((m) => m.name == name, orElse: () => PaymentMethod.mtnMomo);
}
