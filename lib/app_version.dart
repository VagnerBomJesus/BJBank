/// Single source of truth para a versão visível ao utilizador na UI.
///
/// Mantém-se em sincronia com `pubspec.yaml` `version:` field.
/// Quando bumpas pubspec, bumpa também aqui — não há leitura automática
/// para evitar dependência runtime de `package_info_plus`.
///
/// Convenção SemVer: MAJOR.MINOR.PATCH+BUILD.
///   - MAJOR — quebra protocolo PQC ou wire (rejeitar sessões antigas).
///   - MINOR — features novas sem quebra (ex.: benchmark fair-runtime).
///   - PATCH — bug fix / hardening sem novas features.
///   - BUILD — versionCode Android (Play Console exige monotónico).
class AppVersion {
  /// Versão semântica visível (ex.: "1.4.0").
  static const String semver = '1.4.0';

  /// Build number (versionCode Android / CFBundleVersion iOS).
  static const int build = 5;

  /// Versão completa para mostrar na UI: "1.4.0 (build 5)".
  static String get displayString => '$semver (build $build)';

  /// Codename interno do release. Útil em logs / debug overlay.
  static const String codename = 'fair-runtime';

  /// Data de release ISO 8601 (UTC). Usada no canto inferior do About
  /// para o utilizador perceber se a app está stale.
  static const String releaseDate = '2026-06-12';

  /// Versões dos componentes criptográficos críticos. Aparecem no About
  /// e no payload de telemetria (quando consentido) para correlacionar
  /// benchmarks da tese com versões exactas.
  static const String bouncyCastleVersion = '1.80';
  static const String nobleVersion = '0.4';
  static const String pointyCastleVersion = '3.9.1';

  /// Algoritmos PQC ativos. Atualizar se mudar parameter set.
  static const String pqcSignature = 'ML-DSA-65 (FIPS 204)';
  static const String pqcKem = 'ML-KEM-768 (FIPS 203)';
  static const String pqcBackupSignature = 'SLH-DSA-SHAKE-128f (FIPS 205)';
  static const String hybridKex = 'X25519 + ML-KEM-768';
}
