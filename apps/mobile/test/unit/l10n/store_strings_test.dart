import 'package:block_puzzle_mobile/l10n/store_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoreStrings (F4 RU-only localization)', () {
    test('provides exact expected Russian user-facing strings', () {
      expect(StoreStrings.storeUnavailable, 'Магазин недоступен в текущей версии');
      expect(StoreStrings.alreadyOwned('Тема Неон'), '"Тема Неон" уже куплен');
      expect(StoreStrings.purchaseSuccess('Тема Неон'), 'Покупка "Тема Неон" успешно завершена');
      expect(StoreStrings.purchaseCancelled('user_cancel'), 'Покупка отменена: user_cancel');
      expect(StoreStrings.purchaseFailed('network_error'), 'Ошибка покупки: network_error');
      expect(StoreStrings.restoreSuccess(3), 'Восстановлено покупок: 3');
      expect(StoreStrings.restoreFailed('timeout'), 'Ошибка восстановления: timeout');
      expect(StoreStrings.loadCatalogFailed, 'Не удалось загрузить магазин');
    });
  });
}
