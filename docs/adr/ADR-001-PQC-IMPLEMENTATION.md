# ADR-001: Estratégia de implementação PQC (revisada)

**Data**: 19/05/2026
**Estado**: Aceite (revisto após migração para Supabase + abordagem dupla Kotlin/Flutter)

## Contexto

O BJBank pretende demonstrar Criptografia Pós-Quântica (ML-KEM-768 + ML-DSA-65, FIPS 203/204) em operações bancárias móveis. A decisão crítica é **onde corre a cripto**: no dispositivo do cliente, no servidor, ou ambos.

A escolha tem impacto directo em:
- Modelo de ameaça (quem tem acesso à chave privada)
- Latência percebida pelo utilizador
- Reprodutibilidade dos resultados experimentais
- Tamanho do binário do app
- Maturidade das bibliotecas disponíveis

## Decisão

**Implementação dupla deliberada** para servir como objecto de comparação na tese:

### Variante A — Kotlin (canónica)
- **Onde corre a cripto**: localmente no dispositivo Android
- **Biblioteca**: BouncyCastle 1.82 (Java/Kotlin)
- **Chave privada ML-DSA do cliente**: gerada e armazenada no Android Keystore
- **Modelo de ameaça**: forte — chave privada nunca sai do dispositivo

### Variante B — Flutter (pragmática)
- **Onde corre a cripto**: ML-DSA-65 é delegada ao servidor; AES-GCM e HKDF correm localmente
- **Biblioteca cliente**: PointyCastle (HKDF + AES-GCM)
- **Biblioteca servidor**: `@noble/post-quantum 0.4` (TypeScript/Deno)
- **Chave privada ML-DSA do cliente**: gerada e guardada na BD Supabase em `flutter_client_keys.secret_key_base64`, protegida por RLS (acessível só por service_role e usada apenas dentro da Edge Function `flutter_sign_transfer`)
- **Modelo de ameaça**: comprometido vs. variante A — atacante que compromete o backend Supabase tem acesso às chaves privadas dos utilizadores Flutter

### Pipeline comum a ambas variantes
1. Handshake → derivação HKDF-SHA-256
2. Construção de payload canónico (bytes idênticos nas duas variantes)
3. Assinatura ML-DSA-65 do payload
4. Envelope `[payload | signature]`
5. Cifragem AES-256-GCM com IV derivado e AAD = sessionId
6. POST `executar_transferencia` Edge Function
7. Verificação ML-DSA + RPC atómica

## Justificação

### Por que Kotlin com cripto local

- BouncyCastle 1.82 tem implementações estáveis de ML-KEM e ML-DSA (Maio 2026)
- JVM permite uso directo sem FFI / build extra
- Android Keystore oferece hardware-backed key storage em muitos dispositivos
- Representa o cenário "ideal" para banca móvel pós-quântica

### Por que Flutter com cripto server-side

- **Inexistência de libs Dart fiáveis para ML-DSA em Maio 2026**:
  - `oqs-dart` não compila em Android (problemas FFI com liboqs)
  - `pointycastle` não tem ML-DSA nem ML-KEM
- A alternativa seria FFI manual para liboqs — fora do escopo da tese
- Permite mostrar o **trade-off arquitectural** explicitamente na tese: "se a biblioteca não está disponível no cliente, qual é o overhead de delegar ao servidor?"
- A escolha está documentada no ecrã "Sobre" da app e visível ao utilizador

## Consequências

### Positivas
- Tese tem material rico para comparação: PQC client-side vs server-side, lados positivos e negativos de cada modelo
- Pipeline comum (handshake + payload canónico + envelope) é demonstrado em ambas — prova que a arquitectura é portável
- O backend Supabase com Edge Functions Deno serve como provedor universal de PQC para outros clientes futuros (Web, iOS) que também não tenham libs nativas

### Negativas
- Variante Flutter não cumpre o requisito de "chave privada nunca sai do device" — é uma limitação conhecida e documentada
- Reprodutibilidade dos benchmarks depende do runtime Supabase Edge (Deno 2.1, V8 11.6) — ambiente partilhado com outros tenants

### Mitigações
- A chave privada ML-DSA do servidor para o utilizador é gerada por seed aleatório `crypto.getRandomValues(32)` e nunca é mostrada nos logs
- O `pqc_public_key_base64` do utilizador é pin no primeiro signing (TOFU) — qualquer tentativa de substituição é rejeitada
- Em produção real, esta arquitectura migraria para HSM/KMS do lado do servidor (AWS CloudHSM, Azure Key Vault, GCP KMS)

## Alternativas consideradas

### Alternativa 1: Apenas Kotlin (cripto local) — rejeitada
Limitaria a tese a Android-only e perderia o ponto de comparação. Flutter é uma das stacks mais relevantes em banca móvel multi-plataforma.

### Alternativa 2: Flutter com FFI manual para liboqs — rejeitada
Esforço de engenharia desproporcionado (build de liboqs para 4 arquitecturas Android + iOS + cross-compilação) sem valor académico adicional.

### Alternativa 3: Flutter com ml-dsa-js sobre `js_isolate` — rejeitada
Performance pior que delegar ao servidor (carregamento de JS runtime no Dart VM), e introduzia dependência adicional difícil de auditar.

### Alternativa 4: Implementar ML-DSA em Dart puro — rejeitada
Esforço enorme + risco de bugs criptográficos. Fora do escopo da tese.

## Decisões relacionadas

- **ADR-002 State Management** — Provider escolhido para simplicidade; estado de cripto é fora desse padrão (singletons)
- **ADR-003 Security Strategy** — Detalha modelo de ameaça completo e mitigações
