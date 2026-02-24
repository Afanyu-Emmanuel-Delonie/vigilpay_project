import '../entities/product_entity.dart';
import '../repositories/products_repository.dart';

class FetchProductsUseCase {
  FetchProductsUseCase(this._repository);

  final ProductsRepository _repository;

  Future<List<ProductEntity>> call() {
    return _repository.fetchProducts();
  }
}
