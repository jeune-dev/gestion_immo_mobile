# Règles R8 — TerangaLoc
#
# L'essentiel du code métier est en Dart, compilé en natif ARM : R8 ne le voit
# pas et ne le touche pas. Ces règles ne concernent que la couche Android et
# les plugins natifs, où la réduction casse ce qui est atteint par réflexion —
# c'est-à-dire ce qu'aucune analyse statique ne peut suivre.

# Moteur Flutter et embedding : jamais supprimés, jamais renommés.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Google Play Core (livraison différée) : R8 référence ces classes même quand
# l'application n'en fait pas usage. On tait l'avertissement plutôt que
# d'ajouter une dépendance dont personne n'a besoin.
-dontwarn com.google.android.play.core.**

# Firebase Cloud Messaging : le service de réception est instancié par le
# système, pas appelé depuis le code.
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# flutter_secure_storage s'appuie sur androidx.security.crypto.
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**

# Coroutines Kotlin, employées par plusieurs plugins.
-dontwarn kotlinx.coroutines.**

# Signatures génériques et annotations : la sérialisation JSON des plugins
# natifs les relit à l'exécution.
-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*

# Numéros de ligne conservés, pour que les piles d'appels remontées à
# Crashlytics soient lisibles. Sans `LineNumberTable`, R8 les retire : la table
# de correspondance téléversée par le greffon Gradle rend alors les NOMS de
# classes et de méthodes, mais plus l'endroit exact — et c'est l'endroit exact
# qu'on vient chercher. `-renamesourcefileattribute` remplace le nom du fichier
# source par une chaîne fixe : la correspondance suffit à le retrouver, et rien
# de l'arborescence du projet ne part dans l'APK.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
