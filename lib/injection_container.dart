import 'package:get_it/get_it.dart';

import 'core/network/api_client.dart';
import 'core/services/auth_event_bus.dart';
import 'core/services/file_attente_service.dart';
import 'core/services/referentiels_service.dart';
import 'core/services/token_service.dart';

// Auth
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/activer_locataire.dart';
import 'features/auth/domain/usecases/changer_mot_de_passe.dart';
import 'features/auth/domain/usecases/connecter.dart';
import 'features/auth/domain/usecases/deconnecter.dart';
import 'features/auth/domain/usecases/demander_reinitialisation.dart';
import 'features/auth/domain/usecases/get_compte.dart';
import 'features/auth/domain/usecases/inscrire_proprietaire.dart';
import 'features/auth/domain/usecases/reinitialiser_mot_de_passe.dart';
import 'features/auth/domain/usecases/restaurer_session.dart';
import 'features/auth/domain/usecases/verifier_mfa.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/mot_de_passe_oublie_bloc.dart';

// Notifications
import 'features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'features/notifications/data/repositories/notifications_repository_impl.dart';
import 'features/notifications/domain/repositories/notifications_repository.dart';
import 'features/notifications/domain/usecases/compter_notifications_non_lues.dart';
import 'features/notifications/domain/usecases/get_notifications.dart';
import 'features/notifications/domain/usecases/marquer_notification_lue.dart';
import 'features/notifications/domain/usecases/tout_lire.dart';
import 'features/notifications/presentation/bloc/notifications_bloc.dart';

// Documents
import 'features/documents/data/datasources/documents_remote_datasource.dart';
import 'features/documents/data/repositories/documents_repository_impl.dart';
import 'features/documents/domain/repositories/documents_repository.dart';
import 'features/documents/domain/usecases/ajouter_photo_document.dart';
import 'features/documents/domain/usecases/changer_visibilite_document.dart';
import 'features/documents/domain/usecases/get_documents.dart';
import 'features/documents/domain/usecases/get_lien_document.dart';
import 'features/documents/domain/usecases/supprimer_document.dart';
import 'features/documents/domain/usecases/telecharger_document.dart';
import 'features/documents/presentation/bloc/documents_bloc.dart';

// Account
import 'features/account/data/datasources/account_remote_datasource.dart';
import 'features/account/data/repositories/account_repository_impl.dart';
import 'features/account/domain/repositories/account_repository.dart';
import 'features/account/domain/usecases/activer_mfa.dart';
import 'features/account/domain/usecases/desactiver_mfa.dart';
import 'features/account/domain/usecases/get_sessions.dart';
import 'features/account/domain/usecases/initialiser_mfa.dart';
import 'features/account/domain/usecases/modifier_profil.dart';
import 'features/account/domain/usecases/regenerer_codes_secours.dart';
import 'features/account/domain/usecases/revoquer_session.dart';
import 'features/account/domain/usecases/revoquer_toutes_sessions.dart';
import 'features/account/presentation/bloc/account_bloc.dart';

// Patrimoine
import 'features/appartement/data/datasources/appartement_remote_datasource.dart';
import 'features/appartement/data/repositories/appartement_repository_impl.dart';
import 'features/appartement/domain/repositories/appartement_repository.dart';
import 'features/appartement/domain/usecases/changer_statut_appartement.dart';
import 'features/appartement/domain/usecases/creer_appartement.dart';
import 'features/appartement/domain/usecases/get_appartements.dart';
import 'features/appartement/domain/usecases/get_fiche_appartement.dart';
import 'features/appartement/domain/usecases/modifier_appartement.dart';
import 'features/appartement/domain/usecases/supprimer_appartement.dart';
import 'features/appartement/presentation/bloc/appartement_bloc.dart';
import 'features/bail/data/datasources/bail_remote_datasource.dart';
import 'features/bail/data/repositories/bail_repository_impl.dart';
import 'features/bail/domain/repositories/bail_repository.dart';
import 'features/bail/domain/usecases/activer_bail.dart';
import 'features/bail/domain/usecases/annuler_bail.dart';
import 'features/bail/domain/usecases/cloturer_bail.dart';
import 'features/bail/domain/usecases/creer_bail.dart';
import 'features/bail/domain/usecases/generer_contrat.dart';
import 'features/bail/domain/usecases/get_baux.dart';
import 'features/bail/domain/usecases/get_fiche_bail.dart';
import 'features/bail/domain/usecases/modifier_bail.dart';
import 'features/bail/domain/usecases/reviser_loyer.dart';
import 'features/bail/domain/usecases/terminer_bail.dart';
import 'features/bail/presentation/bloc/bail_bloc.dart';
import 'features/immeuble/data/datasources/immeuble_remote_datasource.dart';
import 'features/immeuble/data/repositories/immeuble_repository_impl.dart';
import 'features/immeuble/domain/repositories/immeuble_repository.dart';
import 'features/immeuble/domain/usecases/creer_immeuble.dart';
import 'features/immeuble/domain/usecases/get_immeuble.dart';
import 'features/immeuble/domain/usecases/get_immeubles.dart';
import 'features/immeuble/domain/usecases/modifier_immeuble.dart';
import 'features/immeuble/domain/usecases/supprimer_immeuble.dart';
import 'features/immeuble/presentation/bloc/immeuble_bloc.dart';
import 'features/locataire/data/datasources/locataire_remote_datasource.dart';
import 'features/locataire/data/repositories/locataire_repository_impl.dart';
import 'features/locataire/domain/repositories/locataire_repository.dart';
import 'features/locataire/domain/usecases/creer_locataire.dart';
import 'features/locataire/domain/usecases/enregistrer_consentement_whatsapp.dart';
import 'features/locataire/domain/usecases/get_locataire.dart';
import 'features/locataire/domain/usecases/get_locataires.dart';
import 'features/locataire/domain/usecases/inviter_locataire.dart';
import 'features/locataire/domain/usecases/modifier_locataire.dart';
import 'features/locataire/domain/usecases/supprimer_locataire.dart';
import 'features/locataire/presentation/bloc/locataire_bloc.dart';

