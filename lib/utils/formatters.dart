import 'package:intl/intl.dart';

class Formatters {
  // Currency Formatters
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _currencyCompactFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 0,
  );

  static String currency(double amount) {
    return _currencyFormatter.format(amount);
  }

  static String currencyCompact(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    }
    return _currencyCompactFormatter.format(amount);
  }

  // Date Formatters
  static final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy');
  static final DateFormat _timeFormatter = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormatter = DateFormat('MMM dd, yyyy HH:mm');
  static final DateFormat _shortDateFormatter = DateFormat('MM/dd/yyyy');
  static final DateFormat _dayMonthFormatter = DateFormat('dd MMM');
  static final DateFormat _fullDateFormatter = DateFormat(
    'EEEE, MMMM dd, yyyy',
  );

  static String date(DateTime date) {
    return _dateFormatter.format(date);
  }

  static String time(DateTime time) {
    return _timeFormatter.format(time);
  }

  static String dateTime(DateTime dateTime) {
    return _dateTimeFormatter.format(dateTime);
  }

  static String shortDate(DateTime date) {
    return _shortDateFormatter.format(date);
  }

  static String dayMonth(DateTime date) {
    return _dayMonthFormatter.format(date);
  }

  static String fullDate(DateTime date) {
    return _fullDateFormatter.format(date);
  }

  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return _dateFormatter.format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  static String timeUntil(DateTime futureDate) {
    final now = DateTime.now();
    final difference = futureDate.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'Now';
    }
  }

  // Duration Formatters
  static String duration(int days) {
    if (days == 1) {
      return '1 day';
    } else if (days < 7) {
      return '$days days';
    } else if (days == 7) {
      return '1 week';
    } else if (days < 30) {
      final weeks = (days / 7).floor();
      final remainingDays = days % 7;
      if (remainingDays == 0) {
        return '$weeks week${weeks == 1 ? '' : 's'}';
      } else {
        return '$weeks week${weeks == 1 ? '' : 's'} $remainingDays day${remainingDays == 1 ? '' : 's'}';
      }
    } else {
      final months = (days / 30).floor();
      return '$months month${months == 1 ? '' : 's'}';
    }
  }

  static String shortDuration(int days) {
    if (days < 7) {
      return '${days}d';
    } else if (days < 30) {
      return '${(days / 7).floor()}w';
    } else {
      return '${(days / 30).floor()}m';
    }
  }

  // Number Formatters
  static final NumberFormat _numberFormatter = NumberFormat('#,##0');
  static final NumberFormat _decimalFormatter = NumberFormat('#,##0.0');

  static String number(int number) {
    return _numberFormatter.format(number);
  }

  static String decimal(double number) {
    return _decimalFormatter.format(number);
  }

  static String compactNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  // Rating Formatter
  static String rating(double rating) {
    return rating.toStringAsFixed(1);
  }

  static String ratingWithCount(double rating, int count) {
    return '${rating.toStringAsFixed(1)} (${compactNumber(count)})';
  }

  // Percentage Formatter
  static String percentage(double value) {
    return '${(value * 100).toStringAsFixed(0)}%';
  }

  static String percentageWithDecimal(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  // Distance Formatter
  static String distance(double kilometers) {
    if (kilometers < 1) {
      return '${(kilometers * 1000).toInt()} m';
    } else if (kilometers < 100) {
      return '${kilometers.toStringAsFixed(1)} km';
    } else {
      return '${kilometers.toInt()} km';
    }
  }

  // File Size Formatter
  static String fileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Phone Number Formatter
  static String phoneNumber(String phone) {
    if (phone.length == 10) {
      return '(${phone.substring(0, 3)}) ${phone.substring(3, 6)}-${phone.substring(6)}';
    }
    return phone;
  }

  // Capitalize Text
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String capitalizeWords(String text) {
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  // Truncate Text
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - suffix.length) + suffix;
  }
}
