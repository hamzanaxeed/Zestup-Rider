class OrdersResponse {
  final List<Order> orders;
  final int total;
  final int offset;
  final int limit;

  OrdersResponse({
    required this.orders,
    required this.total,
    required this.offset,
    required this.limit,
  });

  factory OrdersResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return OrdersResponse(
      orders: (data['orders'] as List<dynamic>? ?? [])
          .map((e) => Order.fromJson(e))
          .toList(),
      total: data['total'] ?? 0,
      offset: data['offset'] ?? 0,
      limit: data['limit'] ?? 0,
    );
  }
}

class Order {
  final String id;
  final int? displayId;
  final String? displayIdMetadata;
  final String? customerId;
  final String? type;
  final num? total;
  final String? status;
  final String? addressId;
  final String? riderId;
  final String? deliveryPhone;
  final String? deliveryAddress;
  final List<OrderItem> items;
  final int? itemsCount;
  final String? createdAt;

  Order({
    required this.id,
    this.displayId,
    this.displayIdMetadata,
    this.customerId,
    this.type,
    this.total,
    this.status,
    this.addressId,
    this.riderId,
    this.deliveryPhone,
    this.deliveryAddress,
    required this.items,
    this.itemsCount,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      displayId: json['displayId'],
      displayIdMetadata: json['displayIdMetadata'],
      customerId: json['customerId'],
      type: json['type'],
      total: json['total'],
      status: json['status'],
      addressId: json['addressId'],
      riderId: json['riderId'],
      deliveryPhone: json['deliveryPhone'],
      deliveryAddress: json['deliveryAddress'],
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromJson(e))
          .toList(),
      itemsCount: json['itemsCount'],
      createdAt: json['createdAt'],
    );
  }
}

class OrderItem {
  final String id;
  final num? price;
  final Variant? variant;
  final String? createdAt;
  final String? updatedAt;

  OrderItem({
    required this.id,
    this.price,
    this.variant,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      price: json['price'],
      variant: json['variant'] != null ? Variant.fromJson(json['variant']) : null,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}

class Variant {
  final String id;
  final String? name;
  final List<dynamic>? addons;
  final List<dynamic>? extras;
  final String? itemName;
  final int? quantity;
  final num? basePrice;
  final String? itemImage;
  final String? description;

  Variant({
    required this.id,
    this.name,
    this.addons,
    this.extras,
    this.itemName,
    this.quantity,
    this.basePrice,
    this.itemImage,
    this.description,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: json['id'],
      name: json['name'],
      addons: json['addons'],
      extras: json['extras'],
      itemName: json['itemName'],
      quantity: json['quantity'],
      basePrice: json['basePrice'],
      itemImage: json['itemImage'],
      description: json['description'],
    );
  }
}

