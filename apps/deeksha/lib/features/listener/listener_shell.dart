import 'package:flutter/material.dart';

import '../../app.dart';
import '../stories/library_page.dart';
import '../stories/search_page.dart';
import 'my_library_page.dart';
import 'profile_page.dart';

class ListenerShell extends StatefulWidget {
  const ListenerShell({super.key});

  @override
  State<ListenerShell> createState() => _ListenerShellState();
}

class _ListenerShellState extends State<ListenerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _index,
      children: [
        const HomePage(),
        const SearchPage(),
        MyLibraryPage(onExplore: () => setState(() => _index = 0)),
        const ProfilePage(),
      ],
    ),
    bottomNavigationBar: DecoratedBox(
      decoration: const BoxDecoration(
        color: VelaColors.cream,
        border: Border(top: BorderSide(color: VelaColors.blush)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _NavItem(
                label: 'Home',
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
              _NavItem(
                label: 'Search',
                icon: Icons.search_rounded,
                selectedIcon: Icons.search_rounded,
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
              _NavItem(
                label: 'My Library',
                icon: Icons.bookmarks_outlined,
                selectedIcon: Icons.bookmarks_rounded,
                selected: _index == 2,
                onTap: () => setState(() => _index = 2),
              ),
              _NavItem(
                label: 'Profile',
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                selected: _index == 3,
                onTap: () => setState(() => _index = 3),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              size: 22,
              color: selected ? VelaColors.apricot : VelaColors.plum,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? VelaColors.apricot : VelaColors.plum,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
