import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Fichiers qui n'existent que le temps d'une lecture ou d'un partage : le lecteur
/// vidéo et le partage du système ne savent travailler que sur un fichier.
/// Aucun n'est conservé : chacun est supprimé après usage, et les restes
/// (application fermée entre-temps) le sont au lancement suivant.
const _dossierTemporaire = 'kerimmo';

Future<Directory> _racine() async =>
    Directory('${(await getTemporaryDirectory()).path}/$_dossierTemporaire');

/// Écrit [octets] dans un fichier temporaire qui porte le nom [nom].
Future<File> ecrireFichierTemporaire(String nom, List<int> octets) async {
  final dossier = Directory('${(await _racine()).path}/${const Uuid().v4()}');
  await dossier.create(recursive: true);
  return File('${dossier.path}/$nom').writeAsBytes(octets, flush: true);
}

Future<void> supprimerFichierTemporaire(File fichier) async {
  try {
    await fichier.parent.delete(recursive: true);
  } on FileSystemException {
    // Déjà supprimé, ou supprimé au prochain lancement.
  }
}

Future<void> viderFichiersTemporaires() async {
  final racine = await _racine();
  if (await racine.exists()) await racine.delete(recursive: true);
}
