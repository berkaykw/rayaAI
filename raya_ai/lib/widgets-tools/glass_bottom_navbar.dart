import 'dart:ui';
import 'package:flutter/material.dart';

class GlassBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const GlassBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color containerColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.1);
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.25)
        : Colors.black.withOpacity(0.18);
    const double navBarHeight = 60.0;

    return Padding(
      // Dış boşluklar ayarlandı.
      padding: const EdgeInsets.symmetric(horizontal: 75.0, vertical: 20.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: navBarHeight,
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                    context, Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, 0),
                _buildNavItem(
                    context, Icons.camera_alt_outlined, Icons.camera_alt, 1),
                _buildNavItem(
                    context, Icons.dry_cleaning_outlined, Icons.dry_cleaning, 2),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildNavItem(BuildContext context, IconData unselectedIcon,
      IconData selectedIcon, int index) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isSelected = selectedIndex == index;
    final Color selectedColor = theme.colorScheme.primary;
    final Color unselectedColor = isDark
        ? Colors.white.withOpacity(0.7)
        : theme.colorScheme.onSurface.withOpacity(0.5);
    final Color splashColor = selectedColor.withOpacity(0.2);
    return IconButton(
      onPressed: () => onItemTapped(index),
      splashColor: splashColor,
      highlightColor: splashColor,
      icon: Icon(
        isSelected ? selectedIcon : unselectedIcon,
        color: isSelected ? selectedColor : unselectedColor,
        size: 28, // İkon boyutunu buradan ayarlayabilirsin.
      ),
    );
  }
}

