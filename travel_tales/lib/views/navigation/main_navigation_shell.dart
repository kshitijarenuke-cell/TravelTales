import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../dashboard/trip_dashboard_screen.dart';
import '../itinerary/itinerary_screen.dart';
import '../expenses/expenses_screen.dart';
import '../guides/guides_screen.dart';
import '../maps/maps_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final int initialIndex;

  const MainNavigationShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TripDashboardScreen(),
          ItineraryScreen(),
          ExpensesScreen(),
          GuidesScreen(),
          MapsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.subtle, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(15, 23, 42, 0.05),
              offset: Offset(0, -4),
              blurRadius: 16,
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  label: 'Home',
                  icon: Icons.home_rounded,
                  unselectedIcon: Icons.home_outlined,
                ),
                _buildNavItem(
                  index: 1,
                  label: 'Itinerary',
                  icon: Icons.calendar_month_rounded,
                  unselectedIcon: Icons.calendar_today_outlined,
                ),
                _buildNavItem(
                  index: 2,
                  label: 'Expenses',
                  icon: Icons.credit_card_rounded,
                  unselectedIcon: Icons.credit_card_outlined,
                ),
                _buildNavItem(
                  index: 3,
                  label: 'Guides',
                  icon: Icons.person_rounded,
                  unselectedIcon: Icons.person_outline_rounded,
                ),
                _buildNavItem(
                  index: 4,
                  label: 'Maps',
                  icon: Icons.location_on_rounded,
                  unselectedIcon: Icons.location_on_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData unselectedIcon,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primaryTeal : AppColors.muted;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? icon : unselectedIcon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
