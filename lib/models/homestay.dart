class Homestay {
  final int id;
  final String name;
  final String state;
  final String district;
  final String price;
  final String description;
  final String imageUrl;

  Homestay({
    required this.id,
    required this.name,
    required this.state,
    required this.district,
    required this.price,
    required this.description,
    required this.imageUrl,
  });

  factory Homestay.fromJson(Map<String, dynamic> json) {
    return Homestay(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? 'No name',
      state: json['state']?.toString() ?? 'No state',
      district: json['district']?.toString() ?? 'No district',
      price:
          json['price_min']?.toString() ??
          json['price']?.toString() ??
          json['rate']?.toString() ??
          json['rental']?.toString() ??
          'No price',
      description:
          json['description']?.toString() ??
          json['details']?.toString() ??
          'No description',
      imageUrl: json['image_url']?.toString() ?? '',
    );
  }
}
