import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gestion_immo_mobile/core/validation/identifiant_validator.dart';
import 'package:gestion_immo_mobile/core/services/referentiels_service.dart';
import 'package:gestion_immo_mobile/core/theme/app_colors.dart';
import 'package:gestion_immo_mobile/core/theme/app_theme.dart';
import 'package:gestion_immo_mobile/core/utils/format.dart';

import 'actions.dart';
import 'base.dart';

import 'package:gestion_immo_mobile/core/widgets/fond_marque.dart';

enum TypeChamp {
  texte,

  /// Prénom ou nom : lettres, espaces, apostrophes et tirets.
  nom,
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
  entite,
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

  /// Nombre décimal strictement supérieur à 0.
  final bool positif;

  /// Nombre de décimales accepté (même précision que l'API).
  final int? decimales;

  /// Date : argent déjà reçu ou dépensé, jamais dans le futur.
  final bool pasDansLeFutur;

  /// Date : aujourd'hui ou plus tard.
  final bool pasDansLePasse;

  /// Date : pas avant cette date (AAAA-MM-JJ).
  final String? dateMin;

  /// Date : pas avant la valeur de cet autre champ.
  final String? apresChamp;

  /// Avec [apresChamp] : strictement après (une date égale est refusée).
  final bool apresStrict;

  /// Obligatoire selon les autres valeurs saisies.
  final bool Function(Map<String, dynamic> valeurs)? obligatoireSi;

  /// Sélection d'une entité de l'API (immeuble, appartement, locataire, bail…).
  final SourceEntite<dynamic>? entite;

  /// Envoyé à `null` quand il est vidé (pour effacer une valeur).
  final bool nullable;

  /// Affichage conditionnel selon les autres valeurs saisies.
  final bool Function(Map<String, dynamic> valeurs)? visible;

  /// Ouvre une nouvelle carte titrée à partir de ce champ.
  final String? groupe;

  /// Partage sa ligne avec le champ `moitie` voisin.
  final bool moitie;

  final IconData? icone;

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
    this.positif = false,
    this.decimales,
    this.pasDansLeFutur = false,
    this.pasDansLePasse = false,
    this.dateMin,
    this.apresChamp,
    this.apresStrict = false,
    this.obligatoireSi,
    this.entite,
    this.nullable = false,
    this.visible,
    this.groupe,
    this.moitie = false,
    this.icone,
  });
}

/// Plafond des montants de l'API (1 000 milliards de FCFA).
const _montantMax = 1000000000000;

/// Formulaire plein écran. [envoyer] reçoit le corps prêt à poster.
class EcranFormulaire extends StatefulWidget {
  final String titre;
  final List<Champ> champs;
  final Map<String, dynamic> initial;

  final Future<dynamic> Function(Map<String, dynamic> corps) envoyer;

  /// Contrôle portant sur plusieurs champs : renvoie le message d'erreur, ou null.
  final String? Function(Map<String, dynamic> corps)? controle;
  final String libelleEnvoi;
  final Widget? intro;
  final String? messageSucces;

  const EcranFormulaire({
    super.key,
    required this.titre,
    required this.champs,
    required this.envoyer,
    this.controle,
    this.initial = const {},
    this.libelleEnvoi = 'Enregistrer',
    this.intro,
    this.messageSucces,
  });

  /// Ouvre le formulaire ; renvoie le résultat de [envoyer] si l'envoi a réussi.
  static Future<T?> ouvrir<T>(BuildContext context, EcranFormulaire f) =>
      Navigator.of(
        context,
      ).push<T>(MaterialPageRoute(builder: (_) => f, fullscreenDialog: true));

  @override
  State<EcranFormulaire> createState() => _EcranFormulaireState();
}

class _EcranFormulaireState extends State<EcranFormulaire> {
  final _form = GlobalKey<FormState>();
  late final Map<String, dynamic> _valeurs;
  final Map<String, String> _libellesEntites = {};
  bool _envoi = false;

