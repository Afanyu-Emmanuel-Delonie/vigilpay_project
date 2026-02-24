String formatUsd(num amount, {bool includeSign = false}) {
  final absolute = amount.abs();
  final parts = absolute.toStringAsFixed(2).split('.');
  final withGrouping = parts[0].replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  final core = '\$$withGrouping.${parts[1]}';

  if (!includeSign) {
    return amount < 0 ? '-$core' : core;
  }

  if (amount < 0) {
    return '-$core';
  }
  return '+$core';
}
