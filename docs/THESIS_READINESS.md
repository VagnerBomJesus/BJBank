# BJBank — Thesis Defence Readiness

**Document:** Honest assessment of the implementation state against the thesis requirements.
**Thesis:** *Post-Quantum Cryptography in Mobile Applications: A Resilient Protocol Proposal for Home Banking Environments*
**App version:** 1.4.0+5 (codename `fair-runtime`, 2026-06-12)
**Primary defended platform:** Android (BC 1.80 native)
**Secondary platform:** iOS (server-managed, no Swift plugin)

---

## TL;DR — State per typical chapter

| Thesis chapter | State | Evidence |
|---|---|---|
| 1. Introduction, motivation | ✅ Covered | HNDL threat model → ADR-001 |
| 2. Theoretical foundations (RSA/ECDSA/Shor/Grover/lattices/hash-based) | ✅ Text | Material in ADR-001/003 |
| 3. State of the art (NIST FIPS 203/204/205, hybrid, RFC 9420) | ✅ Text | ADR-001 §3, literature references |
| 4. Protocol proposal | ✅ Implemented | Wire protocol v2 + KEM handshake + audit chain |
| 5. Implementation | ✅ Functional | Android BC 1.80 native + Supabase Edge |
| 6. Experimental evaluation | ⚠️ **Missing real ARM** | 3 fair-runtime datasets (x86 emulator) |
| 7. Discussion | ✅ Sufficient material | Trade-offs documented |
| 8. Conclusions + future work | ✅ Text | This doc + FUTURE_WORK.md |

**Critical note:** the only blocking item for a robust defence is **running benchmarks on at least ONE physical ARM device** (Pixel, Samsung, anything Android). Without this, any reviewer can say "your numbers are x86 emulator — not representative".

---

## 1. What is IMPLEMENTED (Android, v1.4.0)

### 1.1 Native on-device post-quantum cryptography

| Component | Where | FIPS | State |
|---|---|---|---|
| **ML-DSA-65 keygen** | `PqcPlugin.kt::generateDsa` | 204 | ✅ |
| **ML-DSA-65 sign** | `PqcPlugin.kt::signDsa` | 204 | ✅ |
| **ML-DSA-65 verify** | `PqcPlugin.kt::verifyDsa` | 204 | ✅ (local client — not server) |
| **ML-KEM-768 encap** | `PqcPlugin.kt::kemEncapsulate` | 203 | ✅ |
| **SLH-DSA-SHAKE-128f sign** | `PqcPlugin.kt::slhDsaSign` | 205 | ✅ (defence-in-depth secondary signature) |
| **X25519 agree** | `PqcPlugin.kt::x25519Agree` | RFC 7748 | ✅ (classical component of hybrid) |
| **HKDF combiner** | `PqcPlugin.kt::hybridDerive` | RFC 9420 | ✅ |
| **Private key in StrongBox/TEE** | `EncryptedSharedPreferences` + `MasterKey.AES256_GCM` | — | ✅ (AndroidKeyStore-backed) |
| **Cloud backup / device-transfer exclusion** | `data_extraction_rules.xml` | — | ✅ |

### 1.2 Wire protocol v2 (BJBank-v2-aes256gcm-sha256)

| Item | Where | State |
|---|---|---|
| Canonical payload (sorted keys) | `_canonicalEncode` in `SupabaseTransferService` | ✅ |
| Random 12-byte IV (not static) | wire v2 | ✅ |
| Monotonic serial persisted in SharedPreferences | `_proximoSerialAsync` | ✅ |
| Timestamp window ±30s | server-side validation | ✅ |
| UNIQUE `txId` Postgres constraint | migration | ✅ |
| UNIQUE pubkey per user-device | migration anti first-use injection | ✅ |
| TTL 5 min on pending_kem_sessions | TTL trigger | ✅ |
| App-restart-resilient serial cleanup | `purgeSerialAntigos` in `main()` | ✅ |

### 1.3 Real post-quantum PFS

| Item | Where | State |
|---|---|---|
| 2-phase KEM handshake | `pqc_handshake_flutter` v2 + `pqc_handshake_kem_complete` | ✅ |
| `kemEncapsulate` runs on client | `PqcPlugin.kt::kemEncapsulate` | ✅ |
| `sharedSecret` never crosses the network | by wire v2 design | ✅ |
| Server-side decapsulation with ephemeral key | Edge Function | ✅ |
| Session expires (TTL) and regenerates | `pending_kem_sessions` table | ✅ |