// Loyers et paiements
import 'features/echeance/data/datasources/echeance_remote_datasource.dart';
import 'features/echeance/data/repositories/echeance_repository_impl.dart';
import 'features/echeance/domain/repositories/echeance_repository.dart';
import 'features/echeance/domain/usecases/annuler_echeance.dart';
import 'features/echeance/domain/usecases/get_echeances.dart';
import 'features/paiement/data/datasources/paiement_remote_datasource.dart';
import 'features/paiement/data/repositories/paiement_repository_impl.dart';
import 'features/paiement/domain/repositories/paiement_repository.dart';
import 'features/paiement/domain/usecases/configurer_moyen_paiement.dart';
import 'features/paiement/domain/usecases/encaisser_paiement.dart';
import 'features/paiement/domain/usecases/get_fiche_paiement.dart';
import 'features/paiement/domain/usecases/get_moyens_paiement.dart';
import 'features/paiement/domain/usecases/get_paiements.dart';
import 'features/paiement/domain/usecases/get_rapprochements.dart';
import 'features/paiement/domain/usecases/get_transaction.dart';
import 'features/paiement/domain/usecases/get_transactions.dart';
import 'features/paiement/domain/usecases/rejeter_rapprochement.dart';
import 'features/paiement/domain/usecases/rejeter_transaction.dart';
import 'features/paiement/domain/usecases/rembourser_paiement.dart';
import 'features/paiement/domain/usecases/resoudre_rapprochement.dart';
import 'features/paiement/domain/usecases/valider_transaction.dart';
import 'features/paiement/presentation/bloc/moyens_paiement_bloc.dart';
import 'features/paiement/presentation/bloc/paiement_bloc.dart';
import 'features/paiement/presentation/bloc/transaction_bloc.dart';
import 'features/quittance/data/datasources/quittance_remote_datasource.dart';
import 'features/quittance/data/repositories/quittance_repository_impl.dart';
import 'features/quittance/domain/repositories/quittance_repository.dart';
import 'features/quittance/domain/usecases/get_quittances.dart';
import 'features/quittance/domain/usecases/telecharger_quittance.dart';

// Factures communes
import 'features/facture_commune/data/datasources/facture_commune_remote_datasource.dart';
import 'features/facture_commune/data/repositories/facture_commune_repository_impl.dart';
import 'features/facture_commune/domain/repositories/facture_commune_repository.dart';
import 'features/facture_commune/domain/usecases/annuler_facture_commune.dart';
import 'features/facture_commune/domain/usecases/creer_facture_commune.dart';
import 'features/facture_commune/domain/usecases/get_charges_refacturees.dart';
import 'features/facture_commune/domain/usecases/get_facture_commune.dart';
import 'features/facture_commune/domain/usecases/get_factures_a_repartir.dart';
import 'features/facture_commune/domain/usecases/get_factures_communes.dart';
import 'features/facture_commune/domain/usecases/joindre_document_facture.dart';
import 'features/facture_commune/domain/usecases/modifier_facture_commune.dart';
import 'features/facture_commune/domain/usecases/previsualiser_repartition.dart';
import 'features/facture_commune/domain/usecases/repartir_facture.dart';
import 'features/facture_commune/presentation/bloc/facture_commune_bloc.dart';
import 'features/facture_commune/presentation/bloc/repartition_bloc.dart';

// Gestion financière
import 'features/caisse/data/datasources/caisse_remote_datasource.dart';
import 'features/caisse/data/repositories/caisse_repository_impl.dart';
import 'features/caisse/domain/repositories/caisse_repository.dart';
import 'features/caisse/domain/usecases/ajouter_autre_revenu.dart';
import 'features/caisse/domain/usecases/annuler_mouvement_caisse.dart';
import 'features/caisse/domain/usecases/get_mouvements_caisse.dart';
import 'features/caisse/domain/usecases/get_synthese_caisse.dart';
import 'features/caution/data/datasources/caution_remote_datasource.dart';
import 'features/caution/data/repositories/caution_repository_impl.dart';
import 'features/caution/domain/repositories/caution_repository.dart';
import 'features/caution/domain/usecases/ajouter_justificatif_caution.dart';
import 'features/caution/domain/usecases/get_caution.dart';
import 'features/caution/domain/usecases/get_cautions.dart';
import 'features/caution/domain/usecases/repondre_contestation.dart';
import 'features/caution/domain/usecases/restituer_caution.dart';
import 'features/caution/domain/usecases/retenir_caution.dart';
import 'features/caution/domain/usecases/verser_caution.dart';
import 'features/caution/presentation/bloc/caution_bloc.dart';
import 'features/depense/data/datasources/depense_remote_datasource.dart';
import 'features/depense/data/repositories/depense_repository_impl.dart';
import 'features/depense/domain/repositories/depense_repository.dart';
import 'features/depense/domain/usecases/ajouter_justificatif_depense.dart';
import 'features/depense/domain/usecases/annuler_depense.dart';
import 'features/depense/domain/usecases/creer_categorie_depense.dart';
import 'features/depense/domain/usecases/creer_depense.dart';
import 'features/depense/domain/usecases/creer_depense_travaux.dart';
import 'features/depense/domain/usecases/desactiver_categorie_depense.dart';
import 'features/depense/domain/usecases/get_categories_depenses.dart';
import 'features/depense/domain/usecases/get_depenses.dart';
import 'features/depense/domain/usecases/modifier_categorie_depense.dart';
import 'features/depense/domain/usecases/modifier_depense.dart';
import 'features/depense/presentation/bloc/categories_bloc.dart';
import 'features/rapport/data/datasources/rapport_remote_datasource.dart';
import 'features/rapport/data/repositories/rapport_repository_impl.dart';
import 'features/rapport/domain/repositories/rapport_repository.dart';
import 'features/rapport/domain/usecases/exporter_rapport_csv.dart';
import 'features/rapport/domain/usecases/get_rapport_financier.dart';
import 'features/rapport/domain/usecases/get_rapport_immobilier.dart';
import 'features/rapport/domain/usecases/get_rapport_locataires.dart';
import 'features/rapport/domain/usecases/get_rapport_travaux.dart';
import 'features/rapport/domain/usecases/get_rentabilite.dart';

