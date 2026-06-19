import 'package:cloud_functions/cloud_functions.dart';

import '../../core/logging/app_logger.dart';
import 'purchase_receipt_validator.dart';

/// [PurchaseReceiptValidator] backed by the `verifyPurchase` callable Cloud
/// Function. The function validates the Android `purchaseToken` with the Google
/// Play Developer API, records the entitlement under the caller's UID in
/// Firestore, and returns `{ valid: bool, entitlements: [..], errorCode? }`.
///
/// Requires the caller to be authenticated (Firebase Anonymous Auth) so the
/// function can bind entitlements to a stable UID. See
/// `docs/adr/003-billing-receipt-validation.md`.
class CloudFunctionsReceiptValidator implements PurchaseReceiptValidator {
  CloudFunctionsReceiptValidator({
    required AppLogger logger,
    FirebaseFunctions? functions,
    Duration timeout = const Duration(seconds: 20),
  })  : _logger = logger,
        _functions = functions ?? FirebaseFunctions.instance,
        _timeout = timeout;

  final AppLogger _logger;
  final FirebaseFunctions _functions;
  final Duration _timeout;

  @override
  Future<ReceiptValidationResult> validate({
    required String productId,
    required String purchaseToken,
    required String source,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable(
        'verifyPurchase',
        options: HttpsCallableOptions(timeout: _timeout),
      );
      final HttpsCallableResult result = await callable.call(<String, Object?>{
        'platform': 'android',
        'productId': productId,
        'purchaseToken': purchaseToken,
        'source': source,
      });

      final Object? data = result.data;
      if (data is! Map) {
        return ReceiptValidationResult.invalid(
          errorCode: 'malformed_response',
          message: 'verifyPurchase returned a non-object payload.',
        );
      }
      final Map<dynamic, dynamic> payload = data;
      final bool valid = payload['valid'] == true;
      if (!valid) {
        return ReceiptValidationResult.invalid(
          errorCode: (payload['errorCode'] as String?) ?? 'receipt_invalid',
          message: payload['message'] as String?,
        );
      }

      final Object? rawEntitlements = payload['entitlements'];
      final Set<String> entitlements = rawEntitlements is List
          ? rawEntitlements.whereType<String>().toSet()
          : <String>{};
      return ReceiptValidationResult.valid(entitlements: entitlements);
    } on FirebaseFunctionsException catch (error) {
      _logger.warn(
        'verifyPurchase failed [${error.code}] for $productId: ${error.message}',
      );
      return ReceiptValidationResult.invalid(
        errorCode: error.code,
        message: error.message,
      );
    } catch (error) {
      _logger.warn('verifyPurchase threw for $productId: $error');
      return ReceiptValidationResult.invalid(
        errorCode: 'validation_error',
        message: '$error',
      );
    }
  }
}