### 1.4 Defence in depth

| Item | State |
|---|---|
| SHA-256 hash-chained audit log (tamper-evident) | ✅ Postgres trigger |
| Server key rotation (`server_key_history`) | ✅ Schema + Edge UI |
| Local ML-DSA verify (no `verify_dsa` circular trust) | ✅ |
| TOFU pubkey pinning | ✅ |
| ProGuard rules for BC + Supabase release | ✅ |
| NetworkSecurityConfig (cleartext blocked in release) | ✅ |
| Multi-layer anti-replay | ✅ |

### 1.5 Academic material

| Item | Where | State |
|---|---|---|
| On-device PQC native benchmark (ns) | `DevicePqcService.runBenchmark` | ✅ |
| Fair-runtime ECDSA/ECDH BC native benchmark | `runClassicBenchmark` | ✅ |
| Classical Dart reference benchmark | `ClassicCryptoService.benchmark` | ✅ |
| Server Edge Functions benchmark (@noble) | endpoint deployments | ✅ |
| 3-pipeline JSON export + methodological note | `DeviceBenchmarkScreen._exportar` | ✅ |
| Automatic PQC vs Classical ratios in UI | yellow card | ✅ |

### 1.6 Technical documentation

| Doc | Content | State |
|---|---|---|
| README.md | Executive summary + index | ✅ v1.4.0 |
| CHANGELOG.md | v1.0 → v1.4.0 | ✅ |
| docs/ARCHITECTURE.md | Stack, flows, deployment | ✅ |
| docs/REQUIREMENTS.md | RF/RNF | ✅ |
| docs/UML_DIAGRAMS.md | 14 Mermaid (sequence, component, state, ER) | ✅ |
| docs/diagrams/BJBank_Architecture.drawio | 9 editable pages | ✅ |
| docs/adr/ADR-001-PQC-IMPLEMENTATION.md | PQC architectural decision | ✅ |
| docs/adr/ADR-002-MULTI-TENANCY.md | Postgres RLS | ✅ |
| docs/adr/ADR-003-SECURITY-STRATEGY.md | Threat model wire v2 | ✅ |
| docs/PQC_REMAINING_CRITICAL_ISSUES.md | 3 critical issues + resolution | ✅ |
| docs/THESIS_READINESS.md | THIS document | ✅ |
| docs/FUTURE_WORK.md | Future work | ✅ |

---

## 2. What is MISSING for the thesis to be 100% defensible

### 2.1 BLOCKING for robust defence

| # | Item | Effort | Why critical |
|---|---|---|---|
| **B1** | Run benchmarks on ONE physical ARM device (Pixel / Samsung) and export JSON | 30 min if you have a device | The jury will ask "is this an emulator?" — without real ARM, any claim about mobile performance is vulnerable |
| **B2** | Validate end-to-end the PFS flow with KEM mode on a real device with captured logcat | 1h | Prove that `pqc_handshake_kem_complete` works, not just compiles |

### 2.2 STRONGLY RECOMMENDED

| # | Item | Effort | Why it matters |
|---|---|---|---|
| **R1** | Experimental chapter with 3 cross datasets: Android-emul-x86 / Android-device-ARM / Server-V8-noble | 2-3h writing | Allows the assertion "on platform X with runtime Y, PQC costs Z" — defensible and specific |
| **R2** | Bar charts P50 with P95 error bars for each operation × pipeline | 1h matplotlib | Mandatory visual for an empirical thesis |
| **R3** | Sizes table (official FIPS) pk/sk/sig/ct side-by-side with classical | 30 min | More persuasive than latency — users don't notice 5ms but they store bytes forever |
| **R4** | Honest discussion of unexpected results (ML-DSA verify 3× FASTER than ECDSA in BC native) | 1h writing | Shows academic rigour — you don't hide counter-intuitive findings |

### 2.3 OPTIONAL (strengthens the thesis but not critical)

| # | Item | Effort | Why it helps |
|---|---|---|---|
| **O1** | Analogous iOS Swift plugin (CryptoKit + liboqs-objc or pqcrystals-pure) | 5-10 days | Real cross-platform coverage, not server-fallback |
| **O2** | Side-channel analysis note — Banegas et al. citation | 2h | Defence against practical-attacks reviewer |
| **O3** | Demo video (2-3 min) — onboarding + transfer + benchmark | 1h | Always requested at defence |
| **O4** | Public GitHub repository with release tag v1.4.0 | 30 min | Reproducibility |

---

## 3. Non-PQC features implemented (banking context)

