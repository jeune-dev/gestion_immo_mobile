#!/bin/sh
# Phase de build Xcode « Contrôles de publication » (configuration Release
# seulement, juste avant la signature) :
#  1. refuse une version publiée sans --dart-define=API_URL=https://… ;
#  2. retire de l'Info.plist les autorisations réservées au développement
#     (HTTP en réseau local, demande d'accès au réseau local).
set -eu
[ "${CONFIGURATION:-}" = "Release" ] || exit 0

# Flutter transmet les --dart-define encodés en base64, séparés par des virgules.
url_api=""
for define in $(echo "${DART_DEFINES:-}" | tr ',' ' '); do
  valeur=$(echo "$define" | base64 --decode 2>/dev/null || true)
  case "$valeur" in API_URL=*) url_api="${valeur#API_URL=}" ;; esac
done
case "$url_api" in
  https://*) ;;
  *)
    echo "error: Version de publication : --dart-define=API_URL=https://… est obligatoire." >&2
    exit 1
    ;;
esac

plist="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
/usr/libexec/PlistBuddy -c "Delete :NSAppTransportSecurity" "$plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Delete :NSLocalNetworkUsageDescription" "$plist" 2>/dev/null || true
