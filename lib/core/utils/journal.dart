import 'package:flutter/foundation.dart';

/// Journal de diagnostic, écrit en développement seulement : `debugPrint`
/// n'est pas retiré des versions publiées, où un message d'exception peut
/// contenir une adresse ou une donnée personnelle.
void journalDebug(String message) {
  if (kDebugMode) debugPrint(message);
}
