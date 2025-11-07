import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Define PriceUtils class
class PriceUtils {
  static String formatPrice(double price, {String currency = '\$'}) {
    return '$currency\${price.toStringAsFixed(2)}';
  }
  
  // Extract numeric value from price string with any currency symbol
  static double parsePrice(String priceString) {
    if (priceString.isEmpty) return 0.0;
    // Remove all currency symbols and non-numeric characters except decimal point
    String numericString = priceString.replaceAll(RegExp(r'[^\\d.]'), '');
    return double.tryParse(numericString) ?? 0.0;
  }
  
  // Detect currency symbol from price string
  static String detectCurrency(String priceString) {
    if (priceString.contains('₹')) return '₹';
    if (priceString.contains('\$')) return '\$';
    if (priceString.contains('€')) return '€';
    if (priceString.contains('£')) return '£';
    if (priceString.contains('¥')) return '¥';
    if (priceString.contains('₩')) return '₩';
    if (priceString.contains('₽')) return '₽';
    if (priceString.contains('₦')) return '₦';
    if (priceString.contains('₨')) return '₨';
    return '\$'; // Default to dollar
  }
  
  static double calculateDiscountPrice(double originalPrice, double discountPercentage) {
    return originalPrice * (1 - discountPercentage / 100);
  }
  
  static double calculateTotal(List<double> prices) {
    return prices.fold(0.0, (sum, price) => sum + price);
  }
  
  static double calculateTax(double subtotal, double taxRate) {
    return subtotal * (taxRate / 100);
  }
  
  static double applyShipping(double total, double shippingFee, {double freeShippingThreshold = 100.0}) {
    return total >= freeShippingThreshold ? total : total + shippingFee;
  }
}

// Cart item model
class CartItem {
  final String id;
  final String name;
  final double price;
  final double discountPrice;
  int quantity;
  final String? image;
  
  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.discountPrice = 0.0,
    this.quantity = 1,
    this.image,
  });
  
  double get effectivePrice => discountPrice > 0 ? discountPrice : price;
  double get totalPrice => effectivePrice * quantity;
}

// Cart manager
class CartManager extends ChangeNotifier {
  final List<CartItem> _items = [];
  
  List<CartItem> get items => List.unmodifiable(_items);
  
  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere((i) => i.id == item.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }
  
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
  
  void updateQuantity(String id, int quantity) {
    final item = _items.firstWhere((i) => i.id == id);
    item.quantity = quantity;
    notifyListeners();
  }
  
  void clear() {
    _items.clear();
    notifyListeners();
  }
  
  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }
  
  double get totalWithTax {
    final tax = PriceUtils.calculateTax(subtotal, 8.0); // 8% tax
    return subtotal + tax;
  }
  
  double get totalDiscount {
    return _items.fold(0.0, (sum, item) => 
      sum + ((item.price - item.effectivePrice) * item.quantity));
  }
  
  double get gstAmount {
    return PriceUtils.calculateTax(subtotal, 18.0); // 18% GST
  }
  
  double get finalTotal {
    return subtotal + gstAmount;
  }
  
  double get finalTotalWithShipping {
    return PriceUtils.applyShipping(totalWithTax, 5.99); // $5.99 shipping
  }
}

// Wishlist item model
class WishlistItem {
  final String id;
  final String name;
  final double price;
  final double discountPrice;
  final String? image;
  
  WishlistItem({
    required this.id,
    required this.name,
    required this.price,
    this.discountPrice = 0.0,
    this.image,
  });
  
  double get effectivePrice => discountPrice > 0 ? discountPrice : price;
}

// Wishlist manager
class WishlistManager extends ChangeNotifier {
  final List<WishlistItem> _items = [];
  
  List<WishlistItem> get items => List.unmodifiable(_items);
  
  void addItem(WishlistItem item) {
    if (!_items.any((i) => i.id == item.id)) {
      _items.add(item);
      notifyListeners();
    }
  }
  
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
  
  void clear() {
    _items.clear();
    notifyListeners();
  }
  
  bool isInWishlist(String id) {
    return _items.any((item) => item.id == id);
  }
}

