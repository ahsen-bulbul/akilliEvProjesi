class SensorThreshold {
  final String key;
  final String label;
  final double? min;
  final double? max;
  final String unit;

  const SensorThreshold({
    required this.key,
    required this.label,
    this.min,
    this.max,
    required this.unit,
  });

  bool isExceeded(double? value) {
    if (value == null) {
      return false;
    }
    if (min != null && value < min!) {
      return true;
    }
    if (max != null && value > max!) {
      return true;
    }
    return false;
  }
}
