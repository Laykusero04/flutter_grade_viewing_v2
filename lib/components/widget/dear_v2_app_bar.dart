import 'package:flutter/material.dart';

class DearV2AppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final Color? backgroundColor;
  final bool centerTitle;
  
  const DearV2AppBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.backgroundColor,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.inversePrimary,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
