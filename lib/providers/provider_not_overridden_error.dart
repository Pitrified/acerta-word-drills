/// A provider that `main` has to override was read without an override.
class ProviderNotOverriddenError extends Error {
  ProviderNotOverriddenError(this.providerName);

  /// The name of the provider that was read.
  final String providerName;

  @override
  String toString() =>
      'ProviderNotOverriddenError: $providerName must be overridden in '
      'the ProviderScope';
}
