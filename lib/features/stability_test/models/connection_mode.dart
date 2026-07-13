/// How an HTTP client is managed across the requests of a single test run.
///
/// See spec §6.2.
enum ConnectionMode {
  /// The whole test shares one HTTP client, allowing connection reuse. Closer
  /// to everyday app or API usage. Spec §6.2.1.
  reuseClient,

  /// A brand-new HTTP client is created for each request and closed right
  /// after, forcing reconnection as much as the platform allows.
  /// Spec §6.2.2. This does NOT guarantee clearing the OS DNS cache.
  newClientPerRequest,
  ;

  /// Stable key used for local-storage serialization (spec §16).
  static const Map<ConnectionMode, String> _keys = <ConnectionMode, String>{
    ConnectionMode.reuseClient: 'reuseClient',
    ConnectionMode.newClientPerRequest: 'newClientPerRequest',
  };

  String get storageKey => _keys[this]!;

  static ConnectionMode fromStorageKey(String? key) {
    switch (key) {
      case 'newClientPerRequest':
        return ConnectionMode.newClientPerRequest;
      case 'reuseClient':
      default:
        return ConnectionMode.reuseClient;
    }
  }
}