final List<Map<String, dynamic>> productCards = [
  {
    'productName': '',
    'imageAsset': 'data:image/png;base64,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',
    'price': '\$299',
    'discountPrice': '\$199',
  }
];


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Generated E-commerce App',
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: Colors.blue,
      appBarTheme: const AppBarTheme(
        elevation: 4,
        shadowColor: Colors.black38,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      cardTheme: const CardThemeData(
        elevation: 3,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        filled: true,
        fillColor: Colors.grey,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    ),
    home: const HomePage(),
    debugShowCheckedModeBanner: false,
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController _pageController;
  int _currentPageIndex = 0;
  final CartManager _cartManager = CartManager();
  final WishlistManager _wishlistManager = WishlistManager();
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _filteredProducts = List.from(productCards);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) => setState(() => _currentPageIndex = index);

  void _onItemTapped(int index) {
    setState(() => _currentPageIndex = index);
    _pageController.jumpToPage(index);
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = List.from(productCards);
      } else {
        _filteredProducts = productCards.where((product) {
          final productName = (product['productName'] ?? '').toString().toLowerCase();
          final price = (product['price'] ?? '').toString().toLowerCase();
          final discountPrice = (product['discountPrice'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return productName.contains(searchLower) || price.contains(searchLower) || discountPrice.contains(searchLower);
        }).toList();
      }
    });
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'home':
        return Icons.home;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'favorite':
        return Icons.favorite;
      case 'person':
        return Icons.person;
      default:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _currentPageIndex,
      children: [
        _buildHomePage(),
        _buildCartPage(),
        _buildWishlistPage(),
        _buildProfilePage(),
      ],
    ),
    bottomNavigationBar: _buildBottomNavigationBar(),
  );

  Widget _buildHomePage() {
    return Column(
      children: [
                  Container(
                    color: Color(0xff2196f3),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                                                Container(
                          width: 32,
                          height: 32,
                          child: Image.memory(
                                base64Decode('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'),
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.store, size: 32, color: Colors.white),
                              ),
                        ),
                        
                        const SizedBox(width: 8),
                        Text(
                          'Foodie Spot',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Stack(
                          children: [
                            const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                            if (_cartManager.items.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${_cartManager.items.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Stack(
                          children: [
                            const Icon(Icons.favorite, color: Colors.white, size: 20),
                            if (_wishlistManager.items.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${_wishlistManager.items.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (value) {
                            _filterProducts(value);
                          },
                          decoration: InputDecoration(
                            hintText: 'Search Food',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: const Icon(Icons.filter_list),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Search by product name or price (e.g., "Product Name" or "\$299")',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 200,
                            autoPlay: true,
                            autoPlayInterval: Duration(seconds: 3),
                            autoPlayAnimationDuration: const Duration(milliseconds: 800),
                            autoPlayCurve: Curves.fastOutSlowIn,
                            enlargeCenterPage: true,
                            scrollDirection: Axis.horizontal,
                            enableInfiniteScroll: true,
                            viewportFraction: 0.8,
                            enlargeFactor: 0.3,
                          ),
                          items: [
                            Builder(
                              builder: (BuildContext context) => Container(
                                width: 300,
                                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    base64Decode('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'),
                                    width: 300,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey[300],
                                      child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                                                const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 6.0, height: 6.0, margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.4))),
                          ],
                        ),
                        
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Color(0xFFFFFFFF),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount:                           _searchQuery.isEmpty 
                              ? productCards.length 
                              : productCards.where((product) {
                                  final productName = (product['productName'] ?? '').toString().toLowerCase();
                                  final price = (product['price'] ?? '').toString().toLowerCase();
                                  final discountPrice = (product['discountPrice'] ?? '').toString().toLowerCase();
                                  return productName.contains(_searchQuery) || price.contains(_searchQuery) || discountPrice.contains(_searchQuery);
                                }).length,
                          itemBuilder: (context, index) {
                            final filteredProducts =                             _searchQuery.isEmpty 
                                ? productCards 
                                : productCards.where((product) {
                                    final productName = (product['productName'] ?? '').toString().toLowerCase();
                                    final price = (product['price'] ?? '').toString().toLowerCase();
                                    final discountPrice = (product['discountPrice'] ?? '').toString().toLowerCase();
                                    return productName.contains(_searchQuery) || price.contains(_searchQuery) || discountPrice.contains(_searchQuery);
                                  }).toList();
                            if (index >= filteredProducts.length) return const SizedBox();
                            final product = filteredProducts[index];
                            final productId = 'product_$index';
                            final isInWishlist = _wishlistManager.isInWishlist(productId);
                            return Card(
                              elevation: 3,
                              color: Color(0xFFFFFFFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                          ),
                                          child:                                           product['imageAsset'] != null
                                              ? (product['imageAsset'] != null && product['imageAsset'].isNotEmpty
                                              ? (product['imageAsset'].startsWith('data:image/')
                                                  ? Image.memory(
                                                      base64Decode(product['imageAsset'].split(',')[1]),
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => Container(
                                                        color: Colors.grey[300],
                                                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                                      ),
                                                    )
                                                  : Image.network(
                                                      product['imageAsset'],
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => Container(
                                                        color: Colors.grey[300],
                                                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                                      ),
                                                    ))
                                              : Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                                ))
                                              : Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image, size: 40),
                                          )
                                          ,
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: IconButton(
                                            onPressed: () {
                                              if (isInWishlist) {
                                                _wishlistManager.removeItem(productId);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Removed from wishlist')),
                                                );
                                              } else {
                                                final wishlistItem = WishlistItem(
                                                  id: productId,
                                                  name: product['productName'] ?? 'Product',
                                                  price: double.tryParse(product['price']?.replaceAll('\$','') ?? '0') ?? 0.0,
                                                  discountPrice: product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                      ? double.tryParse(product['discountPrice'].replaceAll('\$','') ?? '0') ?? 0.0
                                                      : 0.0,
                                                  image: product['imageAsset'],
                                                );
                                                _wishlistManager.addItem(wishlistItem);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Added to wishlist')),
                                                );
                                              }
                                            },
                                            icon: Icon(
                                              isInWishlist ? Icons.favorite : Icons.favorite_border,
                                              color: isInWishlist ? Colors.red : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['productName'] ?? 'Product Name',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Current/Final Price (always without strikethrough)
                                              Text(
                                                                                                product['price'] ?? '$0'
                                                ,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              // Original Price (if discount exists)
                                                                                            if (product['discountPrice'] != null && product['discountPrice'].toString().isNotEmpty)
                                                Text(
                                                  product['discountPrice'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    decoration: TextDecoration.lineThrough,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              Icon(Icons.star_border, color: Colors.amber, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                product['rating'] ?? '4.0',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                final cartItem = CartItem(
                                                  id: productId,
                                                  name: product['productName'] ?? 'Product',
                                                  price: PriceUtils.parsePrice(product['price'] ?? '0'),
                                                  discountPrice:                                                   product['discountPrice'] != null && product['discountPrice'].toString().isNotEmpty
                                                      ? PriceUtils.parsePrice(product['discountPrice'])
                                                      : 0.0
                                                  ,
                                                  image: product['imageAsset'],
                                                );
                                                _cartManager.addItem(cartItem);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Added to cart')),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  
                                                ),
                                              ),
                                              child: const Text(
                                                'Add to Cart',
                                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        automaticallyImplyLeading: false,
      ),
      body: ListenableBuilder(
        listenable: _cartManager,
        builder: (context, child) {
          return _cartManager.items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _cartManager.items.length,
                    itemBuilder: (context, index) {
                      final item = _cartManager.items[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: item.image != null && item.image!.isNotEmpty
                                    ? (item.image!.startsWith('data:image/')
                                    ? Image.memory(
                                  base64Decode(item.image!.split(',')[1]),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                                )
                                    : Image.network(
                                  item.image!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                                ))
                                    : const Icon(Icons.image),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    // Show current price (effective price)
                                    Text(
                                      PriceUtils.formatPrice(item.effectivePrice),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    // Show original price if there's a discount
                                    if (item.discountPrice > 0 && item.price != item.discountPrice)
                                      Text(
                                        PriceUtils.formatPrice(item.price),
                                        style: TextStyle(
                                          fontSize: 14,
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (item.quantity > 1) {
                                        _cartManager.updateQuantity(item.id, item.quantity - 1);
                                      } else {
                                        _cartManager.removeItem(item.id);
                                      }
                                    },
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
                                  IconButton(
                                    onPressed: () {
                                      _cartManager.updateQuantity(item.id, item.quantity + 1);
                                    },
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Bill Summary Section
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bill Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            Text(PriceUtils.formatPrice(_cartManager.subtotal), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      ),
                      if (_cartManager.totalDiscount > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Discount', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              Text('-$0.00', style: const TextStyle(fontSize: 14, color: Colors.green)),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('GST (18%)', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            Text(PriceUtils.formatPrice(_cartManager.gstAmount), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Divider(thickness: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                            Text(PriceUtils.formatPrice(_cartManager.finalTotal), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
        },
      ),
    );
  }

  Widget _buildWishlistPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        automaticallyImplyLeading: false,
      ),
      body: _wishlistManager.items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Your wishlist is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _wishlistManager.items.length,
              itemBuilder: (context, index) {
                final item = _wishlistManager.items[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: item.image != null && item.image!.isNotEmpty
                          ? (item.image!.startsWith('data:image/')
                          ? Image.memory(
                        base64Decode(item.image!.split(',')[1]),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                      )
                          : Image.network(
                        item.image!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                      ))
                          : const Icon(Icons.image),
                    ),
                    title: Text(item.name),
                    subtitle: Text(PriceUtils.formatPrice(item.effectivePrice)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            final cartItem = CartItem(
                              id: item.id,
                              name: item.name,
                              price: item.price,
                              discountPrice: item.discountPrice,
                              image: item.image,
                            );
                            _cartManager.addItem(cartItem);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart')),
                            );
                          },
                          icon: const Icon(Icons.shopping_cart),
                        ),
                        IconButton(
                          onPressed: () {
                            _wishlistManager.removeItem(item.id);
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProfilePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'John Doe',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(250, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Refund button action
                    },
                    child: const Text(
                      'Refund',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 15),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(250, 50),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Log Out button action
                    },
                    child: const Text(
                      'Log Out',
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentPageIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            label: Text('${_cartManager.items.length}'),
            isLabelVisible: _cartManager.items.length > 0,
            child: const Icon(Icons.shopping_cart),
          ),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            label: Text('${_wishlistManager.items.length}'),
            isLabelVisible: _wishlistManager.items.length > 0,
            child: const Icon(Icons.favorite),
          ),
          label: 'Wishlist',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

}
