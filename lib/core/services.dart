import 'api/api_client.dart';
import 'api/session_store.dart';
import 'referentiels.dart';
import 'sync/file_attente.dart';

/// Services partagés de l'application (instanciés une fois au démarrage).
class Services {
  Services._();

  static final session = SessionStore();
  /// Créé au premier accès, donc après le chargement du `.env` (voir main.dart).
  static final api = ApiClient(session: session);
  static final referentiels = Referentiels(api);
  static final fileAttente = FileAttente(api);
}

/// Raccourcis lisibles dans les écrans.
ApiClient get api => Services.api;
Referentiels get refs => Services.referentiels;
