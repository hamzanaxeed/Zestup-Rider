import 'package:flutter/material.dart';
import 'package:rider/helpers/Colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../views/Authentication/login_Screen.dart';
import '../controllers/order_Controller.dart';
import '../controllers/auth_Controller.dart';
import 'package:provider/provider.dart';
import '../Models/order_Model.dart';
import 'orders/orders_Screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Add a global RouteObserver for tracking navigation
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  int selectedTab = 0; // 0: Pending, 1: Completed

  void _showRoundedBottomSheet(BuildContext context) {

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Make sheet cover full bottom
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5, // covers half the screen, adjust as needed
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'This is a rounded bottom sheet!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Text('You can put any content here.'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    final success = await AuthController.logoutUser(context);
    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
    // If not successful, snackbar is already shown in AuthController
  }

  Future<void> _refreshOrders() async {
    final controller = Provider.of<OrderController>(context, listen: false);
    await controller.fetchOrders(context: context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes using the global routeObserver
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);

    // Schedule fetchOrders after build to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<OrderController>(context, listen: false);
      controller.fetchOrders(context: context);
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when returning to this screen from another route
    final controller = Provider.of<OrderController>(context, listen: false);
    controller.fetchOrders(context: context);
    super.didPopNext();
  }

  @override
  void initState() {
    super.initState();
    // Notification setup removed, handled globally in main.dart
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Appcolors.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: Appcolors.appBarColor,
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.shopping_bag_outlined, size: 28),
              SizedBox(width: 8),
              Text('Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => _logout(context),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        child: Consumer<OrderController>(
          builder: (context, orderController, _) {
            // Filter orders based on selectedTab
            List<Order> filteredOrders;
            if (selectedTab == 1) {
              filteredOrders = orderController.orders
                  .where((o) => o.status?.toLowerCase() == 'delivered' || o.status?.toLowerCase() == 'completed')
                  .toList();
            } else {
              filteredOrders = orderController.orders
                  .where((o) => o.status?.toLowerCase() != 'delivered' && o.status?.toLowerCase() != 'completed')
                  .toList();
            }

            // Always provide a scrollable widget for RefreshIndicator
            if (orderController.loading) {
              // Show loading indicator, but allow pull-to-refresh
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }
            if (orderController.errorMessage != null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          orderController.errorMessage!,
                          style: const TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            if (filteredOrders.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Center(
                      child: Text(
                        selectedTab == 1 ? 'No completed orders.' : 'No pending orders.',
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(orderId: order.id ?? ''),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: order.status?.toLowerCase() == 'delivered' || order.status?.toLowerCase() == 'completed'
                                ? Colors.green[100]
                                : Colors.orange[100],
                            child: Icon(
                              order.status?.toLowerCase() == 'delivered' || order.status?.toLowerCase() == 'completed'
                                  ? Icons.check_circle_outline
                                  : Icons.timelapse,
                              color: order.status?.toLowerCase() == 'delivered' || order.status?.toLowerCase() == 'completed'
                                  ? Colors.green
                                  : Colors.orange,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Use Expanded here to avoid overflow
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order #${order.displayId ?? ''}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: Colors.blueGrey),
                                    const SizedBox(width: 4),
                                    // Use Flexible to avoid overflow
                                    Flexible(
                                      child: Text(
                                        order.deliveryAddress ?? '',
                                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        order.createdAt?.substring(0, 16) ?? '',
                                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Use Flexible for trailing column to avoid overflow
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  order.status ?? '',
                                  style: TextStyle(
                                    color: order.status?.toLowerCase() == 'delivered' || order.status?.toLowerCase() == 'completed'
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Rs. ${order.total ?? ''}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                },
              );
          },
        ),
      ),
    );
  }
}
