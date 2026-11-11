import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:gestion_immo_mobile/core/errors/failure.dart';
import 'package:gestion_immo_mobile/core/services/cache_images.dart';
import 'package:gestion_immo_mobile/core/services/token_service.dart';
import 'package:gestion_immo_mobile/features/documents/domain/repositories/documents_repository.dart';
import 'package:gestion_immo_mobile/features/documents/domain/usecases/telecharger_document.dart';
import 'package:gestion_immo_mobile/features/documents/presentation/widgets/image_api.dart';

/// Décodage des images de l'API à la taille réellement affichée.
///
/// `Image.memory` décode par défaut à la taille du FICHIER : une miniature de
/// 480 px occupe 480 × 480 × 4 ≈ 0,9 Mo en mémoire, qu'elle remplisse l'écran
/// ou une vignette de 48 px. `cacheWidth` demande au décodeur de s'arrêter à la
/// largeur utile — c'est le seul réglage qui agisse avant l'allocation.
///
/// Ce que ces tests figent : la largeur vient de la boîte RÉELLE, et la taille
/// `originale` en est exemptée pour que le zoom reste net.

/// Un PNG 1×1 valide : il suffit, aucun test ici ne regarde les pixels.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _DepotFactice implements DocumentsRepository {
  @override
  Future<Either<Failure, Uint8List>> telecharger(
    String id, {
    String? taille,
  }) async => Right(_png);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Récupère la largeur de décodage demandée : `Image.memory` avec `cacheWidth`
/// enveloppe son fournisseur dans un `ResizeImage`.
int? largeurDemandee(WidgetTester tester) {
  final image = tester.widget<Image>(find.byType(Image));
  final fournisseur = image.image;
  return fournisseur is ResizeImage ? fournisseur.width : null;
}

Future<void> afficher(
  WidgetTester tester, {
  required double largeurBoite,
  required double densite,
  String taille = 'miniature',
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(devicePixelRatio: densite),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: largeurBoite,
            height: largeurBoite,
            child: ImageApi('doc-1', taille: taille),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final sl = GetIt.instance;

  setUp(() {
    sl.registerSingleton(TokenService());
    sl.registerSingleton(CacheImages(sl<TokenService>()));
    sl.registerSingleton(TelechargerDocument(_DepotFactice()));
  });
  tearDown(sl.reset);

  testWidgets('une vignette décode à la largeur de sa boîte, pas du fichier', (
    tester,
  ) async {
    await afficher(tester, largeurBoite: 48, densite: 3);

    // 48 points × 3 pixels par point = 144 pixels physiques. Une miniature de
    // 480 px décodée ainsi occupe 144 × 144 × 4 ≈ 83 Ko au lieu de 0,9 Mo.
    expect(largeurDemandee(tester), 144);
  });

  testWidgets('une grande boîte décode plus large', (tester) async {
    await afficher(tester, largeurBoite: 300, densite: 2);
    expect(largeurDemandee(tester), 600);
  });

  testWidgets('la densité de l’écran est prise en compte', (tester) async {
    await afficher(tester, largeurBoite: 100, densite: 1);
    expect(largeurDemandee(tester), 100);
  });

  testWidgets('la taille « originale » décode tout : le zoom doit rester net', (
    tester,
  ) async {
    await afficher(
      tester,
      largeurBoite: 48,
      densite: 3,
      taille: 'originale',
    );

    // Aucune réduction : l'image plein écran vit dans un InteractiveViewer, et
    // une image décodée à la taille de l'écran deviendrait floue au zoom.
    expect(largeurDemandee(tester), isNull);
  });

  testWidgets('l’image est bien affichée, pas seulement dimensionnée', (
    tester,
  ) async {
    await afficher(tester, largeurBoite: 120, densite: 2);

    // Le garde-fou qui compte : réduire le décodage ne doit pas empêcher le
    // rendu. S'il n'y a plus d'Image, l'optimisation a mangé l'affichage.
    expect(find.byType(Image), findsOneWidget);
    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.cover);
  });
}