  /// Après un premier envoi refusé, les messages suivent la saisie.
  bool _soumis = false;

  /// Erreurs des champs sans `validator` (date, entité).
  final Map<String, String> _erreurs = {};
  final Map<String, GlobalKey> _cles = {};

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
        case TypeChamp.telephone:
          sortie = IdentifiantValidator.telephone('${v ?? ''}').valeur;
          if (sortie == '') sortie = null;
        case TypeChamp.email:
          final s = '${v ?? ''}'.trim().toLowerCase();
          sortie = s.isEmpty ? null : s;
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
    setState(() {
      _soumis = true;
      _erreurs
        ..clear()
        ..addAll({
          for (final c in widget.champs.where(_visible))
            if (_erreurHorsTexte(c) case final String erreur) c.nom: erreur,
        });
    });
    final invalides = _form.currentState!.validateGranularly();
    if (invalides.isNotEmpty || _erreurs.isNotEmpty) {
      _montrerPremiereErreur([
        for (final f in invalides) f.context,
        for (final nom in _erreurs.keys)
          if (_cles[nom]?.currentContext case final BuildContext c) c,
      ]);
      return;
    }
    final erreur = widget.controle?.call(_corps());
    if (erreur != null) return afficherErreur(context, erreur);
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

  bool _requis(Champ c) =>
      c.obligatoire || (c.obligatoireSi?.call(_valeurs) ?? false);

  /// Fait défiler jusqu'au champ en erreur le plus haut de l'écran.
  void _montrerPremiereErreur(List<BuildContext> champs) {
    if (champs.isEmpty) return;
    double hauteur(BuildContext c) {
      final r = c.findRenderObject();
      return r is RenderBox && r.attached
          ? r.localToGlobal(Offset.zero).dy
          : double.infinity;
    }

    final premier = champs.reduce((a, b) => hauteur(a) <= hauteur(b) ? a : b);
    Scrollable.ensureVisible(
      premier,
      alignment: 0.2,
      duration: const Duration(milliseconds: 200),
    );
  }

  /// Contrôle d'une date ou d'une entité, qui n'ont pas de zone de saisie.
  String? _erreurHorsTexte(Champ c) {
    if (c.type != TypeChamp.date && c.type != TypeChamp.entite) return null;
    final v = _valeurs[c.nom] as String?;
    if (v == null || v.isEmpty) return _requis(c) ? 'Obligatoire' : null;
    if (c.type == TypeChamp.entite) return null;
    final jour = aujourdhui();
    if (c.pasDansLeFutur && v.compareTo(jour) > 0) {
      return 'Ne peut pas être dans le futur';
    }
    if (c.pasDansLePasse && v.compareTo(jour) < 0) {
      return "Ne peut pas être antérieure à aujourd'hui";
    }
    final min = c.dateMin;
    if (min != null && v.compareTo(min) < 0) {
      return 'Ne peut pas être avant le ${date(min)}';
    }
    final nomAutre = c.apresChamp;
    final autre = nomAutre == null ? null : _valeurs[nomAutre] as String?;
    if (autre != null) {
      final ecart = v.compareTo(autre);
      if (ecart < 0 || (c.apresStrict && ecart == 0)) {
        final libelle = widget.champs
            .firstWhere((x) => x.nom == nomAutre)
            .libelle;
        return c.apresStrict
            ? 'Doit être après « $libelle »'
            : 'Ne peut pas être avant « $libelle »';
      }
    }
    return null;
  }

