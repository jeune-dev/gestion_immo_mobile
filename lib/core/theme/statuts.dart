import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Ton visuel d'un statut.
enum TonStatut { succes, avertissement, danger, info, neutre }

/// Famille de statuts renvoyés par l'API (champ `status`).
enum FamilleStatut {
  echeance,
  charge,
  bail,
  appartement,
  incident,
  travaux,
  transaction,
  paiement,
  caution,
  abonnement,
  etatDesLieux,
  priorite
}

/// Ton de chaque code de statut de l'API (tokens.json › tonsDesStatuts).
///
/// Les LIBELLÉS à afficher viennent de `GET /api/v1/referentiels` : ne pas les
/// réécrire dans l'application.
const Map<FamilleStatut, Map<String, TonStatut>> tonsDesStatuts = {
  FamilleStatut.echeance: {
    'a_venir': TonStatut.neutre,
    'a_payer': TonStatut.avertissement,
    'partiellement_paye': TonStatut.avertissement,
    'paye': TonStatut.succes,
    'en_retard': TonStatut.danger,
    'annule': TonStatut.neutre,
  },
  FamilleStatut.charge: {
    'a_payer': TonStatut.avertissement,
    'partiellement_paye': TonStatut.avertissement,
    'paye': TonStatut.succes,
    'en_retard': TonStatut.danger,
    'annule': TonStatut.neutre,
  },
  FamilleStatut.bail: {
    'brouillon': TonStatut.neutre,
    'actif': TonStatut.succes,
    'termine': TonStatut.neutre,
    'clos': TonStatut.neutre,
    'annule': TonStatut.neutre,
  },
  FamilleStatut.appartement: {
    'disponible': TonStatut.info,
    'occupe': TonStatut.succes,
    'en_travaux': TonStatut.avertissement,
    'indisponible': TonStatut.neutre,
  },
  FamilleStatut.incident: {
    'signale': TonStatut.avertissement,
    'en_analyse': TonStatut.info,
    'travaux_planifies': TonStatut.info,
    'resolu': TonStatut.succes,
    'rejete': TonStatut.neutre,
  },
  FamilleStatut.travaux: {
    'signale': TonStatut.avertissement,
    'a_valider': TonStatut.avertissement,
    'valide': TonStatut.info,
    'artisan_assigne': TonStatut.info,
    'en_cours': TonStatut.info,
    'termine': TonStatut.succes,
    'annule': TonStatut.neutre,
  },
  FamilleStatut.transaction: {
    'initiee': TonStatut.neutre,
    'en_attente': TonStatut.avertissement,
    'confirmee': TonStatut.succes,
    'a_rapprocher': TonStatut.avertissement,
    'echouee': TonStatut.danger,
    'annulee': TonStatut.neutre,
    'remboursee': TonStatut.neutre,
  },
  FamilleStatut.paiement: {
    'valide': TonStatut.succes,
    'rembourse': TonStatut.neutre
  },
  FamilleStatut.caution: {
    'attendue': TonStatut.avertissement,
    'partiellement_versee': TonStatut.avertissement,
    'detenue': TonStatut.info,
    'restitution_en_cours': TonStatut.avertissement,
    'retenue_partielle': TonStatut.info,
    'restituee': TonStatut.succes,
    'litige': TonStatut.danger,
  },
  FamilleStatut.abonnement: {
    'essai': TonStatut.info,
    'actif': TonStatut.succes,
    'expire': TonStatut.danger,
    'suspendu': TonStatut.danger,
    'annule': TonStatut.neutre,
  },
  FamilleStatut.etatDesLieux: {
    'brouillon': TonStatut.neutre,
    'soumis': TonStatut.avertissement,
    'accepte': TonStatut.succes,
    'conteste': TonStatut.danger,
    'remplace': TonStatut.neutre,
  },
  FamilleStatut.priorite: {
    'basse': TonStatut.neutre,
    'normale': TonStatut.info,
    'haute': TonStatut.avertissement,
    'urgente': TonStatut.danger
  },
};

/// Ton d'un code (neutre si le code est inconnu : nouvelle valeur côté API).
TonStatut tonDe(FamilleStatut famille, String code) =>
    tonsDesStatuts[famille]?[code] ?? TonStatut.neutre;

/// Couleurs (texte, fond) d'un ton, pour le mode en cours.
({Color texte, Color fond}) couleursDuTon(BuildContext context, TonStatut ton) {
  final p = context.palette;
  return switch (ton) {
    TonStatut.succes => (texte: p.succes, fond: p.succesFond),
    TonStatut.avertissement => (
        texte: p.avertissement,
        fond: p.avertissementFond
      ),
    TonStatut.danger => (texte: p.danger, fond: p.dangerFond),
    TonStatut.info => (texte: p.info, fond: p.infoFond),
    TonStatut.neutre => (texte: p.neutre, fond: p.neutreFond),
  };
}

const _icones = {
  TonStatut.succes: Icons.check_circle_outline,
  TonStatut.avertissement: Icons.schedule,
  TonStatut.danger: Icons.error_outline,
  TonStatut.info: Icons.info_outline,
  TonStatut.neutre: Icons.circle_outlined,
};

/// Badge de statut : icône + LIBELLÉ + couleur (jamais la couleur seule).
///
/// ```dart
/// BadgeStatut(famille: FamilleStatut.echeance, code: e.status, libelle: referentiels.libelle('STATUT_ECHEANCE', e.status))
/// ```
class BadgeStatut extends StatelessWidget {
  final FamilleStatut famille;
  final String code;
  final String libelle;
  const BadgeStatut(
      {super.key,
      required this.famille,
      required this.code,
      required this.libelle});

  @override
  Widget build(BuildContext context) {
    final ton = tonDe(famille, code);
    final c = couleursDuTon(context, ton);
    return Semantics(
      label: libelle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: c.fond, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icones[ton], size: 14, color: c.texte),
            const SizedBox(width: 4),
            Text(
              libelle,
              style: TextStyle(
                  color: c.texte, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