// Travaux
import 'features/artisan/data/datasources/artisan_remote_datasource.dart';
import 'features/artisan/data/repositories/artisan_repository_impl.dart';
import 'features/artisan/domain/repositories/artisan_repository.dart';
import 'features/artisan/domain/usecases/creer_artisan.dart';
import 'features/artisan/domain/usecases/definir_activite_artisan.dart';
import 'features/artisan/domain/usecases/get_artisan.dart';
import 'features/artisan/domain/usecases/get_artisans.dart';
import 'features/artisan/domain/usecases/modifier_artisan.dart';
import 'features/artisan/domain/usecases/supprimer_artisan.dart';
import 'features/artisan/presentation/bloc/artisan_bloc.dart';
import 'features/travaux/data/datasources/travaux_remote_datasource.dart';
import 'features/travaux/data/repositories/travaux_repository_impl.dart';
import 'features/travaux/domain/repositories/travaux_repository.dart';
import 'features/travaux/domain/usecases/ajouter_photo_travaux.dart';
import 'features/travaux/domain/usecases/changer_statut_travaux.dart';
import 'features/travaux/domain/usecases/creer_travaux.dart';
import 'features/travaux/domain/usecases/get_travaux.dart';
import 'features/travaux/domain/usecases/get_travaux_liste.dart';
import 'features/travaux/domain/usecases/modifier_travaux.dart';
import 'features/travaux/domain/usecases/supprimer_photo_travaux.dart';
import 'features/travaux/presentation/bloc/travaux_bloc.dart';
import 'features/incident/data/datasources/incident_remote_datasource.dart';
import 'features/incident/data/repositories/incident_repository_impl.dart';
import 'features/incident/domain/repositories/incident_repository.dart';
import 'features/incident/domain/usecases/analyser_incident.dart';
import 'features/incident/domain/usecases/creer_incident.dart';
import 'features/incident/domain/usecases/get_incident.dart';
import 'features/incident/domain/usecases/get_incidents.dart';
import 'features/incident/domain/usecases/planifier_travaux.dart';
import 'features/incident/domain/usecases/rejeter_incident.dart';
import 'features/incident/domain/usecases/resoudre_incident.dart';
import 'features/incident/presentation/bloc/incident_bloc.dart';
import 'features/etat_des_lieux/data/datasources/etat_des_lieux_remote_datasource.dart';
import 'features/etat_des_lieux/data/repositories/etat_des_lieux_repository_impl.dart';
import 'features/etat_des_lieux/domain/repositories/etat_des_lieux_repository.dart';
import 'features/etat_des_lieux/domain/usecases/ajouter_element_edl.dart';
import 'features/etat_des_lieux/domain/usecases/ajouter_photo_edl.dart';
import 'features/etat_des_lieux/domain/usecases/ajouter_piece_edl.dart';
import 'features/etat_des_lieux/domain/usecases/corriger_etat_des_lieux.dart';
import 'features/etat_des_lieux/domain/usecases/creer_etat_des_lieux.dart';
import 'features/etat_des_lieux/domain/usecases/enregistrer_saisie_edl.dart';
import 'features/etat_des_lieux/domain/usecases/get_comparaison_edl.dart';
import 'features/etat_des_lieux/domain/usecases/get_etat_des_lieux.dart';
import 'features/etat_des_lieux/domain/usecases/get_etats_des_lieux.dart';
import 'features/etat_des_lieux/domain/usecases/modifier_releves_edl.dart';
import 'features/etat_des_lieux/domain/usecases/preciser_element_edl.dart';
import 'features/etat_des_lieux/domain/usecases/renommer_piece_edl.dart';
import 'features/etat_des_lieux/domain/usecases/soumettre_etat_des_lieux.dart';
import 'features/etat_des_lieux/domain/usecases/supprimer_element_edl.dart';
import 'features/etat_des_lieux/domain/usecases/supprimer_etat_des_lieux.dart';
import 'features/etat_des_lieux/domain/usecases/supprimer_photo_edl.dart';
import 'features/etat_des_lieux/domain/usecases/supprimer_piece_edl.dart';
import 'features/etat_des_lieux/domain/usecases/telecharger_pdf_edl.dart';
import 'features/etat_des_lieux/presentation/bloc/etat_des_lieux_bloc.dart';
import 'features/etat_des_lieux/presentation/bloc/comparaison_bloc.dart';

// Messagerie
import 'features/messagerie/data/datasources/messagerie_remote_datasource.dart';
import 'features/messagerie/data/repositories/messagerie_repository_impl.dart';
import 'features/messagerie/domain/repositories/messagerie_repository.dart';
import 'features/messagerie/domain/usecases/envoyer_message.dart';
import 'features/messagerie/domain/usecases/envoyer_photo_message.dart';
import 'features/messagerie/domain/usecases/get_fils_discussion.dart';
import 'features/messagerie/domain/usecases/get_messages.dart';
import 'features/messagerie/domain/usecases/marquer_fil_lu.dart';
import 'features/messagerie/domain/usecases/trouver_fil_locataire.dart';
import 'features/messagerie/presentation/bloc/conversation_bloc.dart';

