#!/usr/bin/env bash
# Le projet est dans ~/Documents, synchronisé par iCloud : macOS y ajoute des
# attributs (FinderInfo) aux dossiers .framework et la signature de
# Flutter.framework échoue (« resource fork, Finder information, or similar
# detritus not allowed », Xcode « Exited with status code 255 »).
# Le dossier build/ est donc un lien vers un dossier hors iCloud.
#   bash tool/preparer-build.sh   (après un `flutter clean`, qui supprime le lien)
set -euo pipefail
cd "$(dirname "$0")/.."
cible="$HOME/Library/Caches/gestion_immo_mobile-build"
mkdir -p "$cible"
if [ -e build ] && [ ! -L build ]; then
  echo "Un dossier build/ réel existe : supprimez-le (rm -rf build) puis relancez ce script."
  exit 1
fi
ln -sfn "$cible" build
echo "build -> $cible"
