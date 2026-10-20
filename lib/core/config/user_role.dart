/// Rôles des comptes qui utilisent l'application mobile (le super admin passe par le web).
enum UserRole {
  proprietaire('proprietaire'),
  locataire('locataire'),
  inconnu('');

  const UserRole(this.code);
  final String code;

  static UserRole depuis(String? code) =>
      UserRole.values.firstWhere((r) => r.code == code && r != UserRole.inconnu,
          orElse: () => UserRole.inconnu);
}
