class Country {
  const Country(this.name, this.dialCode);
  final String name;
  final String dialCode;
  @override
  String toString() => '$name ($dialCode)';
}

/// Target markets from the BookMe East Africa proposal.
const supportedCountries = <Country>[
  Country('Rwanda', '+250'),
  Country('Uganda', '+256'),
  Country('Kenya', '+254'),
  Country('Tanzania', '+255'),
  Country('South Sudan', '+211'),
  Country('Burundi', '+257'),
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
