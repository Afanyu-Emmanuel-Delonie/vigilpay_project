import '../../../../core/constants/endpoint_constants.dart';
import '../../../../core/network/api_client.dart';

class ProductsGateway {
  ProductsGateway({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetchProducts() {
    return _apiClient.get(EndpointConstants.products);
  }
}
