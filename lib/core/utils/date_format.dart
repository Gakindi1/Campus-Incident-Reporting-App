import 'package:intl/intl.dart';

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

String fullDateTime(DateTime date) =>
    DateFormat("MMM d, yyyy 'at' h:mm a").format(date);

String shortDateTime(DateTime date) => DateFormat('MMM d, h:mm a').format(date);
