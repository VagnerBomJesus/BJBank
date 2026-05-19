# ADR-001: Estratégia de implementação PQC

**Data**: Maio de 2026
**Estado**: Aceite e implementado

## Contexto

O BJBank pretende demonstrar Criptografia Pós-Quântica (ML-KEM-768 + ML-DSA-65, FIPS 203/204) em operações bancárias móveis. A decisão crítica é **onde corre a cripto**: no dispositivo do cliente, no servidor, ou ambos.

A escolha tem impacto directo em:

- Modelo de ameaça (quem tem acesso à chave privada)
- Latência percebida pelo utilizador
- Reprodutibilidade dos resultados experimentais
- Tamanho do binário do app
- Maturidade das bibliotecas disponíveis

## Decisão

**Cripto pós-quântica delegada ao servidor** para a aplicação Flutter, com cripto simétrica (HKDF + AES-GCM) executada localmente.

### Onde corre cada primitiva

| Primitiva | Localização | Biblioteca |
|---|---|---|
| ML-KEM-768 (lógico no handshake) | Servidor | `@noble/post-quantum 0.4` (Deno) |
| ML-DSA-65 keygen + sign | Servidor | `@noble/post-quantum 0.4` (Deno) |
| ML-DSA-65 verify | Servidor | `@noble/post-quantum 0.4` (Deno) |
| HKDF-SHA-256 | Cliente Flutter | `pointycastle 3.9` |
| AES-256-GCM | Cliente Flutter | `pointycastle 3.9` |
| Web Crypto (decifragem server) | Servidor | Web Crypto API (Deno) |

### Chave privada do utilizador

A chave privada ML-DSA-65 do utilizador é gerada e armazenada na tabela `flutter_client_keys.secret_key_base64` no Supabase, protegida por RLS (acessível apenas via service_role) e usada exclusivamente dentro da Edge Function `flutter_sign_transfer`.

## Justificação

### Por que cripto server-side

- **Inexistência de bibliotecas Dart fiáveis para ML-DSA em Maio de 2026**:
  - `oqs-dart` não compila estavelmente em Android (problemas de FFI com liboqs)
  - `pointycastle` não implementa ML-DSA nem ML-KEM
  - Implementações JavaScript via interop introduzem complexidade e riscos de auditoria
- **Alternativa rejeitada**: FFI manual para liboqs — exigia *build* de liboqs para múltiplas arquiteturas Android + iOS + cross-compilação, esforço de engenharia desproporcional sem valor académico adicional
- **`@noble/post-quantum` é auditado** e está em conformidade com FIPS 203/204
- **Edge Functions Deno** com suporte `npm:` permitem usar a biblioteca directamente, sem builds intermédios
- **Documentação transparente** da limitação na própria aplicação (página "Sobre") e neste ADR

### Modelo de ameaça documentado

Um atacante que comprometa o servidor Supabase tem acesso às chaves privadas dos utilizadores. Esta limitação é:

- **Conhecida** — documentada na app e na dissertação
- **Mitigável em produção** — substituição por HSM (AWS CloudHSM, Azure Key Vault, GCP KMS)
- **Apropriada para o âmbito académico** — permite demonstrar todo o pipeline PQC end-to-end

## Pipeline comum

Independentemente de onde corre cada primitiva, o pipeline lógico é o mesmo:

1. Handshake → derivação HKDF-SHA-256 de chave de sessão
2. Construção de payload canónico (bytes determinísticos)
3. Assinatura ML-DSA-65 do payload
4. Envelope `[payload | signature]`
5. Cifragem AES-256-GCM com IV derivado e AAD = sessionId
6. POST `executar_transferencia` Edge Function
7. Verificação ML-DSA + RPC atómica

## Consequências

### Positivas

- Demonstração end-to-end do pipeline PQC em condições representativas de produção
- Backend Supabase com Edge Functions Deno serve como provedor universal de PQC para outros clientes futuros (Web, outras plataformas Flutter)
- Resultados experimentais reprodutíveis em ambiente conhecido (Deno + V8)

### Negativas

- A variante actual não cumpre o requisito de "chave privada nunca sai do device" típico de carteiras digitais — limitação conhecida e documentada
- Reprodutibilidade dos benchmarks depende do runtime Supabase Edge (Deno 2.1, V8 11.6) — ambiente partilhado com outros tenants

### Mitigações

- A chave privada ML-DSA do utilizador é gerada por seed aleatório `crypto.getRandomValues(32)` e nunca é mostrada nos logs
- O `pqc_public_key_base64` do utilizador é fixado na primeira assinatura (TOFU) — qualquer tentativa de substituição é rejeitada
- Em produção real, esta arquitectura migraria para HSM/KMS

## Alternativas consideradas

| Alternativa | Razão de rejeição |
|---|---|
| FFI manual para liboqs | Esforço de engenharia desproporcional, sem valor académico |
| Implementar ML-DSA em Dart puro | Risco enorme de bugs criptográficos; ~5000 LOC + KAT tests; fora de escopo |
| ml-dsa-js via interop Dart | Performance pior; dependência adicional difícil de auditar |
| Adiar até existir biblioteca Dart fiável | Bloquearia a tese indefinidamente |

## Decisões relacionadas

- **ADR-002 State Management** — Provider escolhido para gestão de estado; cripto fora desse padrão (singletons)
- **ADR-003 Security Strategy** — Modelo de ameaça completo e mitigações em produção
