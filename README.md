# BJBank - Criptografia Pós-Quântica em Aplicações Móveis

[![Flutter](https://img.shields.io/badge/Flutter-3.8.1-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.8.1-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase)](https://firebase.google.com)
[![NIST PQC](https://img.shields.io/badge/NIST-PQC%20Standard-green)](https://csrc.nist.gov/projects/post-quantum-cryptography)
[![License](https://img.shields.io/badge/License-Academic-blue)]()

<p align="center">
  <img src="assets/images/bjbank_logo.png" alt="BJBank Logo" width="200"/>
</p>

---

## Índice

1. [Sobre o Projeto](#sobre-o-projeto)
2. [Funcionalidades](#funcionalidades)
3. [Arquitetura do Sistema](#arquitetura-do-sistema)
4. [Criptografia Pós-Quântica (PQC)](#criptografia-pós-quântica-pqc)
5. [Algoritmos e Fórmulas](#algoritmos-e-fórmulas)
6. [Casos de Uso](#casos-de-uso)
7. [Design System](#design-system)
8. [Stack Tecnológica](#stack-tecnológica)
9. [Estrutura do Projeto](#estrutura-do-projeto)
10. [Instalação e Execução](#instalação-e-execução)
11. [Diagramas](#diagramas)
12. [Segurança](#segurança)
13. [Referências](#referências)

---

## Sobre o Projeto

O **BJBank** é uma aplicação móvel de banca desenvolvida como **prova de conceito** para investigação e implementação de protocolos de **Criptografia Pós-Quântica (PQC)** em ambiente móvel clássico.

### Contexto Académico

| Campo | Informação |
|-------|------------|
| **Projeto** | Dissertação de Mestrado |
| **Título** | Criptografia Pós-Quântica em Aplicações Móveis |
| **Autor** | Vagner Bom Jesus |
| **Email** | vagneripg@gmail.com |
| **Orientador** | Professor Rui A. P. Perdigão |
| **Instituição** | Instituto Politécnico da Guarda |
| **Data** | Fevereiro 2026 |

### Motivação

Com o avanço da computação quântica, os algoritmos criptográficos tradicionais (RSA, ECC) tornam-se vulneráveis ao **algoritmo de Shor**. O setor bancário é particularmente vulnerável, dada a sua dependência crítica em:

- Assinaturas digitais para autenticação de transações
- Encriptação de dados sensíveis
- Mecanismos de acordo de chaves

O BJBank implementa os algoritmos **CRYSTALS-Dilithium** e **CRYSTALS-Kyber**, padronizados pelo NIST em agosto de 2024 (FIPS 204 e FIPS 203), garantindo **resistência a ataques quânticos**.

### Classificação Científica da Implementação PQC

> Ver [ADR-001](docs/adr/ADR-001-pqc-implementation-mode.md) para a decisão arquitetural completa.

| Modo | BJBank (Atual) | Emulador | Produção liboqs (Futuro) |
|------|:---:|:---:|:---:|
| Tamanhos NIST corretos | ✅ | ✅ | ✅ |
| Pipeline UX completo | ✅ | ✅ | ✅ |
| FlutterSecureStorage | ✅ | ✅ | ✅ |
| Operações Module-LWE reais | ❌ | ❌ | ✅ |
| Fiat-Shamir transform | ❌ | ❌ | ✅ |
| Verificação matemática | ❌ | Parcial | ✅ |

**Classificação:** Simulador de Interface PQC = **PoC Arquitetural**

### Contribuições Científicas

1. **Arquitetura de Integração PQC-Mobile**: pipeline completo Flutter + Firebase + PQC
2. **Handshake Híbrido**: protocolo TLS ECDHE-P256 + Kyber768 KEM + HKDF-SHA256 ([ADR-002](docs/adr/ADR-002-hybrid-handshake-design.md))
3. **Benchmark Quantitativo**: latência + tamanho + overhead por algoritmo ([ADR-003](docs/adr/ADR-003-performance-benchmarking-strategy.md))
4. **Achado contra-intuitivo**: Dilithium3 KeyGen é 38% mais rápido que ECDSA-256 (203K vs 330K cycles), apesar de assinatura 45.7× maior

### Benchmark PQC vs. Clássico (Referência NIST/SUPERCOP @ Intel i7-6500U 2.5GHz)

| Algoritmo | Tipo | KeyGen (ms) | Sign/Enc (ms) | Pk (B) | Sig/CT (B) | Resist. Quântica |
|-----------|------|------------|--------------|--------|-----------|-----------------|
| RSA-2048 | Assinatura | 1.280 | 0.680 | 256 | 256 | ❌ |
| ECDSA-256 | Assinatura | 0.060 | 0.100 | 64 | 72 | ❌ |
| ECDH-P256 | KEM | 0.060 | 0.080 | 64 | 65 | ❌ |
| **Dilithium2** | Assinatura | **0.050** | **0.056** | **1312** | **2420** | **✅** |
| **Dilithium3** | Assinatura | **0.081** | **0.093** | **1952** | **3293** | **✅** |
| **Dilithium5** | Assinatura | **0.115** | **0.131** | **2592** | **4595** | **✅** |
| **Kyber512** | KEM | **0.023** | **0.025** | **800** | **768** | **✅** |
| **Kyber768** | KEM | **0.038** | **0.042** | **1184** | **1088** | **✅** |
| **Kyber1024** | KEM | **0.055** | **0.060** | **1568** | **1568** | **✅** |

### Handshake Híbrido (TLS ECDHE-P256 + Kyber768 KEM)

```
[ECDHE-P256 ~15ms] → [Kyber768 KEM ~25ms] → [HKDF-SHA256 ~3ms]
  Total: ~43ms | Overhead PQC: +2,272 bytes/sessão
```

> Ver [ADR-002](docs/adr/ADR-002-hybrid-handshake-design.md) para especificação completa do protocolo.

---

## Funcionalidades

### Autenticação e Segurança

| Funcionalidade | Descrição | Estado |
|----------------|-----------|--------|
| **Registo de Utilizador** | Email, telefone, palavra-passe com validação | ✅ |
| **Login com Email/Password** | Autenticação Firebase | ✅ |
| **PIN de 6 Dígitos** | Hash SHA-256 com salt (10.000 iterações) | ✅ |
| **Autenticação Biométrica** | Impressão digital / Face ID | ✅ |
| **Geração de Chaves PQC** | Par de chaves CRYSTALS-Dilithium no registo | ✅ |
| **Handshake Híbrido** | TLS ECDHE-P256 + Kyber768 KEM + HKDF-SHA256 | ✅ |
| **Benchmark PQC** | Comparação Dilithium/Kyber vs RSA/ECDSA | ✅ |
| **Exportação Métricas** | JSON + Markdown para dissertação | ✅ |
| **Timeout de Sessão** | Bloqueio após 5 minutos de inatividade | ✅ |

### Gestão de Contas

| Funcionalidade | Descrição | Estado |
|----------------|-----------|--------|
| **Dashboard** | Visualização de saldo e movimentos recentes | ✅ |
| **IBAN Português** | Formato PT50 com 21 dígitos numéricos | ✅ |
| **Saldo em Tempo Real** | Streaming de atualizações via Firestore | ✅ |
| **Análise Financeira** | Gráficos de receitas vs despesas mensais | ✅ |

### Transferências Bancárias

| Funcionalidade | Descrição | Estado |
|----------------|-----------|--------|
| **Transferência por IBAN** | Validação de IBAN português | ✅ |
| **Transferência MB WAY** | Por número de telefone (+351) | ✅ |
| **Assinatura PQC** | CRYSTALS-Dilithium em cada transação | ✅ |
| **Transações Atómicas** | Rollback automático em caso de erro | ✅ |
| **Recibo Digital** | Comprovativo com assinatura verificável | ✅ |

### MB WAY

| Funcionalidade | Descrição | Estado |
|----------------|-----------|--------|
| **Associação de Telefone** | Verificação OTP de 6 dígitos | ✅ |
| **Limite Diário** | €1.000 (configurável €100-€5.000) | ✅ |
| **Limite por Transação** | €500 (configurável €10-€1.000) | ✅ |
| **Contactos Recentes** | Últimos 10 destinatários | ✅ |
| **Rate Limiting** | Máx. 10 pesquisas/hora | ✅ |
| **Definições MB WAY** | Ecrã dedicado para gestão | ✅ |

### Histórico e Perfil

| Funcionalidade | Descrição | Estado |
|----------------|-----------|--------|
| **Histórico de Transações** | Lista ordenada com filtros | ✅ |
| **Filtro por Tipo** | Entradas, Saídas, Todos | ✅ |
| **Filtro por Período** | Mês/Ano | ✅ |
| **Detalhes da Transação** | Informação completa + assinatura PQC | ✅ |
| **Gestão de Perfil** | Nome, email, telefone, avatar | ✅ |

---

## Arquitetura do Sistema

### Arquitetura em Camadas

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        CAMADA DE APRESENTAÇÃO                            │
│                      Flutter/Dart - Material Design 3                    │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│  │  Splash  │ │   Home   │ │ Transfer │ │ History  │ │ Settings │      │
│  │  Screen  │ │  Screen  │ │  Screen  │ │  Screen  │ │  Screen  │      │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘      │
└───────┼────────────┼────────────┼────────────┼────────────┼─────────────┘
        │            │            │            │            │
        ▼            ▼            ▼            ▼            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        CAMADA DE ESTADO                                  │
│                     Provider Pattern (ChangeNotifier)                    │
│  ┌────────────────┐  ┌─────────────────┐  ┌──────────────────┐         │
│  │  AuthProvider  │  │ AccountProvider │  │ SettingsProvider │         │
│  └───────┬────────┘  └────────┬────────┘  └─────────┬────────┘         │
└──────────┼────────────────────┼─────────────────────┼───────────────────┘
           │                    │                     │
           ▼                    ▼                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        CAMADA DE SERVIÇOS                                │
│                    Lógica de Negócio e Integração                        │
│  ┌────────────┐ ┌──────────────┐ ┌────────────┐ ┌──────────────────┐   │
│  │AuthService │ │FirestoreServ.│ │ PqcService │ │SecureStorageServ.│   │
│  └─────┬──────┘ └──────┬───────┘ └─────┬──────┘ └────────┬─────────┘   │
└────────┼───────────────┼───────────────┼─────────────────┼──────────────┘
         │               │               │                 │
         ▼               ▼               ▼                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        CAMADA DE DADOS                                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────┐ │
│  │  Firebase Auth  │  │    Firestore    │  │  FlutterSecureStorage   │ │
│  │  (Autenticação) │  │   (Base Dados)  │  │  (Keychain/Keystore)    │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

### Diagrama de Contexto

```
                              ┌─────────────────┐
                              │   Utilizador    │
                              │    (Cliente)    │
                              └────────┬────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    │                  │                  │
                    ▼                  ▼                  ▼
           ┌───────────────┐  ┌───────────────┐  ┌───────────────┐
           │  Smartphone   │  │    Tablet     │  │   Desktop     │
           │  Android/iOS  │  │  Android/iOS  │  │   Windows     │
           └───────┬───────┘  └───────┬───────┘  └───────┬───────┘
                   │                  │                  │
                   └──────────────────┼──────────────────┘
                                      │
                                      ▼
                         ┌────────────────────────┐
                         │                        │
                         │    BJBank App          │
                         │    (Flutter)           │
                         │                        │
                         └───────────┬────────────┘
                                     │
            ┌────────────────────────┼────────────────────────┐
            │                        │                        │
            ▼                        ▼                        ▼
   ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
   │  Firebase Auth  │     │   Firestore     │     │   PQC Service   │
   │  (Autenticação) │     │   (dbbjbank)    │     │   (Dilithium)   │
   └─────────────────┘     └─────────────────┘     └─────────────────┘
```

### Fluxo de Dados

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   INPUT     │────▶│  PROVIDER   │────▶│   SERVICE   │────▶│  FIREBASE   │
│  (Widget)   │     │   (State)   │     │  (Logic)    │     │   (Data)    │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
       ▲                   │
       │                   │
       └───────────────────┘
         (notifyListeners)
```

---

## Criptografia Pós-Quântica (PQC)

### Ameaça Quântica

| Algoritmo | Ataque | Vulnerabilidade | Impacto Bancário |
|-----------|--------|-----------------|------------------|
| RSA-2048 | Shor (fatorização) | **CRÍTICO** | Falsificação de transações |
| ECDSA | Shor (log discreto) | **CRÍTICO** | Personificação de entidades |
| ECDH | Shor (acordo de chaves) | **CRÍTICO** | Interceção de comunicações |
| AES-256 | Grover (reduz para 128 bits) | Médio | Mitigável |
| SHA-256 | Grover (reduz para 128 bits) | Baixo | 128 bits seguro |

### Algoritmos NIST Implementados

| Padrão NIST | Algoritmo | Tipo | Uso no BJBank |
|-------------|-----------|------|---------------|
| **FIPS 204** (ML-DSA) | CRYSTALS-Dilithium | Assinatura Digital | Assinatura de transações |
| **FIPS 203** (ML-KEM) | CRYSTALS-Kyber | Encapsulamento de Chaves | Encriptação futura |

### Níveis de Segurança

#### CRYSTALS-Dilithium (Assinaturas)

| Parâmetro | Dilithium2 | **Dilithium3** | Dilithium5 |
|-----------|------------|----------------|------------|
| Nível NIST | 2 (~128 bits) | **3 (~192 bits)** | 5 (~256 bits) |
| Chave Pública | 1.312 bytes | **1.952 bytes** | 2.592 bytes |
| Chave Privada | 2.528 bytes | **4.000 bytes** | 4.864 bytes |
| Assinatura | 2.420 bytes | **3.293 bytes** | 4.595 bytes |
| Módulo (k, l) | (4, 4) | **(6, 5)** | (8, 7) |
| q (módulo) | 8.380.417 | **8.380.417** | 8.380.417 |
| n (grau) | 256 | **256** | 256 |

**Configuração Padrão:** Dilithium3 (Nível 3, 192 bits de segurança)

#### CRYSTALS-Kyber (Encriptação)

| Parâmetro | Kyber-512 | **Kyber-768** | Kyber-1024 |
|-----------|-----------|---------------|------------|
| Nível NIST | 1 (~128 bits) | **3 (~192 bits)** | 5 (~256 bits) |
| Chave Pública | 800 bytes | **1.184 bytes** | 1.568 bytes |
| Chave Privada | 1.632 bytes | **2.400 bytes** | 3.168 bytes |
| Texto Cifrado | 768 bytes | **1.088 bytes** | 1.568 bytes |
| Segredo Partilhado | 32 bytes | **32 bytes** | 32 bytes |

---

## Algoritmos e Fórmulas

### CRYSTALS-Dilithium

#### Base Matemática: Module-LWE

O Dilithium baseia-se no problema **Module Learning With Errors (MLWE)**:

```
Problema: Dado (A, t = A·s + e mod q), encontrar s

Onde:
  A ∈ R_q^(k×l)     - Matriz pública aleatória
  s ∈ R_q^l         - Vetor secreto (coeficientes pequenos)
  e ∈ R_q^k         - Vetor de erro (ruído)
  q = 8.380.417     - Módulo primo
  R_q = Z_q[X]/(X^n + 1), n = 256
```

#### Geração de Chaves (KeyGen)

```
ENTRADA: Semente aleatória ρ (256 bits)

1. A ← ExpandA(ρ)                    // Matriz k×l sobre R_q
2. (s₁, s₂) ← Sample(η)              // Vetores secretos com ||s_i||∞ ≤ η
3. t ← A·s₁ + s₂                     // Cálculo do vetor público
4. (t₁, t₀) ← Power2Round(t, d)      // Separar bits superiores/inferiores
5. tr ← H(ρ || t₁)                   // Hash para verificação

SAÍDA:
  pk = (ρ, t₁)                       // Chave pública: 1.952 bytes
  sk = (ρ, K, tr, s₁, s₂, t₀)       // Chave privada: 4.000 bytes
```

#### Assinatura (Sign)

```
ENTRADA: sk, mensagem M

1. μ ← H(tr || M)                    // Hash da mensagem com contexto
2. κ ← 0                             // Contador de tentativas
3. REPETIR:
   a. y ← ExpandMask(K, μ, κ)        // Vetor mascarado
   b. w ← A·y                        // Compromisso
   c. w₁ ← HighBits(w)               // Bits superiores
   d. c̃ ← H(μ || w₁)                 // Desafio
   e. c ← SampleInBall(c̃)            // Converter em polinómio
   f. z ← y + c·s₁                   // Resposta
   g. r₀ ← LowBits(w - c·s₂)         // Bits inferiores
   h. SE ||z||∞ ≥ γ₁ - β OU ||r₀||∞ ≥ γ₂ - β:
      κ ← κ + 1
      CONTINUAR                       // "Abort" - rejeitar e recomeçar
   i. h ← MakeHint(-c·t₀, w - c·s₂ + c·t₀)  // Dicas para verificação

4. RETORNAR σ = (c̃, z, h)           // Assinatura: 3.293 bytes
```

#### Verificação (Verify)

```
ENTRADA: pk = (ρ, t₁), M, σ = (c̃, z, h)

1. A ← ExpandA(ρ)                    // Reconstruir matriz
2. μ ← H(H(ρ || t₁) || M)            // Recalcular hash
3. c ← SampleInBall(c̃)               // Converter desafio
4. w'₁ ← UseHint(h, A·z - c·t₁·2^d)  // Reconstruir compromisso
5. RETORNAR c̃ == H(μ || w'₁) E ||z||∞ < γ₁ - β

SAÍDA: VERDADEIRO se assinatura válida, FALSO caso contrário
```

### CRYSTALS-Kyber

#### Encapsulamento de Chaves (KEM)

```
┌─────────────────────────────────────────────────────────────────────┐
│                        KYBER KEM                                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ALICE (Gera chaves)              BOB (Encapsula)                   │
│  ─────────────────────            ────────────────                  │
│  (pk, sk) ← KeyGen()              K, c ← Encaps(pk)                 │
│         │                                │                          │
│         │──────── pk ────────────────────▶                          │
│         │                                │                          │
│         ◀──────── c ─────────────────────│                          │
│         │                                │                          │
│  K ← Decaps(sk, c)                       │                          │
│         │                                │                          │
│         ▼                                ▼                          │
│      K (32 bytes)                    K (32 bytes)                   │
│      Segredo partilhado igual em ambos os lados                     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Hashing de PIN (SHA-256)

```
ENTRADA: PIN (6 dígitos), salt (16 bytes aleatórios)

1. hash₀ ← SHA-256(PIN || salt)
2. PARA i = 1 ATÉ 10.000:
   hash_i ← SHA-256(hash_{i-1} || salt)
3. RETORNAR hash_{10000}

Complexidade de ataque: O(10^6 × 10.000) = O(10^10) operações
```

### Validação de IBAN Português

```
ENTRADA: IBAN (25 caracteres: PT50 + 21 dígitos)

1. VERIFICAR formato: /^PT50\d{21}$/
2. Reorganizar: mover "PT50" para o fim
3. Converter letras: P=25, T=29 → "NNNNNNNNNNNNNNNNNNNN252950"
4. Calcular: resto = número mod 97
5. RETORNAR resto == 1

Exemplo:
  IBAN: PT50000201231234567890154
  Reorganizado: 000201231234567890154252950
  Mod 97: 1 (VÁLIDO)
```

---

## Casos de Uso

### UC01: Registar Conta

```
┌─────────────────────────────────────────────────────────────────────┐
│ UC01: REGISTAR CONTA                                                │
├─────────────────────────────────────────────────────────────────────┤
│ Ator Principal: Utilizador                                          │
│ Pré-condições: App instalada, conexão à internet                    │
│ Pós-condições: Conta criada, chaves PQC geradas                     │
├─────────────────────────────────────────────────────────────────────┤
│ FLUXO PRINCIPAL:                                                    │
│ 1. Utilizador abre a app                                            │
│ 2. Seleciona "Criar Conta"                                          │
│ 3. Insere: nome, email, telefone, palavra-passe                     │
│ 4. Sistema valida dados                                             │
│ 5. Sistema cria conta no Firebase Auth                              │
│ 6. Sistema gera par de chaves CRYSTALS-Dilithium                    │
│ 7. Sistema cria conta bancária com IBAN português                   │
│ 8. Sistema envia email de verificação                               │
│ 9. Utilizador é redirecionado para configuração de PIN              │
├─────────────────────────────────────────────────────────────────────┤
│ FLUXOS ALTERNATIVOS:                                                │
│ 4a. Email já existe → Mostrar erro "Email já registado"             │
│ 4b. Palavra-passe fraca → Mostrar requisitos de segurança           │
│ 6a. Erro na geração de chaves → Rollback e mostrar erro             │
└─────────────────────────────────────────────────────────────────────┘
```

### UC02: Realizar Transferência com Assinatura PQC

```
┌─────────────────────────────────────────────────────────────────────┐
│ UC02: REALIZAR TRANSFERÊNCIA                                        │
├─────────────────────────────────────────────────────────────────────┤
│ Ator Principal: Utilizador                                          │
│ Atores Secundários: Sistema PQC, Firebase                           │
│ Pré-condições: Utilizador autenticado, saldo suficiente             │
│ Pós-condições: Montante transferido, transação assinada com PQC     │
├─────────────────────────────────────────────────────────────────────┤
│ FLUXO PRINCIPAL:                                                    │
│ 1. Utilizador seleciona "Transferir"                                │
│ 2. Escolhe tipo: IBAN ou MB WAY                                     │
│ 3. Insere destinatário (IBAN ou telefone)                           │
│ 4. Insere montante e descrição                                      │
│ 5. Sistema valida:                                                  │
│    - Formato do destinatário                                        │
│    - Saldo disponível                                               │
│    - Limites MB WAY (se aplicável)                                  │
│ 6. Sistema mostra ecrã de confirmação                               │
│ 7. Utilizador confirma com PIN ou biometria                         │
│ 8. Sistema assina transação com CRYSTALS-Dilithium                  │
│ 9. Sistema executa transferência atómica no Firestore               │
│ 10. Sistema mostra recibo com assinatura verificável                │
├─────────────────────────────────────────────────────────────────────┤
│ FLUXOS ALTERNATIVOS:                                                │
│ 5a. Saldo insuficiente → Mostrar "Saldo insuficiente"               │
│ 5b. Limite MB WAY excedido → Mostrar limite disponível              │
│ 7a. PIN incorreto (3x) → Bloquear 30 segundos                       │
│ 9a. Erro na transação → Rollback automático                         │
└─────────────────────────────────────────────────────────────────────┘
```

### Diagrama de Sequência: Transferência com PQC

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│Utilizador│     │   UI    │     │Provider │     │PQCService│    │Firestore│
└────┬────┘     └────┬────┘     └────┬────┘     └────┬────┘     └────┬────┘
     │               │               │               │               │
     │ 1. Preenche   │               │               │               │
     │    dados      │               │               │               │
     │──────────────▶│               │               │               │
     │               │               │               │               │
     │               │ 2. Valida     │               │               │
     │               │    inputs     │               │               │
     │               │──────────────▶│               │               │
     │               │               │               │               │
     │               │ 3. Confirma   │               │               │
     │               │    PIN        │               │               │
     │◀──────────────│               │               │               │
     │               │               │               │               │
     │ 4. Insere PIN │               │               │               │
     │──────────────▶│               │               │               │
     │               │               │               │               │
     │               │ 5. Verifica   │               │               │
     │               │    PIN hash   │               │               │
     │               │──────────────▶│               │               │
     │               │               │               │               │
     │               │               │ 6. signTransaction()          │
     │               │               │──────────────▶│               │
     │               │               │               │               │
     │               │               │ 7. Dilithium  │               │
     │               │               │    signature  │               │
     │               │               │◀──────────────│               │
     │               │               │               │               │
     │               │               │ 8. createTransfer()           │
     │               │               │──────────────────────────────▶│
     │               │               │               │               │
     │               │               │               │ 9. Atomic     │
     │               │               │               │    transaction│
     │               │               │               │               │
     │               │               │ 10. Success   │               │
     │               │               │◀──────────────────────────────│
     │               │               │               │               │
     │               │ 11. Mostra    │               │               │
     │               │     recibo    │               │               │
     │◀──────────────│               │               │               │
     │               │               │               │               │
```

---

## Design System

### Paleta de Cores

```dart
// lib/theme/colors.dart

class BJBankColors {
  // Cores Principais
  static const Color primary = Color(0xFF1E3A5F);        // Azul escuro
  static const Color secondary = Color(0xFF3D5A80);      // Azul médio
  static const Color tertiary = Color(0xFF98C1D9);       // Azul claro

  // Cores de Estado
  static const Color success = Color(0xFF28A745);        // Verde
  static const Color warning = Color(0xFFFFC107);        // Amarelo
  static const Color error = Color(0xFFDC3545);          // Vermelho

  // Cores de Fundo
  static const Color background = Color(0xFFF8F9FA);     // Cinza claro
  static const Color surface = Color(0xFFFFFFFF);        // Branco
  static const Color surfaceVariant = Color(0xFFE9ECEF); // Cinza

  // Cores de Texto
  static const Color onPrimary = Color(0xFFFFFFFF);      // Branco
  static const Color onSurface = Color(0xFF212529);      // Preto
  static const Color onSurfaceVariant = Color(0xFF6C757D); // Cinza

  // Cores Especiais
  static const Color mbwayRed = Color(0xFFE31837);       // MB WAY vermelho
  static const Color gold = Color(0xFFD4AF37);           // Dourado (premium)
}
```

### Tipografia

```dart
// lib/theme/typography.dart

class BJBankTypography {
  static const String fontFamily = 'Inter';

  // Hierarquia de Texto
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}
```

### Espaçamento

```dart
// lib/theme/spacing.dart

class BJBankSpacing {
  static const double xs = 4.0;   // Extra pequeno
  static const double sm = 8.0;   // Pequeno
  static const double md = 16.0;  // Médio (padrão)
  static const double lg = 24.0;  // Grande
  static const double xl = 32.0;  // Extra grande
  static const double xxl = 48.0; // Muito grande
}
```

### Componentes UI

```
┌─────────────────────────────────────────────────────────────────────┐
│ COMPONENTES REUTILIZÁVEIS                                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  QuantumSafeBadge          VerifiedBadge           EncryptedBadge   │
│  ┌──────────────┐          ┌──────────────┐        ┌──────────────┐ │
│  │ 🛡️ PQC Safe │          │ ✓ Verificado │        │ 🔒 Encriptado│ │
│  └──────────────┘          └──────────────┘        └──────────────┘ │
│                                                                     │
│  PinInput (6 dígitos)                                               │
│  ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐                              │
│  │ ● │ │ ● │ │ ● │ │ ○ │ │ ○ │ │ ○ │                              │
│  └───┘ └───┘ └───┘ └───┘ └───┘ └───┘                              │
│                                                                     │
│  TransactionCard                                                    │
│  ┌─────────────────────────────────────────────┐                   │
│  │ 📤 Transferência para João Silva            │                   │
│  │ IBAN: PT50 0002 0123 1234 5678 9015 4       │                   │
│  │                                  -€150,00   │                   │
│  │ 01/02/2026 14:30         🛡️ Assinado PQC  │                   │
│  └─────────────────────────────────────────────┘                   │
│                                                                     │
│  BalanceCard                                                        │
│  ┌─────────────────────────────────────────────┐                   │
│  │         Saldo Disponível                    │                   │
│  │                                             │                   │
│  │           € 2.450,00                        │                   │
│  │                                             │                   │
│  │    IBAN: PT50 0002 0123 1234 5678 9015 4   │                   │
│  └─────────────────────────────────────────────┘                   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Stack Tecnológica

### Dependências Principais

```yaml
dependencies:
  # Core Flutter
  flutter: sdk
  provider: ^6.1.2           # Gestão de estado

  # Firebase
  firebase_core: ^4.4.0      # Core Firebase
  firebase_auth: ^6.1.4      # Autenticação
  cloud_firestore: ^6.1.2    # Base de dados

  # Segurança
  flutter_secure_storage: ^10.0.0  # Keychain/Keystore
  local_auth: ^2.3.0         # Biometria
  crypto: ^3.0.6             # Hashing SHA-256

  # UI
  pin_code_fields: ^8.0.1    # Input de PIN
  intl: ^0.20.2              # Formatação i18n
  image_picker: ^1.1.2       # Seleção de imagens
  share_plus: ^10.1.4        # Partilha

  # Rede
  dio: ^5.7.0                # HTTP client
  connectivity_plus: ^7.0.0  # Estado de rede

  # FFI (futuro liboqs)
  ffi: ^2.1.0                # Interface nativa
```

### Plataformas Suportadas

| Plataforma | Versão Mínima | Estado |
|------------|---------------|--------|
| Android | 8.0 (API 26) | ✅ Suportado |
| iOS | 13.0+ | ✅ Suportado |
| Windows | 10+ | ✅ Suportado |
| Web | - | ⏳ Futuro |
| macOS | - | ⏳ Futuro |
| Linux | - | ⏳ Futuro |

---

## Estrutura do Projeto

```
bjbank/
├── android/                          # Configuração Android
│   ├── app/
│   │   ├── build.gradle.kts         # Configuração Gradle
│   │   ├── google-services.json     # Config Firebase (gitignored)
│   │   └── src/main/
│   │       ├── AndroidManifest.xml  # Permissões e metadata
│   │       └── res/                 # Recursos (ícones, cores)
│   └── settings.gradle.kts
│
├── ios/                              # Configuração iOS
│   ├── Runner/
│   │   ├── Info.plist               # Configurações iOS
│   │   └── Assets.xcassets/         # Ícones e imagens
│   └── Runner.xcodeproj/
│
├── windows/                          # Configuração Windows
│
├── lib/                              # Código-fonte principal
│   ├── main.dart                    # Entry point
│   ├── app.dart                     # Widget raiz (MaterialApp)
│   ├── firebase_options.dart        # Configuração Firebase
│   │
│   ├── config/                      # Configurações da app
│   │   └── environment.dart         # Variáveis de ambiente
│   │
│   ├── models/                      # Modelos de dados (6 ficheiros)
│   │   ├── user_model.dart          # Modelo de utilizador
│   │   ├── account_model.dart       # Modelo de conta bancária
│   │   ├── transaction_model.dart   # Modelo de transação
│   │   ├── financial_summary.dart   # Resumo financeiro
│   │   └── mbway_contact_model.dart # Contactos MB WAY
│   │
│   ├── providers/                   # Gestão de estado (3 ficheiros)
│   │   ├── auth_provider.dart       # Estado de autenticação
│   │   ├── account_provider.dart    # Estado de conta/transações
│   │   └── settings_provider.dart   # Preferências do utilizador
│   │
│   ├── services/                    # Lógica de negócio (7 ficheiros)
│   │   ├── auth_service.dart        # Autenticação Firebase
│   │   ├── firestore_service.dart   # Operações Firestore
│   │   ├── pqc_service.dart         # Criptografia PQC
│   │   ├── secure_storage_service.dart # Armazenamento seguro
│   │   ├── otp_service.dart         # Verificação OTP
│   │   ├── seed_data_service.dart   # Dados de demonstração
│   │   └── biometric_service.dart   # Autenticação biométrica
│   │
│   ├── routes/                      # Navegação (2 ficheiros)
│   │   ├── app_routes.dart          # Constantes de rotas
│   │   └── app_router.dart          # Configuração de navegação
│   │
│   ├── screens/                     # Ecrãs UI (35+ ficheiros)
│   │   ├── splash/                  # Ecrã de carregamento
│   │   ├── onboarding/              # Introdução inicial
│   │   ├── auth/                    # Login, Registo, PIN
│   │   ├── home/                    # Dashboard principal
│   │   ├── transfer/                # Transferências (IBAN, MB WAY)
│   │   ├── history/                 # Histórico de transações
│   │   ├── profile/                 # Perfil do utilizador
│   │   ├── cards/                   # Gestão de cartões
│   │   └── settings/                # Definições, MB WAY settings
│   │
│   ├── theme/                       # Design system (8 ficheiros)
│   │   ├── colors.dart              # Paleta de cores
│   │   ├── typography.dart          # Estilos de texto
│   │   ├── spacing.dart             # Espaçamentos
│   │   ├── theme.dart               # ThemeData principal
│   │   └── app_theme.dart           # Configuração de tema
│   │
│   └── widgets/                     # Componentes reutilizáveis
│       ├── pqc/                     # Badges PQC
│       └── common/                  # Componentes comuns
│
├── test/                            # Testes
│   └── widget_test.dart
│
├── assets/                          # Recursos estáticos
│   ├── images/                      # Imagens e ícones
│   └── fonts/                       # Tipografias
│
├── docs/                            # Documentação
│   ├── README.md                    # Visão geral da documentação
│   ├── TECHNICAL_DOCUMENTATION.md   # Documentação técnica completa
│   ├── PQC-IMPLEMENTATION.md        # Implementação PQC detalhada
│   ├── IMPLEMENTATION_STATUS.md     # Estado de implementação
│   ├── design-system/               # Especificações de design
│   └── diagrams/                    # Diagramas Excalidraw
│
├── pubspec.yaml                     # Dependências do projeto
├── analysis_options.yaml            # Configurações de linting
├── firebase.json                    # Configuração Firebase
├── firestore.rules                  # Regras de segurança Firestore
├── CLAUDE.md                        # Instruções para desenvolvimento
└── README.md                        # Este ficheiro
```

---

## Instalação e Execução

### Pré-requisitos

- Flutter SDK 3.8.1+
- Dart SDK 3.8.1+
- Android Studio / Xcode (para emuladores)
- Conta Firebase (para backend)

### Passos de Instalação

```bash
# 1. Clonar repositório
git clone https://github.com/vagnerbomjesus/bjbank.git
cd bjbank

# 2. Instalar dependências
flutter pub get

# 3. Configurar Firebase (se necessário)
flutterfire configure

# 4. Executar a aplicação
flutter run

# 5. Executar em modo release
flutter run --release
```

### Comandos Úteis

```bash
# Analisar código
flutter analyze

# Executar testes
flutter test

# Gerar APK (Android)
flutter build apk --release

# Gerar IPA (iOS)
flutter build ios --release

# Gerar executável Windows
flutter build windows --release

# Limpar cache
flutter clean && flutter pub get
```

---

## Diagramas

### Modelo de Dados (Firestore)

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FIRESTORE COLLECTIONS                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  users/{userId}                                                     │
│  ├── id: string                                                     │
│  ├── email: string                                                  │
│  ├── name: string                                                   │
│  ├── phone: string                                                  │
│  ├── avatarUrl: string?                                             │
│  ├── pqcPublicKey: string (base64, 1952 bytes)                     │
│  ├── pqcAlgorithm: string ("dilithium3")                           │
│  ├── createdAt: timestamp                                           │
│  └── updatedAt: timestamp                                           │
│                                                                     │
│  accounts/{accountId}                                               │
│  ├── id: string                                                     │
│  ├── userId: string (FK)                                            │
│  ├── iban: string ("PT50XXXX...")                                  │
│  ├── accountNumber: string                                          │
│  ├── balance: number                                                │
│  ├── availableBalance: number                                       │
│  ├── type: string ("checking" | "savings")                         │
│  ├── mbWayLinked: boolean                                           │
│  ├── mbWayPhone: string?                                            │
│  ├── mbWayDailyLimit: number (default: 1000)                       │
│  ├── mbWayPerTransactionLimit: number (default: 500)               │
│  ├── mbWayDailyUsed: number                                         │
│  ├── mbWayLastResetDate: timestamp?                                 │
│  ├── mbWayLinkedAt: timestamp?                                      │
│  ├── createdAt: timestamp                                           │
│  └── updatedAt: timestamp                                           │
│                                                                     │
│  transactions/{transactionId}                                       │
│  ├── id: string                                                     │
│  ├── userId: string (FK)                                            │
│  ├── accountId: string (FK)                                         │
│  ├── type: string ("transfer" | "mbway" | "deposit" | ...)         │
│  ├── amount: number                                                 │
│  ├── currency: string ("EUR")                                       │
│  ├── description: string                                            │
│  ├── recipientName: string?                                         │
│  ├── recipientIban: string?                                         │
│  ├── recipientPhone: string?                                        │
│  ├── pqcSignature: string (base64, 3293 bytes)                     │
│  ├── pqcAlgorithm: string ("dilithium3")                           │
│  ├── status: string ("completed" | "pending" | "failed")           │
│  ├── date: timestamp                                                │
│  └── createdAt: timestamp                                           │
│                                                                     │
│  users/{userId}/mbway_contacts/{contactId}                          │
│  ├── id: string                                                     │
│  ├── name: string                                                   │
│  ├── phone: string                                                  │
│  ├── avatarUrl: string?                                             │
│  ├── lastUsed: timestamp                                            │
│  └── useCount: number                                               │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Fluxo de Autenticação

```
┌─────────────────────────────────────────────────────────────────────┐
│                     FLUXO DE AUTENTICAÇÃO                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│                          ┌──────────┐                               │
│                          │  SPLASH  │                               │
│                          └────┬─────┘                               │
│                               │                                     │
│                    ┌──────────┴──────────┐                          │
│                    │ Verificar sessão    │                          │
│                    └──────────┬──────────┘                          │
│                               │                                     │
│              ┌────────────────┴────────────────┐                    │
│              │                                 │                    │
│              ▼                                 ▼                    │
│     ┌────────────────┐              ┌────────────────┐              │
│     │  SEM SESSÃO    │              │  COM SESSÃO    │              │
│     └───────┬────────┘              └───────┬────────┘              │
│             │                               │                       │
│             ▼                               ▼                       │
│     ┌────────────────┐              ┌────────────────┐              │
│     │  ONBOARDING    │              │  PIN / BIOM.   │              │
│     └───────┬────────┘              └───────┬────────┘              │
│             │                               │                       │
│     ┌───────┴───────┐                       │                       │
│     │               │                       │                       │
│     ▼               ▼                       │                       │
│  ┌──────┐       ┌──────┐                   │                       │
│  │LOGIN │       │REGIST│                   │                       │
│  └──┬───┘       └──┬───┘                   │                       │
│     │              │                        │                       │
│     │   ┌──────────┘                        │                       │
│     │   │                                   │                       │
│     │   │  Gera chaves PQC                  │                       │
│     │   │  Cria conta bancária              │                       │
│     │   │                                   │                       │
│     ▼   ▼                                   │                       │
│  ┌────────────────┐                         │                       │
│  │  CONFIG. PIN   │                         │                       │
│  └───────┬────────┘                         │                       │
│          │                                  │                       │
│          └──────────────┬───────────────────┘                       │
│                         │                                           │
│                         ▼                                           │
│                  ┌────────────┐                                     │
│                  │    HOME    │                                     │
│                  │ (Dashboard)│                                     │
│                  └────────────┘                                     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Ciclo de Vida da Transação

```
┌─────────────────────────────────────────────────────────────────────┐
│                  CICLO DE VIDA DA TRANSAÇÃO                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────┐                                                        │
│  │ CRIADA  │ ── Dados inseridos pelo utilizador                     │
│  └────┬────┘                                                        │
│       │                                                             │
│       ▼                                                             │
│  ┌─────────┐                                                        │
│  │VALIDADA │ ── Verificação de saldo, limites, formato              │
│  └────┬────┘                                                        │
│       │                                                             │
│       ▼                                                             │
│  ┌─────────┐                                                        │
│  │ CONFIR. │ ── Utilizador confirma com PIN/biometria               │
│  └────┬────┘                                                        │
│       │                                                             │
│       ▼                                                             │
│  ┌─────────┐                                                        │
│  │ASSINADA │ ── CRYSTALS-Dilithium gera assinatura PQC              │
│  └────┬────┘    σ = Sign(sk, H(transação))                          │
│       │                                                             │
│       ▼                                                             │
│  ┌─────────┐                                                        │
│  │EXECUTADA│ ── Transação atómica no Firestore:                     │
│  └────┬────┘    1. Debitar origem                                   │
│       │         2. Creditar destino                                 │
│       │         3. Guardar transação com assinatura                 │
│       │                                                             │
│       ▼                                                             │
│  ┌─────────┐                                                        │
│  │COMPLETA │ ── Recibo gerado, assinatura verificável               │
│  └─────────┘                                                        │
│                                                                     │
│  EM CASO DE ERRO:                                                   │
│  ─────────────────                                                  │
│  ┌─────────┐                                                        │
│  │ FALHOU  │ ── Rollback automático, saldo restaurado               │
│  └─────────┘                                                        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Segurança

### Camadas de Proteção

```
┌─────────────────────────────────────────────────────────────────────┐
│                      MODELO DE SEGURANÇA                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  CAMADA 1: Autenticação                                             │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ Firebase Auth (email/password)                              │   │
│  │ PIN 6 dígitos (SHA-256, salt, 10.000 iterações)            │   │
│  │ Biometria (impressão digital / Face ID)                     │   │
│  │ Bloqueio após 3 tentativas falhadas (30 segundos)           │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  CAMADA 2: Autorização                                              │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ Firestore Security Rules (uid-based access)                 │   │
│  │ Rate limiting (10 pesquisas MB WAY/hora)                    │   │
│  │ Limites de transação (diário e por operação)                │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  CAMADA 3: Integridade                                              │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ CRYSTALS-Dilithium (assinatura de todas as transações)      │   │
│  │ Verificação de assinatura antes de exibir transação         │   │
│  │ Hash de dados sensíveis                                     │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  CAMADA 4: Confidencialidade                                        │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ FlutterSecureStorage (Keychain iOS / Keystore Android)      │   │
│  │ TLS 1.3 em todas as comunicações                            │   │
│  │ Chaves privadas nunca saem do dispositivo                   │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  CAMADA 5: Resistência Quântica                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ CRYSTALS-Dilithium Nível 3 (192 bits pós-quânticos)         │   │
│  │ CRYSTALS-Kyber Nível 3 (preparado para uso futuro)          │   │
│  │ Migração transparente entre níveis de segurança             │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Requisitos de Segurança NIST

| Requisito | Implementação | Estado |
|-----------|---------------|--------|
| Encriptação em repouso | FlutterSecureStorage (AES-256) | ✅ |
| Encriptação em trânsito | TLS 1.3 (Firebase) | ✅ |
| Assinaturas PQC | CRYSTALS-Dilithium Nível 3 | ✅ |
| Hash de credenciais | SHA-256 + salt + 10.000 iterações | ✅ |
| Autenticação multi-fator | PIN + Biometria | ✅ |
| Timeout de sessão | 5 minutos de inatividade | ✅ |
| Rate limiting | 10 operações/hora (MB WAY) | ✅ |
| Logs de auditoria | Firestore timestamps | ✅ |

---

## Referências

### Artigos e Padrões

1. Perdigão, Rui A.P. (2024): *From Quantum Information to Post-Quantum Security*. DOI: 10.46337/uc.241019.

2. NIST (2024): *FIPS 204 - Module-Lattice-Based Digital Signature Standard (ML-DSA)*. National Institute of Standards and Technology.

3. NIST (2024): *FIPS 203 - Module-Lattice-Based Key-Encapsulation Mechanism Standard (ML-KEM)*. National Institute of Standards and Technology.

4. Shor, P.W. (1994): *Algorithms for Quantum Computation: Discrete Logarithms and Factoring*. Proceedings of the 35th Annual Symposium on Foundations of Computer Science.

5. Grover, L.K. (1996): *A Fast Quantum Mechanical Algorithm for Database Search*. Proceedings of the 28th Annual ACM Symposium on Theory of Computing.

6. Bernstein, D.J., Buchmann, J., & Dahmen, E. (2009): *Post-Quantum Cryptography*. Springer Berlin.

7. Nielsen, M., & Chuang, I. (2010): *Quantum Computation and Quantum Information*. Cambridge University Press.

8. Ducas, L., et al. (2018): *CRYSTALS-Dilithium: A Lattice-Based Digital Signature Scheme*. IACR Transactions on Cryptographic Hardware and Embedded Systems.

9. Bos, J., et al. (2018): *CRYSTALS-Kyber: A CCA-Secure Module-Lattice-Based KEM*. IEEE European Symposium on Security and Privacy.

10. Lyubashevsky, V. (2009): *Fiat-Shamir with Aborts: Applications to Lattice and Factoring-Based Signatures*. ASIACRYPT 2009.

### Documentação Técnica

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [NIST Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography)
- [liboqs - Open Quantum Safe](https://openquantumsafe.org/)

---

## Licença

Este projeto é desenvolvido no âmbito académico do **Instituto Politécnico da Guarda**.

Todos os direitos reservados © 2026 Vagner Bom Jesus

---

## Contacto

| Campo | Informação |
|-------|------------|
| **Autor** | Vagner Bom Jesus |
| **Email** | vagneripg@gmail.com |
| **Orientador** | Professor Rui A. P. Perdigão |
| **Instituição** | Instituto Politécnico da Guarda |
| **Repositório** | [github.com/vagnerbomjesus/bjbank](https://github.com/vagnerbomjesus/bjbank) |

---

<p align="center">
  <b>BJBank</b> - Criptografia Pós-Quântica em Aplicações Móveis<br>
  <i>Dissertação de Mestrado - Instituto Politécnico da Guarda</i><br>
  <i>Fevereiro 2026</i>
</p>
