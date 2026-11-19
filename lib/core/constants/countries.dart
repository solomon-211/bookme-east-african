class Country {
  const Country(this.name, this.dialCode, this.flag);
  final String name;
  final String dialCode;
  final String flag; // emoji flag
  @override
  String toString() => '$name ($dialCode)';
}

/// Phone sign-in is limited to these East African countries.
/// The first entry is the default selection.
const supportedCountries = <Country>[
  Country('Rwanda', '+250', '\u{1F1F7}\u{1F1FC}'),
  Country('Uganda', '+256', '\u{1F1FA}\u{1F1EC}'),
  Country('Kenya', '+254', '\u{1F1F0}\u{1F1EA}'),
  Country('Tanzania', '+255', '\u{1F1F9}\u{1F1FF}'),
  Country('South Sudan', '+211', '\u{1F1F8}\u{1F1F8}'),
  Country('Burundi', '+257', '\u{1F1E7}\u{1F1EE}'),
];

/// Cities served by the demo data.
const supportedCities = <String>[
  'Kigali',
  'Kampala',
  'Nairobi',
  'Bujumbura',
];

/// Payment methods (key stored in Firestore -> label shown in the UI).
const paymentMethods = <String, String>{
  'mtn_momo': 'MTN Mobile Money',
  'airtel_money': 'Airtel Money',
  'mpesa': 'M-Pesa',
};