// Tableau de bord et abonnement
import 'features/abonnement/data/datasources/abonnement_remote_datasource.dart';
import 'features/abonnement/data/repositories/abonnement_repository_impl.dart';
import 'features/abonnement/domain/repositories/abonnement_repository.dart';
import 'features/abonnement/domain/usecases/get_fiche_abonnement.dart';
import 'features/abonnement/domain/usecases/souscrire_abonnement.dart';
import 'features/abonnement/presentation/bloc/abonnement_bloc.dart';
import 'features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';
import 'features/dashboard/domain/usecases/get_tableau_de_bord.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';

// Paramètres
import 'features/parametres/data/datasources/parametres_remote_datasource.dart';
import 'features/parametres/data/repositories/parametres_repository_impl.dart';
import 'features/parametres/domain/repositories/parametres_repository.dart';
import 'features/parametres/domain/usecases/get_parametres.dart';
import 'features/parametres/domain/usecases/modifier_espace_bailleur.dart';
import 'features/parametres/domain/usecases/modifier_reglages.dart';
import 'features/parametres/presentation/bloc/parametres_bloc.dart';

// Espace locataire
import 'features/espace_locataire/data/datasources/espace_locataire_remote_datasource.dart';
import 'features/espace_locataire/data/repositories/espace_locataire_repository_impl.dart';
import 'features/espace_locataire/domain/repositories/espace_locataire_repository.dart';
import 'features/espace_locataire/domain/usecases/accepter_etat_des_lieux.dart';
import 'features/espace_locataire/domain/usecases/ajouter_piece_signalement.dart';
import 'features/espace_locataire/domain/usecases/consentir_whatsapp.dart';
import 'features/espace_locataire/domain/usecases/contester_etat_des_lieux.dart';
import 'features/espace_locataire/domain/usecases/contester_retenue.dart';
import 'features/espace_locataire/domain/usecases/declarer_preuve_paiement.dart';
import 'features/espace_locataire/domain/usecases/get_accueil_locataire.dart';
import 'features/espace_locataire/domain/usecases/get_logements_locataire.dart';
import 'features/espace_locataire/domain/usecases/get_ma_transaction.dart';
import 'features/espace_locataire/domain/usecases/get_mes_cautions.dart';
import 'features/espace_locataire/domain/usecases/get_mes_charges.dart';
import 'features/espace_locataire/domain/usecases/get_mes_echeances.dart';
import 'features/espace_locataire/domain/usecases/get_mes_etats_des_lieux.dart';
import 'features/espace_locataire/domain/usecases/get_mes_incidents.dart';
import 'features/espace_locataire/domain/usecases/get_mes_paiements.dart';
import 'features/espace_locataire/domain/usecases/get_mes_transactions.dart';
import 'features/espace_locataire/domain/usecases/get_mon_etat_des_lieux.dart';
import 'features/espace_locataire/domain/usecases/get_mon_incident.dart';
import 'features/espace_locataire/domain/usecases/get_moyens_paiement_locataire.dart';
import 'features/espace_locataire/domain/usecases/payer_en_ligne.dart';
import 'features/espace_locataire/domain/usecases/signaler_probleme.dart';
import 'features/espace_locataire/domain/usecases/telecharger_mon_etat_des_lieux.dart';
import 'features/espace_locataire/presentation/bloc/accueil_locataire_bloc.dart';
import 'features/espace_locataire/presentation/bloc/suivi_transaction_bloc.dart';
import 'features/espace_locataire/presentation/bloc/cautions_locataire_bloc.dart';
import 'features/espace_locataire/presentation/bloc/etat_des_lieux_locataire_bloc.dart';
import 'features/espace_locataire/presentation/bloc/incident_locataire_bloc.dart';
import 'features/espace_locataire/presentation/bloc/paiement_locataire_bloc.dart';

/// Localisateur de services (même rôle que `sl` dans Sign).
final sl = GetIt.instance;

