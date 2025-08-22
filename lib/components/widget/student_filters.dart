import 'package:flutter/material.dart';

class StudentFilters extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback onClearSearch;

  const StudentFilters({
    super.key,
    required this.onSearch,
    required this.onClearSearch,
  });

  @override
  State<StudentFilters> createState() => _StudentFiltersState();
}

class _StudentFiltersState extends State<StudentFilters> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    widget.onClearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search students by name, email, or school ID...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: widget.onSearch,
          ),
        ],
      ),
    );
  }
}
