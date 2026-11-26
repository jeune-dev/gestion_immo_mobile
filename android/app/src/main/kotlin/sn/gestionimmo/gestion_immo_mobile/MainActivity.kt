package sn.gestionimmo.gestion_immo_mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        creerCanalPush()
    }

    /**
     * Crée le canal de notification nommé par le manifeste
     * (`default_notification_channel_id`).
     *
     * Déclarer l'identifiant dans le manifeste ne suffit pas : si le canal
     * n'existe pas quand la notification arrive, FCM la pose dans son canal de
     * repli, intitulé « Divers ». L'utilisateur voit alors une catégorie sans
     * nom dans les réglages d'Android, et ne peut pas régler ces alertes à
     * part du reste.
     *
     * Créer un canal déjà présent est sans effet : Android ignore l'appel, sauf
     * pour le nom et la description, qu'il met à jour. Aucun risque à le faire
     * à chaque démarrage, et c'est ce qui permet de corriger un libellé.
     *
     * Avant Android 8 (API 26) les canaux n'existent pas et les notifications
     * s'affichent sans eux.
     */
    private fun creerCanalPush() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val canal = NotificationChannel(
            getString(R.string.canal_push),
            getString(R.string.canal_push_nom),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = getString(R.string.canal_push_description)
        }
        getSystemService(NotificationManager::class.java)
            ?.createNotificationChannel(canal)
    }
}
