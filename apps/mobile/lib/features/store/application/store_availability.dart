import '../../../core/config/remote_config_reader.dart';

/// Answers whether the premium store and monetization surfaces are enabled.
///
/// Under DEC-0026 and DEC-0028 item 7, all monetization surfaces and paid
/// SKUs are disabled in v1.0. When Stage C begins, this can be toggled
/// via Firebase Remote Config parameter `iap_store_enabled` (internal key
/// `iap.store_enabled`) or `feature_store_enabled`.
class StoreAvailability {
  const StoreAvailability(this._reader);

  final RemoteConfigReader _reader;

  /// The primary Remote Config parameter gating the store surface.
  static const String flagKey = 'iap.store_enabled';

  /// Auxiliary feature flag key supported for operational flexibility.
  static const String auxiliaryFlagKey = 'feature_store_enabled';

  /// Whether the store and monetization surfaces are enabled.
  ///
  /// In v1.0 defaults to false. When Stage C begins, toggling either
  /// [flagKey] (`iap_store_enabled` in Firebase) or [auxiliaryFlagKey]
  /// to true re-enables the store route, catalog, and main-screen entry.
  bool get isEnabled {
    final String rolloutStrategy =
        _reader.readString('iap.rollout_strategy', fallback: '');
    if (rolloutStrategy == 'disabled' || rolloutStrategy == 'none') {
      return false;
    }
    return _reader.readBool(flagKey, fallback: false) ||
        _reader.readBool(auxiliaryFlagKey, fallback: false);
  }
}
