class StoreInfo {
  final String name;
  final String phone;
  final String address;

  const StoreInfo({
    required this.name,
    required this.phone,
    required this.address,
  });

  // Factory constructor from JSON
  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    return StoreInfo(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
    };
  }

  // Default store info for new installations
  static const StoreInfo defaultStore = StoreInfo(
    name: 'My Salon',
    phone: '',
    address: '',
  );

  // Create a copy with updated values
  StoreInfo copyWith({
    String? name,
    String? phone,
    String? address,
  }) {
    return StoreInfo(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StoreInfo &&
        other.name == name &&
        other.phone == phone &&
        other.address == address;
  }

  @override
  int get hashCode => Object.hash(name, phone, address);
}