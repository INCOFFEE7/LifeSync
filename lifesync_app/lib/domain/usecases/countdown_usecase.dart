class CountdownUseCase {
  /// Returns a formatted string representing the countdown
  static String calculateCountdown(DateTime current, DateTime target) {
    if (current.isAfter(target)) {
      return 'Deadline passed';
    }

    Duration diff = target.difference(current);
    int inDays = diff.inDays;
    
    if (inDays > 365) {
      int years = inDays ~/ 365;
      return '$years years remaining';
    } else if (inDays > 30) {
      int months = inDays ~/ 30;
      return '$months months remaining';
    } else if (inDays > 0) {
      int hours = diff.inHours % 24;
      if (hours > 0) {
        return '$inDays days $hours hours remaining';
      }
      return '$inDays days remaining';
    } else {
      int hours = diff.inHours;
      int minutes = diff.inMinutes % 60;
      if (hours > 0) {
        return '$hours hours $minutes minutes remaining';
      } else {
        return '$minutes minutes remaining';
      }
    }
  }
}