Future<void> init() async {
  //================================================
  // CORE
  //================================================

  sl.registerLazySingleton(() => TokenService());
  sl.registerLazySingleton(() {
    final api = ApiClient(session: sl());
    // Session non renouvelable : l'AuthBloc ferme la session (bus d'événements, sans BuildContext)
    api.onSessionExpiree = AuthEventBus.instance.emitLogout;
    return api;
  });
  sl.registerLazySingleton(() => ReferentielsService(sl()));
  sl.registerLazySingleton(() => FileAttenteService(sl()));

  //================================================
  // FEATURE — AUTH
  //================================================

  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
      remoteDataSource: sl(), api: sl(), jetons: sl(), fileAttente: sl()));
  sl.registerLazySingleton(() => RestaurerSession(sl()));
  sl.registerLazySingleton(() => Connecter(sl()));
  sl.registerLazySingleton(() => VerifierMfa(sl()));
  sl.registerLazySingleton(() => InscrireProprietaire(sl()));
  sl.registerLazySingleton(() => ActiverLocataire(sl()));
  sl.registerLazySingleton(() => ChangerMotDePasse(sl()));
  sl.registerLazySingleton(() => GetCompte(sl()));
  sl.registerLazySingleton(() => Deconnecter(sl()));
  sl.registerLazySingleton(() => DemanderReinitialisation(sl()));
  sl.registerLazySingleton(() => ReinitialiserMotDePasse(sl()));
  // Session globale : une seule instance, partagée par le routeur et les écrans
  sl.registerLazySingleton(
    () => AuthBloc(
      restaurerSession: sl(),
      connecter: sl(),
      verifierMfa: sl(),
      inscrireProprietaire: sl(),
      activerLocataire: sl(),
      changerMotDePasse: sl(),
      getCompte: sl(),
      deconnecter: sl(),
    ),
  );
  sl.registerFactory(() => MotDePasseOublieBloc(
        demanderReinitialisation: sl(),
        reinitialiserMotDePasse: sl(),
      ));

  //================================================
  // FEATURE — NOTIFICATIONS
  //================================================

  sl.registerLazySingleton<NotificationsRemoteDataSource>(
      () => NotificationsRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetNotifications(sl()));
  sl.registerLazySingleton(() => CompterNotificationsNonLues(sl()));
  sl.registerLazySingleton(() => MarquerNotificationLue(sl()));
  sl.registerLazySingleton(() => ToutLire(sl()));
  sl.registerFactory(() => NotificationsBloc(
        compterNotificationsNonLues: sl(),
        marquerNotificationLue: sl(),
        toutLire: sl(),
      ));

  //================================================
  // FEATURE — DOCUMENTS
  //================================================

  sl.registerLazySingleton<DocumentsRemoteDataSource>(
      () => DocumentsRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<DocumentsRepository>(
      () => DocumentsRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetDocuments(sl()));
  sl.registerLazySingleton(() => AjouterPhotoDocument(sl()));
  sl.registerLazySingleton(() => TelechargerDocument(sl()));
  sl.registerLazySingleton(() => GetLienDocument(sl()));
  sl.registerLazySingleton(() => ChangerVisibiliteDocument(sl()));
  sl.registerLazySingleton(() => SupprimerDocument(sl()));
  // Un bloc par entité affichée : (type, id) passés à la création
  sl.registerFactory(() => DocumentsBloc(
        getDocuments: sl(),
        ajouterPhotoDocument: sl(),
        changerVisibiliteDocument: sl(),
        supprimerDocument: sl(),
        getLienDocument: sl(),
      ));

  //================================================
  // FEATURE — ACCOUNT
  //================================================

  sl.registerLazySingleton<AccountRemoteDataSource>(
      () => AccountRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<AccountRepository>(
      () => AccountRepositoryImpl(remoteDataSource: sl(), jetons: sl()));
  sl.registerLazySingleton(() => ModifierProfil(sl()));
  sl.registerLazySingleton(() => GetSessions(sl()));
  sl.registerLazySingleton(() => RevoquerSession(sl()));
  sl.registerLazySingleton(() => RevoquerToutesSessions(sl()));
  sl.registerLazySingleton(() => InitialiserMfa(sl()));
  sl.registerLazySingleton(() => ActiverMfa(sl()));
  sl.registerLazySingleton(() => DesactiverMfa(sl()));
  sl.registerLazySingleton(() => RegenererCodesSecours(sl()));
  sl.registerFactory(
    () => AccountBloc(
      getSessions: sl(),
      revoquerSession: sl(),
      revoquerToutesSessions: sl(),
      initialiserMfa: sl(),
      activerMfa: sl(),
      desactiverMfa: sl(),
      regenererCodesSecours: sl(),
    ),
  );

  //================================================
  // FEATURE — PATRIMOINE
  //================================================

  // Immeubles (§ 7)
  sl.registerLazySingleton<ImmeubleRemoteDataSource>(
      () => ImmeubleRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<ImmeubleRepository>(
      () => ImmeubleRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetImmeubles(sl()));
  sl.registerLazySingleton(() => GetImmeuble(sl()));
  sl.registerLazySingleton(() => CreerImmeuble(sl()));
  sl.registerLazySingleton(() => ModifierImmeuble(sl()));
  sl.registerLazySingleton(() => SupprimerImmeuble(sl()));
  sl.registerFactory(() => ImmeubleBloc(
        getImmeuble: sl(),
        supprimerImmeuble: sl(),
        getAppartements: sl(),
      ));

  // Appartements (§ 8, § 25)
  sl.registerLazySingleton<AppartementRemoteDataSource>(
      () => AppartementRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<AppartementRepository>(
      () => AppartementRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetAppartements(sl()));
  sl.registerLazySingleton(() => GetFicheAppartement(sl()));
  sl.registerLazySingleton(() => CreerAppartement(sl()));
  sl.registerLazySingleton(() => ModifierAppartement(sl()));
  sl.registerLazySingleton(() => ChangerStatutAppartement(sl()));
  sl.registerLazySingleton(() => SupprimerAppartement(sl()));
  sl.registerFactory(() => AppartementBloc(
        getFicheAppartement: sl(),
        changerStatutAppartement: sl(),
        supprimerAppartement: sl(),
      ));

  // Locataires (§ 9)
  sl.registerLazySingleton<LocataireRemoteDataSource>(
      () => LocataireRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<LocataireRepository>(
      () => LocataireRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetLocataires(sl()));
  sl.registerLazySingleton(() => GetLocataire(sl()));
  sl.registerLazySingleton(() => CreerLocataire(sl()));
  sl.registerLazySingleton(() => ModifierLocataire(sl()));
  sl.registerLazySingleton(() => SupprimerLocataire(sl()));
  sl.registerLazySingleton(() => InviterLocataire(sl()));
  sl.registerLazySingleton(() => EnregistrerConsentementWhatsapp(sl()));
  sl.registerFactory(() => LocataireBloc(
        getLocataire: sl(),
        supprimerLocataire: sl(),
        inviterLocataire: sl(),
        enregistrerConsentementWhatsapp: sl(),
      ));

  // Baux (§ 10, § 53)
  sl.registerLazySingleton<BailRemoteDataSource>(
      () => BailRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<BailRepository>(() => BailRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetBaux(sl()));
  sl.registerLazySingleton(() => GetFicheBail(sl()));
  sl.registerLazySingleton(() => CreerBail(sl()));
  sl.registerLazySingleton(() => ModifierBail(sl()));
  sl.registerLazySingleton(() => ActiverBail(sl()));
  sl.registerLazySingleton(() => AnnulerBail(sl()));
  sl.registerLazySingleton(() => TerminerBail(sl()));
  sl.registerLazySingleton(() => CloturerBail(sl()));
  sl.registerLazySingleton(() => ReviserLoyer(sl()));
  sl.registerLazySingleton(() => GenererContrat(sl()));
  sl.registerFactory(() => BailBloc(
        getFicheBail: sl(),
        activerBail: sl(),
        annulerBail: sl(),
        cloturerBail: sl(),
      ));

  //================================================
  // FEATURE — LOYERS ET PAIEMENTS
  //================================================

  // Échéances (§ 11)
  sl.registerLazySingleton<EcheanceRemoteDataSource>(
      () => EcheanceRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<EcheanceRepository>(
      () => EcheanceRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetEcheances(sl()));
  sl.registerLazySingleton(() => AnnulerEcheance(sl()));

  // Quittances (§ 13)
  sl.registerLazySingleton<QuittanceRemoteDataSource>(
      () => QuittanceRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<QuittanceRepository>(
      () => QuittanceRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetQuittances(sl()));
  sl.registerLazySingleton(() => TelechargerQuittance(sl()));

  // Paiements, transactions, rapprochements, moyens (§ 12, § 51)
  sl.registerLazySingleton<PaiementRemoteDataSource>(
      () => PaiementRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<PaiementRepository>(
      () => PaiementRepositoryImpl(sl()));
  sl.registerLazySingleton(() => EncaisserPaiement(sl()));
  sl.registerLazySingleton(() => GetPaiements(sl()));
  sl.registerLazySingleton(() => GetFichePaiement(sl()));
  sl.registerLazySingleton(() => RembourserPaiement(sl()));
  sl.registerLazySingleton(() => GetTransactions(sl()));
  sl.registerLazySingleton(() => GetTransaction(sl()));
  sl.registerLazySingleton(() => ValiderTransaction(sl()));
  sl.registerLazySingleton(() => RejeterTransaction(sl()));
  sl.registerLazySingleton(() => GetRapprochements(sl()));
  sl.registerLazySingleton(() => ResoudreRapprochement(sl()));
  sl.registerLazySingleton(() => RejeterRapprochement(sl()));
  sl.registerLazySingleton(() => GetMoyensPaiement(sl()));
  sl.registerLazySingleton(() => ConfigurerMoyenPaiement(sl()));
  sl.registerFactory(() => PaiementBloc(
        getFichePaiement: sl(),
      ));
  sl.registerFactory(() => TransactionBloc(
        getTransaction: sl(),
        validerTransaction: sl(),
        rejeterTransaction: sl(),
      ));
  sl.registerFactory(() => MoyensPaiementBloc(
        getMoyensPaiement: sl(),
      ));

  //================================================
  // FEATURE — FACTURES COMMUNES
  //================================================

  sl.registerLazySingleton<FactureCommuneRemoteDataSource>(
      () => FactureCommuneRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<FactureCommuneRepository>(
      () => FactureCommuneRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetFacturesCommunes(sl()));
  sl.registerLazySingleton(() => GetFacturesARepartir(sl()));
  sl.registerLazySingleton(() => GetFactureCommune(sl()));
  sl.registerLazySingleton(() => CreerFactureCommune(sl()));
  sl.registerLazySingleton(() => ModifierFactureCommune(sl()));
  sl.registerLazySingleton(() => JoindreDocumentFacture(sl()));
  sl.registerLazySingleton(() => PrevisualiserRepartition(sl()));
  sl.registerLazySingleton(() => RepartirFacture(sl()));
  sl.registerLazySingleton(() => AnnulerFactureCommune(sl()));
  sl.registerLazySingleton(() => GetChargesRefacturees(sl()));
  sl.registerFactory(() => FactureCommuneBloc(
        getFactureCommune: sl(),
        joindreDocumentFacture: sl(),
        annulerFactureCommune: sl(),
      ));
  sl.registerFactory(() => RepartitionBloc(
        getAppartements: sl(),
        previsualiserRepartition: sl(),
        repartirFacture: sl(),
      ));

  //================================================
  // FEATURE — GESTION FINANCIÈRE
  //================================================

  // Dépenses et catégories (§ 20)
  sl.registerLazySingleton<DepenseRemoteDataSource>(
      () => DepenseRemoteDataSourceImpl(api: sl(), fileAttente: sl()));
  sl.registerLazySingleton<DepenseRepository>(
      () => DepenseRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetDepenses(sl()));
  sl.registerLazySingleton(() => CreerDepense(sl()));
  sl.registerLazySingleton(() => CreerDepenseTravaux(sl()));
  sl.registerLazySingleton(() => ModifierDepense(sl()));
  sl.registerLazySingleton(() => AnnulerDepense(sl()));
  sl.registerLazySingleton(() => AjouterJustificatifDepense(sl()));
  sl.registerLazySingleton(() => GetCategoriesDepenses(sl()));
  sl.registerLazySingleton(() => CreerCategorieDepense(sl()));
  sl.registerLazySingleton(() => ModifierCategorieDepense(sl()));
  sl.registerLazySingleton(() => DesactiverCategorieDepense(sl()));
  sl.registerFactory(() => CategoriesBloc(
        getCategoriesDepenses: sl(),
        desactiverCategorieDepense: sl(),
      ));

  // Caisse (§ 21)
  sl.registerLazySingleton<CaisseRemoteDataSource>(
      () => CaisseRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<CaisseRepository>(() => CaisseRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetMouvementsCaisse(sl()));
  sl.registerLazySingleton(() => GetSyntheseCaisse(sl()));
  sl.registerLazySingleton(() => AjouterAutreRevenu(sl()));
  sl.registerLazySingleton(() => AnnulerMouvementCaisse(sl()));

  // Cautions (§ 55)
  sl.registerLazySingleton<CautionRemoteDataSource>(
      () => CautionRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<CautionRepository>(
      () => CautionRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetCautions(sl()));
  sl.registerLazySingleton(() => GetCaution(sl()));
  sl.registerLazySingleton(() => VerserCaution(sl()));
  sl.registerLazySingleton(() => RestituerCaution(sl()));
  sl.registerLazySingleton(() => AjouterJustificatifCaution(sl()));
  sl.registerLazySingleton(() => RetenirCaution(sl()));
  sl.registerLazySingleton(() => RepondreContestation(sl()));
  sl.registerFactory(() => CautionBloc(
        getCaution: sl(),
      ));

  // Rapports (§ 26)
  sl.registerLazySingleton<RapportRemoteDataSource>(
      () => RapportRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<RapportRepository>(
      () => RapportRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetRapportFinancier(sl()));
  sl.registerLazySingleton(() => GetRapportImmobilier(sl()));
  sl.registerLazySingleton(() => GetRapportLocataires(sl()));
  sl.registerLazySingleton(() => GetRapportTravaux(sl()));
  sl.registerLazySingleton(() => GetRentabilite(sl()));
  sl.registerLazySingleton(() => ExporterRapportCsv(sl()));

  //================================================
  // FEATURE — TRAVAUX
  //================================================

  // Artisans (§ 24)
  sl.registerLazySingleton<ArtisanRemoteDataSource>(
      () => ArtisanRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<ArtisanRepository>(
      () => ArtisanRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetArtisans(sl()));
  sl.registerLazySingleton(() => GetArtisan(sl()));
  sl.registerLazySingleton(() => CreerArtisan(sl()));
  sl.registerLazySingleton(() => ModifierArtisan(sl()));
  sl.registerLazySingleton(() => DefinirActiviteArtisan(sl()));
  sl.registerLazySingleton(() => SupprimerArtisan(sl()));
  sl.registerFactory(() => ArtisanBloc(
        getArtisan: sl(),
        definirActiviteArtisan: sl(),
        supprimerArtisan: sl(),
      ));

  // Travaux (§ 18, § 19)
  sl.registerLazySingleton<TravauxRemoteDataSource>(
      () => TravauxRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<TravauxRepository>(
      () => TravauxRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetTravauxListe(sl()));
  sl.registerLazySingleton(() => GetTravaux(sl()));
  sl.registerLazySingleton(() => CreerTravaux(sl()));
  sl.registerLazySingleton(() => ModifierTravaux(sl()));
  sl.registerLazySingleton(() => ChangerStatutTravaux(sl()));
  sl.registerLazySingleton(() => AjouterPhotoTravaux(sl()));
  sl.registerLazySingleton(() => SupprimerPhotoTravaux(sl()));
  sl.registerFactory(() => TravauxBloc(
        getTravaux: sl(),
        ajouterPhotoTravaux: sl(),
        supprimerPhotoTravaux: sl(),
      ));

  // Incidents (§ 22, § 23)
  sl.registerLazySingleton<IncidentRemoteDataSource>(
      () => IncidentRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<IncidentRepository>(
      () => IncidentRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetIncidents(sl()));
  sl.registerLazySingleton(() => GetIncident(sl()));
  sl.registerLazySingleton(() => CreerIncident(sl()));
  sl.registerLazySingleton(() => AnalyserIncident(sl()));
  sl.registerLazySingleton(() => ResoudreIncident(sl()));
  sl.registerLazySingleton(() => RejeterIncident(sl()));
  sl.registerLazySingleton(() => PlanifierTravaux(sl()));
  sl.registerFactory(() => IncidentBloc(
        getIncident: sl(),
        analyserIncident: sl(),
        resoudreIncident: sl(),
        rejeterIncident: sl(),
      ));

  // États des lieux (§ 52)
  sl.registerLazySingleton<EtatDesLieuxRemoteDataSource>(
      () => EtatDesLieuxRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<EtatDesLieuxRepository>(
      () => EtatDesLieuxRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetEtatsDesLieux(sl()));
  sl.registerLazySingleton(() => GetEtatDesLieux(sl()));
  sl.registerLazySingleton(() => CreerEtatDesLieux(sl()));
  sl.registerLazySingleton(() => ModifierRelevesEdl(sl()));
  sl.registerLazySingleton(() => SupprimerEtatDesLieux(sl()));
  sl.registerLazySingleton(() => EnregistrerSaisieEdl(sl()));
  sl.registerLazySingleton(() => AjouterPieceEdl(sl()));
  sl.registerLazySingleton(() => RenommerPieceEdl(sl()));
  sl.registerLazySingleton(() => SupprimerPieceEdl(sl()));
  sl.registerLazySingleton(() => AjouterElementEdl(sl()));
  sl.registerLazySingleton(() => PreciserElementEdl(sl()));
  sl.registerLazySingleton(() => SupprimerElementEdl(sl()));
  sl.registerLazySingleton(() => AjouterPhotoEdl(sl()));
  sl.registerLazySingleton(() => SupprimerPhotoEdl(sl()));
  sl.registerLazySingleton(() => SoumettreEtatDesLieux(sl()));
  sl.registerLazySingleton(() => CorrigerEtatDesLieux(sl()));
  sl.registerLazySingleton(() => TelechargerPdfEdl(sl()));
  sl.registerLazySingleton(() => GetComparaisonEdl(sl()));
  sl.registerFactory(() => ComparaisonBloc(
        getComparaisonEdl: sl(),
      ));
  sl.registerFactory(() => EtatDesLieuxBloc(
        getEtatDesLieux: sl(),
        ajouterPieceEdl: sl(),
        renommerPieceEdl: sl(),
        supprimerPieceEdl: sl(),
        ajouterElementEdl: sl(),
        preciserElementEdl: sl(),
        supprimerElementEdl: sl(),
        ajouterPhotoEdl: sl(),
        supprimerPhotoEdl: sl(),
        soumettreEtatDesLieux: sl(),
        supprimerEtatDesLieux: sl(),
        corrigerEtatDesLieux: sl(),
        enregistrerSaisieEdl: sl(),
      ));

  //================================================
  // FEATURE — MESSAGERIE
  //================================================

  sl.registerLazySingleton<MessagerieRemoteDataSource>(
      () => MessagerieRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<MessagerieRepository>(
      () => MessagerieRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetFilsDiscussion(sl()));
  sl.registerLazySingleton(() => TrouverFilLocataire(sl()));
  sl.registerFactory(() => ConversationBloc(
        getMessages: sl(),
        marquerFilLu: sl(),
        trouverFilLocataire: sl(),
        envoyerMessage: sl(),
        envoyerPhotoMessage: sl(),
      ));
  sl.registerLazySingleton(() => GetMessages(sl()));
  sl.registerLazySingleton(() => MarquerFilLu(sl()));
  sl.registerLazySingleton(() => EnvoyerMessage(sl()));
  sl.registerLazySingleton(() => EnvoyerPhotoMessage(sl()));

  //================================================
  // FEATURE — TABLEAU DE BORD ET ABONNEMENT
  //================================================

  // Tableau de bord (§ 6, § 48)
  sl.registerLazySingleton<DashboardRemoteDataSource>(
      () => DashboardRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<DashboardRepository>(
      () => DashboardRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetTableauDeBord(sl()));
  sl.registerFactory(() => DashboardBloc(
        getTableauDeBord: sl(),
      ));

  // Abonnement (§ 31)
  sl.registerLazySingleton<AbonnementRemoteDataSource>(
      () => AbonnementRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<AbonnementRepository>(
      () => AbonnementRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetFicheAbonnement(sl()));
  sl.registerLazySingleton(() => SouscrireAbonnement(sl()));
  sl.registerFactory(() => AbonnementBloc(
        getFicheAbonnement: sl(),
        souscrireAbonnement: sl(),
      ));

  //================================================
  // FEATURE — PARAMÈTRES
  //================================================

  sl.registerLazySingleton<ParametresRemoteDataSource>(
      () => ParametresRemoteDataSourceImpl(api: sl()));
  sl.registerLazySingleton<ParametresRepository>(
      () => ParametresRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetParametres(sl()));
  sl.registerLazySingleton(() => ModifierReglages(sl()));
  sl.registerLazySingleton(() => ModifierEspaceBailleur(sl()));
  sl.registerFactory(() => ParametresBloc(
        getParametres: sl(),
        modifierReglages: sl(),
      ));

  //================================================
  // FEATURE — ESPACE LOCATAIRE
  //================================================

  sl.registerLazySingleton<EspaceLocataireRemoteDataSource>(
      () => EspaceLocataireRemoteDataSourceImpl(api: sl(), fileAttente: sl()));
  sl.registerLazySingleton<EspaceLocataireRepository>(
      () => EspaceLocataireRepositoryImpl(sl()));
  sl.registerLazySingleton(() => AccepterEtatDesLieux(sl()));
  sl.registerLazySingleton(() => AjouterPieceSignalement(sl()));
  sl.registerLazySingleton(() => ConsentirWhatsapp(sl()));
  sl.registerLazySingleton(() => ContesterEtatDesLieux(sl()));
  sl.registerLazySingleton(() => ContesterRetenue(sl()));
  sl.registerLazySingleton(() => DeclarerPreuvePaiement(sl()));
  sl.registerLazySingleton(() => GetAccueilLocataire(sl()));
  sl.registerLazySingleton(() => GetLogementsLocataire(sl()));
  sl.registerLazySingleton(() => GetMaTransaction(sl()));
  sl.registerLazySingleton(() => GetMesCautions(sl()));
  sl.registerLazySingleton(() => GetMesCharges(sl()));
  sl.registerLazySingleton(() => GetMesEcheances(sl()));
  sl.registerLazySingleton(() => GetMesEtatsDesLieux(sl()));
  sl.registerLazySingleton(() => GetMesIncidents(sl()));
  sl.registerLazySingleton(() => GetMesPaiements(sl()));
  sl.registerLazySingleton(() => GetMesTransactions(sl()));
  sl.registerLazySingleton(() => GetMonEtatDesLieux(sl()));
  sl.registerLazySingleton(() => GetMonIncident(sl()));
  sl.registerLazySingleton(() => GetMoyensPaiementLocataire(sl()));
  sl.registerLazySingleton(() => PayerEnLigne(sl()));
  sl.registerLazySingleton(() => SignalerProbleme(sl()));
  sl.registerLazySingleton(() => TelechargerMonEtatDesLieux(sl()));
  sl.registerFactory(() => SuiviTransactionBloc(getMaTransaction: sl()));
  sl.registerFactory(() => AccueilLocataireBloc(
        getAccueilLocataire: sl(),
      ));
  sl.registerFactory(() => CautionsLocataireBloc(
        getMesCautions: sl(),
        contesterRetenue: sl(),
      ));
  sl.registerFactory(() => PaiementLocataireBloc(
        getMoyensPaiementLocataire: sl(),
        payerEnLigne: sl(),
      ));
  sl.registerFactory(() => IncidentLocataireBloc(
        getMonIncident: sl(),
        ajouterPieceSignalement: sl(),
      ));
  sl.registerFactory(() => EtatDesLieuxLocataireBloc(
        getMonEtatDesLieux: sl(),
        accepterEtatDesLieux: sl(),
        contesterEtatDesLieux: sl(),
      ));
}
