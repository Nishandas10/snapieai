import 'package:openfoodfacts/openfoodfacts.dart';

/// Service for barcode scanning and OpenFoodFacts API integration
class BarcodeService {
  static final BarcodeService _instance = BarcodeService._internal();
  factory BarcodeService() => _instance;
  BarcodeService._internal() {
    // Configure OpenFoodFacts
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'SnapieAI',
      version: '1.0.0',
      system: 'Flutter',
    );
    OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[
      OpenFoodFactsLanguage.ENGLISH,
    ];
    OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.USA;
  }

  /// Look up a product by barcode
  /// Returns product info (name, brand, image) or null if not found
  Future<BarcodeProductInfo?> lookupBarcode(String barcode) async {
    try {
      final ProductQueryConfiguration configuration = ProductQueryConfiguration(
        barcode,
        language: OpenFoodFactsLanguage.ENGLISH,
        fields: [
          ProductField.NAME,
          ProductField.BRANDS,
          ProductField.SERVING_SIZE,
          ProductField.IMAGE_FRONT_URL,
          ProductField.IMAGE_FRONT_SMALL_URL,
          ProductField.QUANTITY,
        ],
        version: ProductQueryVersion.v3,
      );

      final ProductResultV3 result = await OpenFoodAPIClient.getProductV3(
        configuration,
      );

      if (result.status == ProductResultV3.statusSuccess &&
          result.product != null) {
        final product = result.product!;

        // Build product name
        String productName = product.productName ?? 'Unknown Product';
        final brand = product.brands;

        // Get serving size
        final servingSize = product.servingSize ?? '1 serving';

        // Get product image URL
        final imageUrl = product.imageFrontUrl ?? product.imageFrontSmallUrl;

        return BarcodeProductInfo(
          barcode: barcode,
          productName: productName,
          brand: brand,
          servingSize: servingSize,
          imageUrl: imageUrl,
        );
      }

      return null;
    } catch (e) {
      // Network error or API error
      return null;
    }
  }
}

/// Data class to hold basic product info from barcode lookup
class BarcodeProductInfo {
  final String barcode;
  final String productName;
  final String? brand;
  final String servingSize;
  final String? imageUrl;

  BarcodeProductInfo({
    required this.barcode,
    required this.productName,
    this.brand,
    required this.servingSize,
    this.imageUrl,
  });

  /// Get full product name with brand
  String get fullName {
    if (brand != null && brand!.isNotEmpty) {
      return '$brand $productName';
    }
    return productName;
  }

  /// Get text description for AI analysis
  String get descriptionForAI {
    final parts = <String>[];
    parts.add(fullName);
    if (servingSize.isNotEmpty) {
      parts.add('($servingSize per serving)');
    }
    return parts.join(' ');
  }
}
