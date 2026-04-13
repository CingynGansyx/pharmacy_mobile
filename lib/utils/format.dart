import 'package:intl/intl.dart';

/// Нийтлэг форматерууд — locale-аас хамаарахгүй тул бүх платформ дээр алдаагүй.
final NumberFormat currencyFmt =
    NumberFormat.currency(symbol: '₮', decimalDigits: 0);

String formatCurrency(num value) => currencyFmt.format(value);

final DateFormat dateTimeFmt = DateFormat('yyyy-MM-dd HH:mm');
final DateFormat dateFmt = DateFormat('yyyy-MM-dd');
