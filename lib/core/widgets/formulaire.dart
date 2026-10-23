import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gestion_immo_mobile/core/validation/identifiant_validator.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';
import 'actions.dart';

enum TypeChamp {
  texte,
  multiligne,
  montant,
  entier,
  decimal,
  date,
  selection,
  interrupteur,
  telephone,
  email,
  motDePasse,
  entite
}

/// Description d'un champ : le formulaire gère la saisie, la conversion des types
/// et n'envoie que les champs décrits (jamais de champ inventé, contrat § 4).
class Champ {
  final String nom;
  final String libelle;
  final TypeChamp type;
  final bool obligatoire;

  /// Famille du référentiel pour une sélection (ex. `type_appartement`).
  final String? referentiel;

  /// Options fixes (code, libellé) quand elles ne viennent pas du référentiel.
  final List<OptionRef>? options;
  final String? indice;
  final num? min;
  final num? max;
  final int? maxLongueur;

  /// Longueur minimale d'une saisie libre (la même que le schéma de l'API).
  final int? minLongueur;

  /// Format attendu d'une saisie libre : (expression régulière, message affiché
  /// s'il n'est pas respecté).
  final (String, String)? format;

  /// Sélection d'une entité de l'API (immeuble, appartement, locataire, bail…).
  final SourceEntite<dynamic>? entite;

  /// Envoyé à `null` quand il est vidé (pour effacer une valeur).
  final bool nullable;

  /// Affichage conditionnel selon les autres valeurs saisies.
  final bool Function(Map<String, dynamic> valeurs)? visible;

  const Champ(
    this.nom,
    this.libelle, {
    this.type = TypeChamp.texte,
    this.obligatoire = false,
    this.referentiel,
    this.options,
    this.indice,
    this.min,
    this.max,
    this.maxLongueur,
    this.minLongueur,
    this.format,
    this.entite,
    this.nullable = false,
    this.visible,
  });
}

/// Formulaire plein écran. [envoyer] reçoit le corps prêt à poster.
class EcranFormulaire extends StatefulWidget {
  final String titre;
  final List<Champ> champs;
  final Map<String, dynamic> initial;

  final Future<dynamic> Function(Map<String, dynamic> corps) envoyer;
  final String libelleEnvoi;
  final Widget? intro;
  final String? messageSucces;

  const EcranFormulaire({
    super.key,
    required this.titre,
    required this.champs,
    required this.envoyer,
    this.initial = const {},
    this.libelleEnvoi = 'Enregistrer',
    this.intro,
    this.messageSucces,
  });

  /// Ouvre le formulaire ; renvoie le résultat de [envoyer] si l'envoi a réussi.
  static Future<T?> ouvrir<T>(BuildContext context, EcranFormulaire f) =>
      Navigator.of(context).push<T>(
          MaterialPageRoute(builder: (_) => f, fullscreenDialog: true));

  @override
  State<EcranFormulaire> createState() => _EcranFormulaireState();
}

