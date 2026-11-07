import 'package:intl/intl.dart';

/// Human friendly relative time, e.g. "Just now", "5 min ago", "2 days ago".
String timeAgo(DateTime date, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(date);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) {
    return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }
  return DateFormat('d MMM yyyy').format(date);
}

/// e.g. "Oct 15, 2026 at 10:24 AM"
String fullDateTime(DateTime date) =>
    DateFormat("MMM d, yyyy 'at' h:mm a").format(date);

/// e.g. "Oct 15, 10:24 AM"
String shortDateTime(DateTime date) => DateFormat('MMM d, h:mm a').format(date);
