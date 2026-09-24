/// Russian user-facing strings for StoreController per F4 / DEC-0026 / DEC-0028.
///
/// Full multi-locale arb/intl pipeline is planned for Phase 3.
class StoreStrings {
  const StoreStrings._();

  static const String storeUnavailable = 'Магазин недоступен в текущей версии';
  static String alreadyOwned(String title) => '"$title" уже куплен';
  static String purchaseSuccess(String title) => 'Покупка "$title" успешно завершена';
  static String purchaseCancelled(String reason) => 'Покупка отменена: $reason';
  static String purchaseFailed(Object error) => 'Ошибка покупки: $error';
  static String restoreSuccess(int count) => 'Восстановлено покупок: $count';
  static String restoreFailed(Object error) => 'Ошибка восстановления: $error';
  static const String loadCatalogFailed = 'Не удалось загрузить магазин';
}