class _EcranFormulaireState extends State<EcranFormulaire> {
  final _form = GlobalKey<FormState>();
  late final Map<String, dynamic> _valeurs;
  final Map<String, String> _libellesEntites = {};
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _valeurs = {
      for (final c in widget.champs)
        c.nom: switch (c.type) {
          TypeChamp.interrupteur => widget.initial[c.nom] == true,
          TypeChamp.date => _dateInitiale(widget.initial[c.nom]),
          _ => widget.initial[c.nom],
        },
    };
    for (final c in widget.champs.where((c) => c.type == TypeChamp.entite)) {
      final l = widget.initial['${c.nom}__libelle'];
      if (l != null) _libellesEntites[c.nom] = '$l';
    }
  }

  /// « AAAA-MM-JJ » depuis une date ou une date-heure de l'API (null si illisible).
  static String? _dateInitiale(dynamic v) {
    final d = v is String ? DateTime.tryParse(v) : null;
    return d == null ? null : versApi(d);
  }

  bool _visible(Champ c) => c.visible == null || c.visible!(_valeurs);

  /// Un champ affiché sous condition peut dépendre d'une saisie libre.
  late final bool _conditionnel = widget.champs.any((c) => c.visible != null);

  Map<String, dynamic> _corps() {
    final corps = <String, dynamic>{};
    for (final c in widget.champs.where(_visible)) {
      final v = _valeurs[c.nom];
      final initiale = widget.initial[c.nom];
      dynamic sortie;
      switch (c.type) {
        case TypeChamp.interrupteur:
          sortie = v == true;
        case TypeChamp.montant:
          sortie = v is int ? v : lireMontant('${v ?? ''}');
        case TypeChamp.entier:
          sortie = v is int ? v : int.tryParse('${v ?? ''}'.trim());
        case TypeChamp.decimal:
          sortie = v is num
              ? v
              : num.tryParse('${v ?? ''}'.trim().replaceAll(',', '.'));
        default:
          final s = v == null ? '' : '$v'.trim();
          sortie = s.isEmpty ? null : s;
      }
      if (sortie == null) {
        if (c.nullable || (initiale != null && initiale != '')) {
          corps[c.nom] = null;
        }
      } else {
        corps[c.nom] = sortie;
      }
    }
    return corps;
  }

  Future<void> _valider() async {
    if (!_form.currentState!.validate()) return;
    for (final c in widget.champs.where(_visible)) {
      if (c.obligatoire &&
          (c.type == TypeChamp.selection ||
              c.type == TypeChamp.entite ||
              c.type == TypeChamp.date) &&
          _valeurs[c.nom] == null) {
        return afficherErreur(context, '« ${c.libelle} » est obligatoire');
      }
    }
    setState(() => _envoi = true);
    try {
      final r = await widget.envoyer(_corps());
      if (!mounted) return;
      if (widget.messageSucces != null) {
        afficherSucces(context, widget.messageSucces!);
      }
      Navigator.of(context).pop(r ?? true);
    } catch (e) {
      if (mounted) afficherErreurApi(context, e);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  String? _valider1(Champ c, String? s) {
    final v = (s ?? '').trim();
    if (c.obligatoire && v.isEmpty) return 'Obligatoire';
    if (v.isEmpty) return null;
    if (c.minLongueur != null && v.length < c.minLongueur!) {
      return '${c.minLongueur} caractères minimum';
    }
    final format = c.format;
    if (format != null && !RegExp(format.$1).hasMatch(v)) return format.$2;
    if (c.type == TypeChamp.email) {
      final erreur = IdentifiantValidator.email(v).erreurFormulaire;
      if (erreur != null) return erreur;
    }
    if (c.type == TypeChamp.entier ||
        c.type == TypeChamp.montant ||
        c.type == TypeChamp.decimal) {
      final n = c.type == TypeChamp.montant
          ? lireMontant(v)
          : num.tryParse(v.replaceAll(',', '.'));
      if (n == null) return 'Nombre invalide';
      if (c.min != null && n < c.min!) return 'Minimum ${c.min}';
      if (c.max != null && n > c.max!) return 'Maximum ${c.max}';
    }
    return null;
  }

  Widget _champ(Champ c) {
    final libelle = '${c.libelle}${c.obligatoire ? ' *' : ''}';
    final deco = InputDecoration(
        labelText: libelle, helperText: c.indice, helperMaxLines: 3);
    switch (c.type) {
      case TypeChamp.interrupteur:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(c.libelle),
          subtitle: c.indice == null ? null : Text(c.indice!),
          value: _valeurs[c.nom] == true,
          onChanged: (v) => setState(() => _valeurs[c.nom] = v),
        );
      case TypeChamp.selection:
        final options = c.options ?? refs.options(c.referentiel ?? '');
        return DropdownButtonFormField<String>(
          initialValue: options.any((o) => o.code == _valeurs[c.nom])
              ? _valeurs[c.nom] as String
              : null,
          decoration: deco,
          isExpanded: true,
          items: [
            if (!c.obligatoire)
              const DropdownMenuItem<String>(value: null, child: Text('—')),
            for (final o in options)
              DropdownMenuItem(
                value: o.code,
                child: Text(o.label, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => setState(() => _valeurs[c.nom] = v),
        );
      case TypeChamp.date:
        final v = _valeurs[c.nom] as String?;
        return InkWell(
          onTap: () async {
            final init = (v == null ? null : DateTime.tryParse(v)) ??
                DateTime.now();
            final d = await showDatePicker(
              context: context,
              initialDate: init,
              // Bornes larges : une date initiale hors bornes fait échouer le sélecteur
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              locale: const Locale('fr'),
            );
            if (d != null && mounted) {
              setState(() => _valeurs[c.nom] = versApi(d));
            }
          },
          child: InputDecorator(
            decoration: deco.copyWith(
                suffixIcon: const Icon(Icons.calendar_today, size: 18)),
            child: Text(v == null ? 'Choisir une date' : date(v)),
          ),
        );
      case TypeChamp.entite:
        return InkWell(
          onTap: () async {
            final choix =
                await choisirEntite(context, c.entite!, titre: c.libelle);
            if (choix != null && mounted) {
              setState(() {
                _valeurs[c.nom] = choix.id;
                _libellesEntites[c.nom] = choix.libelle;
              });
            }
          },
          child: InputDecorator(
            decoration: deco.copyWith(
              suffixIcon: _valeurs[c.nom] != null && !c.obligatoire
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() {
                        _valeurs[c.nom] = null;
                        _libellesEntites.remove(c.nom);
                      }),
                    )
                  : const Icon(Icons.arrow_drop_down),
            ),
            child: Text(_libellesEntites[c.nom] ??
                (_valeurs[c.nom] == null ? 'Choisir' : 'Sélectionné')),
          ),
        );
      default:
        final clavier = switch (c.type) {
          TypeChamp.montant || TypeChamp.entier => TextInputType.number,
          TypeChamp.decimal =>
            const TextInputType.numberWithOptions(decimal: true),
          TypeChamp.telephone => TextInputType.phone,
          TypeChamp.email => TextInputType.emailAddress,
          TypeChamp.multiligne => TextInputType.multiline,
          _ => TextInputType.text,
        };
        final initial = _valeurs[c.nom];
        return TextFormField(
          initialValue: initial == null
              ? null
              : c.type == TypeChamp.montant && initial is num
                  ? nombre(initial)
                  : '$initial',
          decoration: deco.copyWith(
              suffixText: c.type == TypeChamp.montant ? 'FCFA' : null),
          keyboardType: clavier,
          obscureText: c.type == TypeChamp.motDePasse,
          maxLines: c.type == TypeChamp.multiligne ? 5 : 1,
          minLines: c.type == TypeChamp.multiligne ? 3 : 1,
          maxLength: c.maxLongueur,
          inputFormatters: [
            if (c.type == TypeChamp.montant) _SeparateurMilliers(),
            if (c.type == TypeChamp.entier)
              FilteringTextInputFormatter.allow(RegExp(r'-?\d*')),
          ],
          validator: (s) => _valider1(c, s),
          onChanged: (s) {
            _valeurs[c.nom] = s;
            if (_conditionnel) setState(() {});
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titre)),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.espaceLg),
            children: [
              if (widget.intro != null) ...[
                widget.intro!,
                const SizedBox(height: AppTheme.espaceLg)
              ],
              for (final c in widget.champs.where(_visible))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.espaceLg),
                  child: _champ(c),
                ),
              const SizedBox(height: AppTheme.espaceSm),
              FilledButton(
                onPressed: _envoi ? null : _valider,
                child: _envoi
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.libelleEnvoi),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Saisie des montants avec séparateur de milliers (« 350 000 »).
class _SeparateurMilliers extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue ancien, TextEditingValue nouveau) {
    final n = lireMontant(nouveau.text);
    if (n == null) return const TextEditingValue();
    final t = nombre(n);
    // Le curseur garde le même nombre de chiffres à sa droite : une
    // correction au milieu du montant ne le renvoie pas à la fin.
    final fin = nouveau.selection.end.clamp(0, nouveau.text.length);
    var aDroite = RegExp(r'\d').allMatches(nouveau.text.substring(fin)).length;
    var position = t.length;
    while (aDroite > 0 && position > 0) {
      position--;
      if (RegExp(r'\d').hasMatch(t[position])) aDroite--;
    }
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: position),
    );
  }
}
