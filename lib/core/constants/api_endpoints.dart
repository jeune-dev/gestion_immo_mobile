/// Chemins de l'API `/api/v1` utilisés par l'application (référence : `gestion_immo_back/docs/API.md`).
///
/// Comme `Env` dans Sign : aucun chemin n'est écrit en dur dans une source de
/// données, tout passe par ce catalogue.
class ApiEndpoints {
  ApiEndpoints._();

  // ── Authentification ───────────────────────────────────────────────────────
  static const connexion = '/auth/connexion';
  static const mfa = '/auth/mfa';
  static const inscription = '/auth/inscription';
  static const refresh = '/auth/refresh';
  static const deconnexion = '/auth/deconnexion';
  static const motDePasseOublie = '/auth/mot-de-passe-oublie';
  static const reinitialiserMotDePasse = '/auth/reinitialiser-mot-de-passe';
  static const activationLocataire = '/auth/locataire/activation';

  // ── Compte ─────────────────────────────────────────────────────────────────
  static const compte = '/compte';
  static const compteMotDePasse = '/compte/mot-de-passe';
  static const compteSessions = '/compte/sessions';
  static String compteSession(String id) => '/compte/sessions/$id';
  static const mfaInitialiser = '/compte/mfa/initialiser';
  static const mfaActiver = '/compte/mfa/activer';
  static const mfaDesactiver = '/compte/mfa/desactiver';
  static const mfaCodesSecours = '/compte/mfa/codes-secours';

  // ── Commun ─────────────────────────────────────────────────────────────────
  static const referentiels = '/referentiels';
  static const notifications = '/notifications';
  static const notificationsCompteur = '/notifications/compteur';
  static const notificationsToutLire = '/notifications/tout-lire';
  static String notificationLue(String id) => '/notifications/$id/lue';
  static const documents = '/documents';
  static String document(String id) => '/documents/$id';
  static String documentFichier(String id) => '/documents/$id/fichier';
  static String documentLien(String id) => '/documents/$id/lien';

  // ── Tableau de bord ────────────────────────────────────────────────────────
  static const dashboard = '/dashboard';
  static const dashboardGraphiques = '/dashboard/graphiques';

  // ── Patrimoine ─────────────────────────────────────────────────────────────
  static const immeubles = '/immeubles';
  static String immeuble(String id) => '/immeubles/$id';
  static const appartements = '/appartements';
  static String appartement(String id) => '/appartements/$id';
  static String appartementStatut(String id) => '/appartements/$id/statut';
  static String appartementHistorique(String id) =>
      '/appartements/$id/historique';
  static String appartementRentabilite(String id) =>
      '/appartements/$id/rentabilite';
  static const locataires = '/locataires';
  static String locataire(String id) => '/locataires/$id';
  static String locataireInvitation(String id) => '/locataires/$id/invitation';
  static String locataireConsentement(String id) =>
      '/locataires/$id/consentement-whatsapp';
  static const baux = '/baux';
  static String bail(String id) => '/baux/$id';
  static String bailAction(String id, String action) => '/baux/$id/$action';
  static String bailContrats(String id) => '/baux/$id/contrats';

  // ── Loyers et paiements ────────────────────────────────────────────────────
  static const echeances = '/echeances';
  static String echeanceAnnuler(String id) => '/echeances/$id/annuler';
  static const paiements = '/paiements';
  static String paiement(String id) => '/paiements/$id';
  static String paiementQuittances(String id) => '/paiements/$id/quittances';
  static String paiementRembourser(String id) => '/paiements/$id/rembourser';
  static const paiementsEspeces = '/paiements/especes';
  static const transactions = '/paiements/transactions';
  static String transaction(String id) => '/paiements/transactions/$id';
  static String transactionValider(String id) =>
      '/paiements/transactions/$id/valider';
  static String transactionRejeter(String id) =>
      '/paiements/transactions/$id/rejeter';
  static const rapprochements = '/paiements/rapprochements';
  static String rapprochementResoudre(String id) =>
      '/paiements/rapprochements/$id/resoudre';
  static String rapprochementRejeter(String id) =>
      '/paiements/rapprochements/$id/rejeter';
  static const moyensPaiement = '/paiements/moyens';
  static const quittances = '/quittances';
  static String quittancePdf(String id) => '/quittances/$id/pdf';

  // ── Charges, dépenses, caisse, cautions ───────────────────────────────────
  static const facturesCommunes = '/factures-communes';
  static const facturesARepartir = '/factures-communes/a-repartir';
  static String factureCommune(String id) => '/factures-communes/$id';
  static String factureDocument(String id) => '/factures-communes/$id/document';
  static String factureApercu(String id) => '/factures-communes/$id/apercu';
  static String factureRepartir(String id) => '/factures-communes/$id/repartir';
  static String factureAnnuler(String id) => '/factures-communes/$id/annuler';
  static const charges = '/charges';
  static const depenses = '/depenses';
  static String depense(String id) => '/depenses/$id';
  static String depenseAnnuler(String id) => '/depenses/$id/annuler';
  static String depenseJustificatifs(String id) =>
      '/depenses/$id/justificatifs';
  static const categoriesDepenses = '/categories-depenses';
  static String categorieDepense(String id) => '/categories-depenses/$id';
  static String categorieDesactiver(String id) =>
      '/categories-depenses/$id/desactiver';
  static const caisse = '/caisse';
  static const caisseSynthese = '/caisse/synthese';
  static const caisseAutresRevenus = '/caisse/autres-revenus';
  static String caisseAnnuler(String id) => '/caisse/$id/annuler';
  static const cautions = '/cautions';
  static String caution(String id) => '/cautions/$id';
  static String cautionVersements(String id) => '/cautions/$id/versements';
  static String cautionRestitutions(String id) => '/cautions/$id/restitutions';
  static String cautionJustificatifs(String id) =>
      '/cautions/$id/justificatifs';
  static String cautionRetenues(String id) => '/cautions/$id/retenues';
  static String cautionReponse(String id, String transactionId) =>
      '/cautions/$id/retenues/$transactionId/reponse';

