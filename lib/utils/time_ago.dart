class TimeAgo {
  static String format(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks tuần trước';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months tháng trước';
    } else {
      final years = (diff.inDays / 365).floor();
      return '$years năm trước';
    }
  }

  static String formatShort(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'mới';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}p';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}g';
    } else {
      return '${diff.inDays}n';
    }
  }
}
