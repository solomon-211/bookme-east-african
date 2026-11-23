class Country {
  const Country(this.name, this.dialCode, this.code);
  final String name;
  final String dialCode;

  /// Two-letter code shown on the country chips, e.g. `RW`.
  final String code;
  @override
  String toString() => '$name ($dialCode)';
}

/// Target markets from the BookMe East Africa proposal.
const supportedCountries = <Country>[
  Country('Rwanda', '+250', 'RW'),
  Country('Uganda', '+256', 'UG'),
  Country('Kenya', '+254', 'KE'),
  Country('Tanzania', '+255', 'TZ'),
  Country('South Sudan', '+211', 'SS'),
  Country('Burundi', '+257', 'BI'),
];
