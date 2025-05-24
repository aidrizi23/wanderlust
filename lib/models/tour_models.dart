class Tour {
  final int id;
  final String name;
  final String description;
  final double price;
  final int durationInDays;
  final String location;
  final String difficultyLevel;
  final String activityType;
  final String category;
  final int maxGroupSize;
  final String? mainImageUrl;
  final bool isActive;
  final DateTime createdAt;
  final List<TourImage> images;
  final List<TourFeature> features;
  final List<ItineraryItem> itineraryItems;
  final double? averageRating;
  final int? reviewCount;
  final double? discountedPrice;
  final int? discountPercentage;

  Tour({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationInDays,
    required this.location,
    required this.difficultyLevel,
    required this.activityType,
    required this.category,
    required this.maxGroupSize,
    this.mainImageUrl,
    required this.isActive,
    required this.createdAt,
    required this.images,
    required this.features,
    required this.itineraryItems,
    this.averageRating,
    this.reviewCount,
    this.discountedPrice,
    this.discountPercentage,
  });

  factory Tour.fromJson(Map<String, dynamic> json) => Tour(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    price: json['price'].toDouble(),
    durationInDays: json['durationInDays'],
    location: json['location'],
    difficultyLevel: json['difficultyLevel'],
    activityType: json['activityType'],
    category: json['category'],
    maxGroupSize: json['maxGroupSize'],
    mainImageUrl: json['mainImageUrl'],
    isActive: json['isActive'],
    createdAt: DateTime.parse(json['createdAt']),
    images: (json['images'] as List).map((e) => TourImage.fromJson(e)).toList(),
    features:
        (json['features'] as List).map((e) => TourFeature.fromJson(e)).toList(),
    itineraryItems:
        (json['itineraryItems'] as List)
            .map((e) => ItineraryItem.fromJson(e))
            .toList(),
    averageRating: json['averageRating']?.toDouble(),
    reviewCount: json['reviewCount'],
    discountedPrice: json['discountedPrice']?.toDouble(),
    discountPercentage: json['discountPercentage'],
  );

  double get displayPrice => discountedPrice ?? price;
  bool get hasDiscount => discountedPrice != null && discountedPrice! < price;
}

class TourImage {
  final int id;
  final String imageUrl;
  final String? caption;
  final int displayOrder;

  TourImage({
    required this.id,
    required this.imageUrl,
    this.caption,
    required this.displayOrder,
  });

  factory TourImage.fromJson(Map<String, dynamic> json) => TourImage(
    id: json['id'],
    imageUrl: json['imageUrl'],
    caption: json['caption'],
    displayOrder: json['displayOrder'],
  );
}

class TourFeature {
  final int id;
  final String name;
  final String? description;

  TourFeature({required this.id, required this.name, this.description});

  factory TourFeature.fromJson(Map<String, dynamic> json) => TourFeature(
    id: json['id'],
    name: json['name'],
    description: json['description'],
  );
}

class ItineraryItem {
  final int id;
  final int dayNumber;
  final String title;
  final String description;
  final String? location;
  final String? startTime;
  final String? endTime;
  final String? activityType;

  ItineraryItem({
    required this.id,
    required this.dayNumber,
    required this.title,
    required this.description,
    this.location,
    this.startTime,
    this.endTime,
    this.activityType,
  });

  factory ItineraryItem.fromJson(Map<String, dynamic> json) => ItineraryItem(
    id: json['id'],
    dayNumber: json['dayNumber'],
    title: json['title'],
    description: json['description'],
    location: json['location'],
    startTime: json['startTime'],
    endTime: json['endTime'],
    activityType: json['activityType'],
  );
}

class TourListResponse {
  final List<Tour> items;
  final int pageIndex;
  final int totalPages;
  final int totalCount;
  final bool hasPreviousPage;
  final bool hasNextPage;

  TourListResponse({
    required this.items,
    required this.pageIndex,
    required this.totalPages,
    required this.totalCount,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory TourListResponse.fromJson(Map<String, dynamic> json) =>
      TourListResponse(
        items: (json['items'] as List).map((e) => Tour.fromJson(e)).toList(),
        pageIndex: json['pageIndex'],
        totalPages: json['totalPages'],
        totalCount: json['totalCount'],
        hasPreviousPage: json['hasPreviousPage'],
        hasNextPage: json['hasNextPage'],
      );
}
