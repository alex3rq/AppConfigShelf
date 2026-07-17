import 'failure.dart';

/// A success-or-failure value. Engines return this across package boundaries
/// instead of throwing, so callers must handle both branches and pipelines
/// can accumulate failures without unwinding.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(ShelfFailure failure) = Err<T>;

  bool get isOk => this is Ok<T>;

  /// The success value, or null.
  T? get valueOrNull => switch (this) { Ok(:final value) => value, Err() => null };

  /// The failure, or null.
  ShelfFailure? get failureOrNull =>
      switch (this) { Ok() => null, Err(:final failure) => failure };

  R fold<R>(R Function(T value) onOk, R Function(ShelfFailure failure) onErr) =>
      switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final failure) => onErr(failure),
      };

  /// Transforms the success value, passing failures through unchanged.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Ok(:final value) => Result.ok(transform(value)),
        Err(:final failure) => Result.err(failure),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  String toString() => 'Ok($value)';
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final ShelfFailure failure;

  @override
  String toString() => 'Err($failure)';
}
