import 'package:intl/intl.dart';

/// Formats d'affichage (charte § 2) : FCFA sans décimale, espace insécable entre
/// les milliers (« 4 250 000 FCFA ») ; dates à l'heure de Dakar (UTC+0).
const _insecable = ' ';

String nombre(num? v) {
  if (v == null) return '—';
  final n = v.round();
  final s = n
      .abs()
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => _insecable);
  return n < 0 ? '-$s' : s;
}

String montant(num? v) => v == null ? '—' : '${nombre(v)}${_insecable}FCFA';

/// Entier depuis une valeur JSON (les montants sont des entiers, parfois en chaîne).
int entier(dynamic v) => v is num ? v.round() : int.tryParse('$v') ?? 0;

DateTime? _lire(String? v) {
  if (v == null || v.isEmpty) return null;
  return DateTime.tryParse(v)?.toUtc();
}

/// « AAAA-MM-JJ » → « 05/09/2026 » ; date-heure ISO → date à Dakar (UTC).
String date(String? v) {
  final d = _lire(v);
  return d == null ? '—' : DateFormat('dd/MM/yyyy').format(d);
}

String dateLongue(String? v) {
  final d = _lire(v);
  return d == null ? '—' : DateFormat('d MMMM yyyy', 'fr').format(d);
}

String dateHeure(String? v) {
  final d = _lire(v);
  return d == null ? '—' : DateFormat("dd/MM/yyyy 'à' HH:mm").format(d);
}

/// « 2026-09 » → « sept. 2026 ».
String mois(String v) {
  final d = DateTime.tryParse('$v-01');
  return d == null ? v : DateFormat('MMM yyyy', 'fr').format(d);
}

String moisCourt(String v) {
  final d = DateTime.tryParse('$v-01');
  return d == null ? v : DateFormat('MMM', 'fr').format(d);
}

String ilYa(String? v) {
  final d = _lire(v);
  if (d == null) return '—';
  final s = DateTime.now().toUtc().difference(d).inSeconds;
  if (s < 60) return "à l'instant";
  if (s < 3600) return 'il y a ${s ~/ 60} min';
  if (s < 86400) return 'il y a ${s ~/ 3600} h';
  if (s < 30 * 86400) return 'il y a ${s ~/ 86400} j';
  return date(v);
}

/// Date du jour « AAAA-MM-JJ » (Dakar = UTC).
String aujourdhui() => DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc());

String versApi(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

String pourcent(num? v) =>
    v == null ? '—' : '${NumberFormat('#,##0.#', 'fr').format(v)}$_insecable%';

String nomComplet(Map? p) {
  if (p == null) return '—';
  final s = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
  return s.isEmpty ? '—' : s;
}

String initiales(Map? p) {
  final a = (p?['first_name'] as String?) ?? '';
  final b = (p?['last_name'] as String?) ?? '';
  final s =
      '${a.isNotEmpty ? a[0] : ''}${b.isNotEmpty ? b[0] : ''}'.toUpperCase();
  return s.isEmpty ? '?' : s;
}

/// Saisie d'un montant (« 350 000 ») → entier, ou null.
int? lireMontant(String s) {
  final c = s.replaceAll(RegExp(r'[^0-9]'), '');
  return c.isEmpty ? null : int.tryParse(c);
}

/// Nombre depuis une valeur JSON (les décimaux arrivent parfois en chaîne).
num? nombreOuNull(dynamic v) => v is num ? v : num.tryParse('${v ?? ''}');

/// Liste d'objets JSON (vide si absente).
List<Map<String, dynamic>> listeJson(dynamic v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];