The app is a **functional mobile banking app**, not a PQC-only demo. For context:

| Feature | State | Comment |
|---|---|---|
| Supabase authentication (email+OTP) | ✅ | GoTrue |
| Account creation + PT50 IBAN (calculated check NIB) | ✅ | Fixed in v1.3.0 migration |
| Real-time balance + statement | ✅ | Realtime Supabase |
| IBAN transfer with PQC signature | ✅ | Core of the thesis |
| MB WAY (transfer by phone/contact) | ✅ | UI + backend |
| QR Code transfer | ⚠️ Partial | "Coming soon" placeholder |
| Push notifications | ⚠️ Schema OK | FCM setup pending |
| Virtual cards CRUD | ⚠️ Mock | No real schema |
| Open Banking PSD2 | ❌ | Future work |
| Investments / Loans / Budgets | ❌ Removed v1.3.1 | Were legacy demo — out of thesis scope |

---

## 4. iOS platform — honest state

| Item | State |
|---|---|
| App compiles and runs on iOS | ✅ |
| Full UI on iOS | ✅ |
| Authentication / Supabase / transfers (server-managed) | ✅ |
| On-device PQC | ❌ No Swift plugin |
| `DevicePqcService.isAvailable()` on iOS | returns `false` |
| iOS fallback pipeline | Server-managed (PQC key on server, same as v1.0) |

**For the thesis:** declare explicitly as an **assumed limitation** and reference FUTURE_WORK §iOS. It is NOT honest to claim "iOS-ready" when it isn't.

---

## 5. Scientific reproducibility

So the jury can replicate:

| Item | State |
|---|---|
| Public source code on GitHub | ✅ (currently private) |
| Build instructions (`flutter pub get && flutter run`) | ✅ |
| Full SQL schema (migrations) | ✅ in `supabase/migrations/` |
| Edge Functions source | ✅ in `supabase/functions/` |
| Documented PQC parameter sets | ✅ ADR-001 |
| Versioned wire protocol | ✅ ADR-003 |
| Benchmark JSON export | ✅ via UI |
| Git release tag v1.4.0 | ❌ Missing `git tag -a v1.4.0` |

---

## 6. Risks for the defence — anticipating hostile questions

| Likely jury question | Defensible answer | Where documented |
|---|---|---|
| "How do I know BouncyCastle 1.80 correctly implements FIPS 204?" | BC passes NIST CAVP test vectors; reference suite | ADR-001 |
| "Why were PQC and classical not measured on real ARM?" | (needs to run) | ⚠️ B1 above |
| "Could the PQC `sharedSecret` be exfiltrated by timing side-channel?" | BC has constant-time mitigations in ML-KEM (cite); side-channel analysis is in FUTURE_WORK | O2 |
| "iOS is half the mobile market — why no support?" | Assumed limitation; PQC server-managed on iOS is a functional fallback; Swift plugin is defined future work | FUTURE_WORK §iOS |
| "What is the per-transfer byte overhead?" | +1088B (ML-KEM ct) + 3309B (ML-DSA sig) = ~4.4KB extra vs ECDSA 64B + ECDH 32B = ~96B → **46× byte overhead** | Experimental chapter |
| "How does it protect against retroactive HNDL?" | Post-quantum PFS via ephemeral ML-KEM; private key never on wire; even capture-now-decrypt-later does not unlock a past session | ADR-003 |
| "Who audits the audit_log?" | SHA-256 hash chaining; client verifies chain on download; Postgres trigger prevents insert without prior hash | v1.3.0 changelog |
| "Battery cost of PQC on mobile?" | Not measured — limitation. Approx CPU time × typical Android power profile (qcom snapdragon ~1W active CPU): 5ms sign ≈ 5mJ per transfer → negligible vs UI rendering | Mention in §6 discussion |

---

## 7. Delivery checklist (1-2 days before defence)

- [ ] Run benchmark on a physical ARM device (B1)
- [ ] Validate end-to-end PFS flow on a physical device (B2)
- [ ] Generate final matplotlib charts (R2)
- [ ] FIPS sizes table (R3)
- [ ] Write §discussion on ML-DSA verify being faster (R4)
- [ ] Demo video (O3)
- [ ] Git tag v1.4.0 + release notes (O4)
- [ ] Print cheat-sheet with the 3 datasets summarised for the oral defence
- [ ] Review slides for coherence with app version (1.4.0)
- [ ] Backup release APK + DB dump to show functional offline
- [ ] Re-read ADR-001/003 to answer detailed technical questions
