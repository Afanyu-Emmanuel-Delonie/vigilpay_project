import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/products_repository.dart';
import '../datasources/products_gateway.dart';
import '../models/product_model.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  ProductsRepositoryImpl({required ProductsGateway gateway}) : _gateway = gateway;

  final ProductsGateway _gateway;

  @override
  Future<List<ProductEntity>> fetchProducts() async {
    final response = await _gateway.fetchProducts();
    final rawList = response['results'] ?? response['data'] ?? const [];

    if (rawList is! List) {
      return const [];
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList(growable: false);
  }
}
