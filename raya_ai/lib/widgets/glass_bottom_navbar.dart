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
              color: Colors.white.withOpacity(0.015),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, 0),
                _buildNavItem(Icons.camera_alt_outlined, Icons.camera_alt, 1),
                _buildNavItem(Icons.dry_cleaning_outlined, Icons.dry_cleaning, 2),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildNavItem(IconData unselectedIcon, IconData selectedIcon, int index) {
    final bool isSelected = selectedIndex == index;
    return IconButton(
      onPressed: () => onItemTapped(index),
      splashColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.1),
      icon: Icon(
        isSelected ? selectedIcon : unselectedIcon,
        color: isSelected ? Colors.white : Colors.white70,
        size: 28, // İkon boyutunu buradan ayarlayabilirsin.
      ),
    );
  }
}

