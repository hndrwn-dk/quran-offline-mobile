import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImportProgress {
  final int current;
  final int total;
  final String? message;

  ImportProgress({
    required this.current,
    required this.total,
    this.message,
  });

  double get progress => total > 0 ? current / total : 0.0;
  bool get isComplete => current >= total;
}

final importProgressProvider = StateProvider<ImportProgress?>((ref) => null);

