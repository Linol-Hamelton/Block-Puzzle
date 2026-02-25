enum AdShowStatus {
  shown,
  unavailable,
  failed,
  skipped,
}

class AdShowResult {
  const AdShowResult({
    required this.status,
    required this.network,
    this.ecpmUsd,
    this.rewardGranted = false,
    this.reason,
  });

  final AdShowStatus status;
  final String network;
  final double? ecpmUsd;
  final bool rewardGranted;
  final String? reason;

  bool get isShown => status == AdShowStatus.shown;

  factory AdShowResult.shown({
    required String network,
    double? ecpmUsd,
    bool rewardGranted = false,
  }) {
    return AdShowResult(
      status: AdShowStatus.shown,
      network: network,
      ecpmUsd: ecpmUsd,
      rewardGranted: rewardGranted,
    );
  }

  factory AdShowResult.unavailable({
    required String network,
    String? reason,
  }) {
    return AdShowResult(
      status: AdShowStatus.unavailable,
      network: network,
      reason: reason,
    );
  }

  factory AdShowResult.failed({
    required String network,
    String? reason,
  }) {
    return AdShowResult(
      status: AdShowStatus.failed,
      network: network,
      reason: reason,
    );
  }

  factory AdShowResult.skipped({
    required String network,
    String? reason,
  }) {
    return AdShowResult(
      status: AdShowStatus.skipped,
      network: network,
      reason: reason,
    );
  }
}