  String? _valider1(Champ c, String? s) {
    final v = (s ?? '').trim();
    if (_requis(c) && v.isEmpty) return 'Obligatoire';
    if (v.isEmpty) return null;
    if (c.type == TypeChamp.nom) {
      final erreur = IdentifiantValidator.nom(v).erreurFormulaire;
      if (erreur != null) return erreur;
    }
    if (c.type == TypeChamp.telephone) {
      final erreur = IdentifiantValidator.telephone(v).erreurFormulaire;
      if (erreur != null) return erreur;
    }
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
      final estMontant = c.type == TypeChamp.montant;
      final max = estMontant ? (c.max ?? _montantMax) : c.max;
      String affiche(num x) => estMontant ? montant(x) : '$x';
      if (c.min != null && n < c.min!) return 'Minimum ${affiche(c.min!)}';
      if (max != null && n > max) return 'Maximum ${affiche(max)}';
      if (c.positif && n <= 0) return 'Doit être supérieur à 0';
      final decimales = c.decimales;
      if (decimales != null) {
        final partie = v.replaceAll(',', '.').split('.');
        if (partie.length > 1 && partie[1].length > decimales) {
          return '$decimales décimales maximum';
        }
      }
    }
    return null;
  }

  Widget _champ(Champ c) {
    final libelle = '${c.libelle}${_requis(c) ? ' *' : ''}';
    final deco = InputDecoration(
      labelText: libelle,
      helperText: c.indice,
      helperMaxLines: 3,
      prefixIcon: c.icone == null ? null : Icon(c.icone),
      errorText: _erreurs[c.nom],
      errorMaxLines: 2,
      // Compteur réservé aux longs textes : il encombre les champs courts.
      counterText: c.type == TypeChamp.multiligne ? null : '',
    );
    final p = context.palette;
    final styleValeur = Theme.of(context).textTheme.bodyLarge!
        .copyWith(color: p.texte, fontSize: 16, fontWeight: FontWeight.w400);
    final stylePlaceholder = styleValeur.copyWith(color: p.texteDiscret);
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
          validator: (v) => _requis(c) && v == null ? 'Obligatoire' : null,
          isExpanded: true,
          isDense: true,
          style: styleValeur,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: [
            if (!_requis(c))
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
          key: _cles.putIfAbsent(c.nom, GlobalKey.new),
          onTap: () async {
            final maintenant = DateTime.now();
            final jour = DateTime(
              maintenant.year,
              maintenant.month,
              maintenant.day,
            );
            final premier = c.pasDansLePasse ? jour : DateTime(1900);
            final dernier = c.pasDansLeFutur ? jour : DateTime(2100);
            var init = (v == null ? null : DateTime.tryParse(v)) ?? jour;
            // Une date initiale hors bornes fait échouer le sélecteur.
            if (init.isBefore(premier)) init = premier;
            if (init.isAfter(dernier)) init = dernier;
            final d = await showDatePicker(
              context: context,
              initialDate: init,
              firstDate: premier,
              lastDate: dernier,
              locale: const Locale('fr'),
            );
            if (d != null && mounted) {
              setState(() {
                _valeurs[c.nom] = versApi(d);
                _erreurs.remove(c.nom);
              });
            }
          },
          child: InputDecorator(
            decoration: deco.copyWith(
              suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(
              v == null ? 'Choisir' : date(v),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: v == null ? stylePlaceholder : styleValeur,
            ),
          ),
        );
      case TypeChamp.entite:
        return InkWell(
          key: _cles.putIfAbsent(c.nom, GlobalKey.new),
          onTap: () async {
            final choix = await choisirEntite(
              context,
              c.entite!,
              titre: c.libelle,
            );
            if (choix != null && mounted) {
              setState(() {
                _valeurs[c.nom] = choix.id;
                _erreurs.remove(c.nom);
                _libellesEntites[c.nom] = choix.libelle;
              });
            }
          },
          child: InputDecorator(
            decoration: deco.copyWith(
              suffixIcon: _valeurs[c.nom] != null && !_requis(c)
                  ? IconButton(
                      tooltip: 'Effacer',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() {
                        _valeurs[c.nom] = null;
                        _libellesEntites.remove(c.nom);
                      }),
                    )
                  : const Icon(Icons.keyboard_arrow_down),
            ),
            child: Text(
              _libellesEntites[c.nom] ??
                  (_valeurs[c.nom] == null ? 'Choisir' : 'Sélectionné'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _valeurs[c.nom] == null ? stylePlaceholder : styleValeur,
            ),
          ),
        );
      default:
        final clavier = switch (c.type) {
          TypeChamp.montant || TypeChamp.entier => TextInputType.number,
          TypeChamp.decimal => const TextInputType.numberWithOptions(
            decimal: true,
          ),
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
            suffixText: c.type == TypeChamp.montant ? 'FCFA' : null,
          ),
          keyboardType: clavier,
          textCapitalization: c.type == TypeChamp.nom
              ? TextCapitalization.words
              : TextCapitalization.none,
          autocorrect: c.type != TypeChamp.email && c.type != TypeChamp.nom,
          obscureText: c.type == TypeChamp.motDePasse,
          maxLines: c.type == TypeChamp.multiligne ? 5 : 1,
          minLines: c.type == TypeChamp.multiligne ? 3 : 1,
          maxLength: c.maxLongueur,
          inputFormatters: [
            if (c.type == TypeChamp.montant) _SeparateurMilliers(),
            if (c.type == TypeChamp.entier)
              FilteringTextInputFormatter.allow(
                RegExp((c.min ?? 0) < 0 ? r'-?\d*' : r'\d'),
              ),
            if (c.type == TypeChamp.decimal)
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            if (c.type == TypeChamp.telephone)
              FilteringTextInputFormatter.allow(RegExp(r'[\d\s+().-]')),
          ],
          validator: (s) => _valider1(c, s),
          onChanged: (s) {
            _valeurs[c.nom] = s;
            if (_conditionnel ||
                widget.champs.any((x) => x.obligatoireSi != null)) {
              setState(() {});
            }
          },
        );
    }
  }

  /// Champs visibles, découpés en cartes à chaque champ qui ouvre un `groupe`.
  List<List<Champ>> _groupes() {
    final groupes = <List<Champ>>[];
    for (final c in widget.champs.where(_visible)) {
      if (groupes.isEmpty || c.groupe != null) groupes.add([]);
      groupes.last.add(c);
    }
    return groupes;
  }

  /// Lignes d'une carte : deux champs `moitie` voisins partagent la même.
  List<Widget> _lignes(List<Champ> champs) {
    final lignes = <Widget>[];
    for (var i = 0; i < champs.length; i++) {
      final c = champs[i];
      if (c.moitie && i + 1 < champs.length && champs[i + 1].moitie) {
        lignes.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _champ(c)),
              const SizedBox(width: AppTheme.espaceMd),
              Expanded(child: _champ(champs[++i])),
            ],
          ),
        );
      } else {
        lignes.add(_champ(c));
      }
    }
    return lignes;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const FondMarque(),
        title: Text(widget.titre),
      ),
      // Bouton d'envoi fixé en bas : toujours visible, même sur un long formulaire,
      // et posé au-dessus du clavier quand il est ouvert.
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(top: BorderSide(color: context.palette.bordure)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.espaceLg,
                AppTheme.espaceMd,
                AppTheme.espaceLg,
                AppTheme.espaceMd,
              ),
              child: FilledButton(
                onPressed: _envoi ? null : _valider,
                child: _envoi
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(widget.libelleEnvoi),
              ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _form,
        autovalidateMode: _soumis
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.espaceLg),
          children: [
            if (widget.intro != null) ...[
              widget.intro!,
              const SizedBox(height: AppTheme.espaceLg),
            ],
            // Champs regroupés en cartes.
            for (final (i, groupe) in _groupes().indexed) ...[
              if (i > 0) const SizedBox(height: AppTheme.espaceLg),
              Section(
                titre: groupe.first.groupe,
                children: [
                  for (final (j, ligne) in _lignes(groupe).indexed) ...[
                    if (j > 0) const SizedBox(height: AppTheme.espaceMd),
                    ligne,
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Saisie des montants avec séparateur de milliers (« 350 000 »).
class _SeparateurMilliers extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue ancien,
    TextEditingValue nouveau,
  ) {
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
