import 'package:flutter/foundation.dart';

class Staff {
  String name;
  final String? photoPath;

  Staff({required this.name, this.photoPath});
}

/// Holds staff directory state and search/edit rules for the Owner screen.
class StaffDirectoryController extends ChangeNotifier {
  final List<Staff> staff = [];
  String searchQuery = '';

  List<Staff> get filteredStaff {
    final query = searchQuery.toLowerCase();
    return staff
        .where((member) => member.name.toLowerCase().contains(query))
        .toList();
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void add(Staff member) {
    staff.add(member);
    notifyListeners();
  }

  void rename(int index, String name) {
    if (index < 0 || index >= staff.length || name.trim().isEmpty) return;
    staff[index].name = name.trim();
    notifyListeners();
  }
}