  // ── Travaux, artisans, incidents, états des lieux ─────────────────────────
  static const travaux = '/travaux';
  static String travail(String id) => '/travaux/$id';
  static String travauxStatut(String id) => '/travaux/$id/statut';
  static String travauxPhotos(String id) => '/travaux/$id/photos';
  static String travauxPhoto(String id, String photoId) =>
      '/travaux/$id/photos/$photoId';
  static String travauxDepenses(String id) => '/travaux/$id/depenses';
  static const artisans = '/artisans';
  static String artisan(String id) => '/artisans/$id';
  static String artisanActivite(String id, {required bool actif}) =>
      '/artisans/$id/${actif ? 'reactiver' : 'desactiver'}';
  static const incidents = '/incidents';
  static String incident(String id) => '/incidents/$id';
  static String incidentAction(String id, String action) =>
      '/incidents/$id/$action';
  static String incidentTravaux(String id) => '/incidents/$id/travaux';
  static const etatsDesLieux = '/etats-des-lieux';
  static const etatsDesLieuxComparaison = '/etats-des-lieux/comparaison';
  static String etatDesLieux(String id) => '/etats-des-lieux/$id';
  static String etatDesLieuxPdf(String id) => '/etats-des-lieux/$id/pdf';
  static String etatDesLieuxSaisie(String id) => '/etats-des-lieux/$id/saisie';
  static String etatDesLieuxSoumettre(String id) =>
      '/etats-des-lieux/$id/soumettre';
  static String etatDesLieuxCorriger(String id) =>
      '/etats-des-lieux/$id/corriger';
  static String etatDesLieuxPieces(String id) => '/etats-des-lieux/$id/pieces';
  static String etatDesLieuxPiece(String id, String pieceId) =>
      '/etats-des-lieux/$id/pieces/$pieceId';
  static String etatDesLieuxElements(String id, String pieceId) =>
      '/etats-des-lieux/$id/pieces/$pieceId/elements';
  static String etatDesLieuxElement(String id, String elementId) =>
      '/etats-des-lieux/$id/elements/$elementId';
  static String etatDesLieuxElementPhotos(String id, String elementId) =>
      '/etats-des-lieux/$id/elements/$elementId/photos';
  static String etatDesLieuxPhoto(String id, String photoId) =>
      '/etats-des-lieux/$id/photos/$photoId';

  // ── Messagerie ─────────────────────────────────────────────────────────────
  static const filsProprietaire = '/messagerie/fils';
  static String filProprietaireMessages(String id) =>
      '/messagerie/fils/$id/messages';
  static String filProprietaireLu(String id) => '/messagerie/fils/$id/lu';
  static String messageAuLocataire(String tenantId) =>
      '/messagerie/locataires/$tenantId/messages';
  static String photoAuLocataire(String tenantId) =>
      '/messagerie/locataires/$tenantId/photos';

  // ── Rapports, paramètres, abonnement ──────────────────────────────────────
  static String rapport(String type) => '/rapports/$type';
  static const parametres = '/parametres';
  static const parametresProfil = '/parametres/profil';
  static const abonnement = '/abonnement';
  static const abonnementPlans = '/abonnement/plans';
  static const abonnementPaiements = '/abonnement/paiements';
  static const abonnementSouscrire = '/abonnement/souscrire';

  // ── Espace locataire ───────────────────────────────────────────────────────
  static const locAccueil = '/locataire/accueil';
  static const locLogement = '/locataire/logement';
  static const locEcheances = '/locataire/echeances';
  static const locPaiements = '/locataire/paiements';
  static const locPaiementsMoyens = '/locataire/paiements/moyens';
  static const locPreuves = '/locataire/paiements/preuves';
  static const locTransactions = '/locataire/paiements/transactions';
  static String locTransaction(String id) =>
      '/locataire/paiements/transactions/$id';
  static const locQuittances = '/locataire/quittances';
  static String locQuittancePdf(String id) => '/locataire/quittances/$id/pdf';
  static const locCaution = '/locataire/caution';
  static String locContesterRetenue(String transactionId) =>
      '/locataire/caution/retenues/$transactionId/contester';
  static const locCharges = '/locataire/charges';
  static const locIncidents = '/locataire/incidents';
  static String locIncident(String id) => '/locataire/incidents/$id';
  static String locIncidentPieces(String id) =>
      '/locataire/incidents/$id/pieces';
  static const locEtatsDesLieux = '/locataire/etats-des-lieux';
  static String locEtatDesLieux(String id) => '/locataire/etats-des-lieux/$id';
  static String locEtatDesLieuxPdf(String id) =>
      '/locataire/etats-des-lieux/$id/pdf';
  static String locEtatDesLieuxAction(String id, String action) =>
      '/locataire/etats-des-lieux/$id/$action';
  static const locFils = '/locataire/messagerie';
  static String locFilMessages(String id) =>
      '/locataire/messagerie/$id/messages';
  static String locFilPhotos(String id) => '/locataire/messagerie/$id/photos';
  static String locFilLu(String id) => '/locataire/messagerie/$id/lu';
  static const locConsentement = '/locataire/consentement-whatsapp';
}
