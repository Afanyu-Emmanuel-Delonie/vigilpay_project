import 'package:flutter/foundation.dart';

import '../../../../core/utils/request_state.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/fetch_products_usecase.dart';

class ProductsController extends ChangeNotifier {
  ProductsController({required FetchProductsUseCase fetchProductsUseCase})
      : _fetchProductsUseCase = fetchProductsUseCase;

  final FetchProductsUseCase _fetchProductsUseCase;

  RequestState _state = RequestState.idle;
  String? _errorMessage;
  List<ProductEntity> _products = const [];

  RequestState get state => _state;
  String? get errorMessage => _errorMessage;
  List<ProductEntity> get products => _products;

  Future<void> loadProducts() async {
    _state = RequestState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _fetchProductsUseCase();
      _state = RequestState.success;
    } catch (error) {
      _state = RequestState.error;
      _errorMessage = error.toString();
    }

    notifyListeners();
  }
}
