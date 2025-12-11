class Result<T> {
  final T? value;
  final String? error;

  Result({this.value, this.error});

  factory Result.success(T value) => Result(value: value);
  factory Result.error(String error) => Result(error: error);

  bool get isSuccess => value != null;
  bool get isError => error != null;

  @override
  String toString() {
    if (isSuccess) {
      return 'Result(success: $value)';
    } else {
      return 'Result(error: $error)';
    }
  }
}
