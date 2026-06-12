# BJBank — Future Work

**Document:** Explicit post-thesis roadmap.
**Last update:** 2026-06-12 (v1.4.0).
**Audience:** Chapter §8 of the dissertation + future project contributors.

---

## 1. iOS — Swift plugin analogous to Android

**Current state:** iOS runs in server-managed mode (PQC key lives on the server for iOS devices, identical to the v1.0 prototype). `DevicePqcService.isAvailable()` returns `false` and `SupabaseTransferService` falls back automatically.

**Estimated effort:** 5-10 days.

### What is missing

| Item | How |
|---|---|
| `PqcPlugin.swift` plugin analogous to Kotlin | `FlutterPlugin` + `MethodChannel` `com.bjbank.ipg/pqc` |
| ML-DSA-65 + ML-KEM-768 native iOS | **Option A** liboqs as `xcframework` via CocoaPods. **Option B** swift-crypto extension (no built-in PQC yet in 2026). **Option C** pqcrystals-dilithium C reference compiled as binary library |
| Private key in Secure Enclave | `kSecAttrTokenIDSecureEnclave` + `SecKeyCreateRandomKey` for wrapping key; ML-DSA priv encrypted with wrapping key |
| Equivalent to `EncryptedSharedPreferences` | Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` + `kSecAttrSynchronizable=false` |
| Block iCloud Keychain sync of PQC private | the attribute above solves it |
| Android ↔ iOS behavioural parity tests | Fixture suite (same keys, same wire) |

### Risks
- liboqs iOS build pipeline is fragile — depends on Xcode version, target arch, etc.
- Secure Enclave has key size limits; ML-DSA-65 priv = 4032B may not fit directly. Solution: wrap with SE-resident key.
- Apple App Store review may question non-Apple cryptography — declare via `ITSAppUsesNonExemptEncryption=NO` and add classification note.

---

## 2. Experimental validation on real hardware

**Current state:** all benchmarks measured on emulator `sdk_gphone64_x86_64` (Android API 36, x86_64). Results published in the dissertation refer to this environment.

**Effort:** 1 day (if devices on hand), 1 week if you need to acquire them.

### Recommended devices (mobile spectrum coverage)

| Device | SoC | Why |
|---|---|---|
| Pixel 7/8 | Tensor G2/G3 (ARM Cortex-A78/A715) | Pure Android reference |
| Samsung Galaxy A54 mid-range | Exynos 1380 | Dominant mass-market in PT |
| Any low-end Android 12+ device | Snapdragon 4 series | Worst-case latency |
| iPhone 13+ (after Swift plugin) | A15+ | Apple Silicon comparison |

### Metrics to collect

- P50/P95/P99 in ns for each PQC + classical native BC + classical Dart operation.
- Energy delta (mWh) via `BatteryManager` API between test and idle baseline — optional but strong for the thesis.
- Heap usage during batch — verify GC pressure during ML-DSA verify (heavy big-int ops).
- Thermal throttling — run 5×500 sequential iterations and check whether P50 climbs (CPU clock drops).

### Cross-device comparison

Essential chart for §6: 4 devices × 3 pipelines × 6 operations = coloured matrix. Shows that **PQC overhead is consistent across hardware**, not an emulator outlier.

---

## 3. Side-channel hardening

**Current state:** the code uses BC 1.80, which has constant-time mitigations in some ML-KEM/ML-DSA operations (cite BC changelog), but there is no empirical validation in this project.

**Future work:**
- Timing analysis via Mona Lisa / dudect in a dedicated lab.
- Verify that `MLDSAPrivateKeyParameters` does not allocate dependently on the key.
- Replace byte-by-byte signature comparison with `MessageDigest.isEqual` (constant-time) where applicable.
- Mandatory citations: **Banegas et al., "Concrete quantum-resistance" SoK CHES 2024** + **Howe et al., "TimeCryptAnalyse"**.

---

## 4. Protocol-level enhancements

### 4.1 Multi-session forward secrecy (KEM rotation)

Currently each KEM handshake generates a new ephemeral key, but the user's **ML-DSA key** is long-term. Compromise → manual revocation. Future work:

- **Key transparency** CONIKS-style — verifiable pubkey publication with signed Merkle tree.
- **Automatic client-side key rotation** — generate a new ML-DSA every N transfers or T time, without history loss.
- Compatibility with the current `revokeKey`.

### 4.2 Triple hybrid PFS

Currently the handshake uses only ML-KEM-768. To resist catastrophic failures in lattice cryptography, add an extra layer:

- **X25519 + ML-KEM-768 + Classic-McEliece-460896** — McEliece is code-based, with lattice-independent assumption.
- HKDF combiner expanded to 3 secrets.
- Cost: ~250KB McEliece pubkey — prohibitive for mobile in most cases, but viable for initial handshake (not per-session).

### 4.3 Verifiable Random Function (VRF) for serial

The serial is currently deterministic monotonic. For resistance against an attacker observing the stream:

- Implement ML-DSA-based VRF signing `(sessionId, counter)`.
- Serial becomes unpredictable but still avoids replay.
- Cost: +1 ML-DSA sign per transfer (~5ms).

---

## 5. Operations and observability

| Item | Why it matters |
|---|---|
| **Opt-in benchmark telemetry** | Collect real PQC production statistics across user base — material for a follow-up paper |
| **Grafana dashboard with Edge Function metrics** | p95/p99 latency per operation, `kemCipherInvalid` error rate, key rotations |
| **Sentry alerts for `_kemCompletePending` timeout** | Detect handshake breakage |
| **Structured JSON logging** | Replace `debugPrint` with `logger` package with levels |
| **End-to-end APM tracing** | OpenTelemetry trace request → Edge → Postgres |

---

## 6. Non-PQC pending banking features

These are product features, not thesis ones, but they belong to the roadmap if the project continues:

| Feature | State | Effort |
|---|---|---|
| QR Code transfer (parse + sign) | "Coming soon" placeholder | 1-2 days |
| FCM push notifications | Schema OK, backend trigger missing | 2-3 days |
| Real virtual cards CRUD | Mock, schema + RPCs + UI missing | 5-7 days |
| Open Banking PSD2 | Does not exist | 3-4 weeks (regulatory) |
| Branded splash screen | Flutter default | 30 min `flutter_native_splash` |
| Offline handling + exponential-backoff retry | Non-existent | 1-2 days |
| First-time-user onboarding tour | Does not exist | 1 day |

---

## 7. Compliance and regulation (real banking)

If the app becomes a product:

- **PSD2 SCA** — Strong Customer Authentication two-factor (already have email OTP, missing biometric attestation + dynamic linking)
- **GDPR DPIA** — formal Data Protection Impact Assessment
- **eIDAS** — qualified signatures if signing contracts
- **DORA** — Digital Operational Resilience Act (2025+ mandatory for EU banking)
- **Cyber Resilience Act** — for software products with crypto components
- **NIS2** — network security for critical entities
- **Certified penetration testing** by external entity
- **Bug bounty programme**

---

## 8. Specific academic research follow-ups

### 8.1 Follow-up paper — "PQC verify is faster than ECDSA in mobile hot paths"

Unexpected, counter-intuitive observation in v1.4.0 benchmarks: in BC 1.80 native on an x86_64 emulator, **ML-DSA-65 verify is 3× faster than ECDSA-P256 verify** (1.36ms vs 3.97ms P50). Hypothesis: NTT vectorises better than big-int in JIT JVM. Future work:

- Validate on real ARM64 (may invert if ARMv8 PMULL accelerates big-int).
- Profile with `perf` to confirm hot loop (cache miss, branch mispredict).
- Submit as IACR ePrint short paper.

### 8.2 Mobile PQC user acceptance study

Survey:
- Do users perceive PQC when explained? (UX challenge)
- Do they accept ~5-10ms extra latency on transfers?
- Trust transfer: "if the bank says post-quantum, is it more secure?"
- Comparison with TLS "green padlock" — quantum lock equivalent?

### 8.3 Protocol-aware migration

If PQC has to change parameter set (e.g. attack on ML-DSA-65 → migrate to ML-DSA-87):

- Version wire protocol with downgrade-resistant negotiation
- Rollover strategy (v2 + v3 coexistence window)
- Backward compatibility window

---

## 9. Honest limitations the thesis must acknowledge

To maintain academic rigour — explicitly declare:

1. **Single platform experimentally validated:** Android emulator x86_64. Real ARM and iOS are assumed extensions, not measured.
2. **No side-channel testing:** assumes BC 1.80 is constant-time where needed; not independently validated.
3. **No production-scale load testing:** single-device measurements, no concurrency.
4. **No formal security audit:** wire protocol v2 was not reviewed by an independent entity.
5. **Classical vs PQC comparison limited to ECDSA-P256/ECDH-P256:** does not cover RSA-2048/3072 nor Ed25519 (the latter used by X25519 but not as ECDSA equivalent).
6. **PFS is per-session, not per-message:** an attacker with a captured session can decrypt all messages within it. Partial mitigation via 5 min session TTL.
7. **Assumed quantum threat model:** follows NIST estimates; a practical quantum computer does not yet exist. The analysis is pre-quantum mitigation, not post-attack response.

---

## 10. Roadmap executive summary

| Horizon | Items |
|---|---|
| **Pre-defence (this week)** | B1+B2 (real ARM + PFS validation) + final charts |
| **3 months post-defence** | iOS Swift plugin + side-channel hardening + follow-up paper |
| **6-12 months** | KEM rotation + triple hybrid (McEliece) + opt-in telemetry |
| **Product roadmap** | QR + push + cards + Open Banking + compliance |
| **Continuous research** | Acceptance study + protocol migration awareness |
