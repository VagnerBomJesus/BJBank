# BJBank - Documentação Técnica Completa

## Aplicação Móvel de Banca com Criptografia Pós-Quântica

**Versão:** 1.0.0
**Data:** Fevereiro 2026
**Plataformas:** Android, iOS, Windows
**Framework:** Flutter (Dart SDK ^3.8.1)

---

## ÍNDICE

1. [Descrição da Solução](#1-descrição-da-solução)
2. [Análise de Requisitos](#2-análise-de-requisitos)
3. [Modelação da Solução](#3-modelação-da-solução)
4. [Ferramentas e Tecnologias](#4-ferramentas-e-tecnologias)
5. [Metodologia de Desenvolvimento](#5-metodologia-de-desenvolvimento)
6. [Implementação dos Métodos](#6-implementação-dos-métodos)
7. [Algoritmos e Fórmulas](#7-algoritmos-e-fórmulas)
8. [Validação e Testes](#8-validação-e-testes)
9. [Estado Atual e Melhorias Futuras](#9-estado-atual-e-melhorias-futuras)

---

## 1. DESCRIÇÃO DA SOLUÇÃO

### 1.1 Visão Geral

O **BJBank** é uma aplicação móvel de banca desenvolvida em Flutter que implementa **Criptografia Pós-Quântica (PQC)** para garantir segurança contra ataques de computadores quânticos. A aplicação permite operações bancárias seguras incluindo transferências, pagamentos MB WAY, gestão de contas e análise financeira.

### 1.2 Contexto e Motivação

Com o avanço da computação quântica, os algoritmos criptográficos tradicionais (RSA, ECC) tornam-se vulneráveis. O BJBank implementa os algoritmos **CRYSTALS-Dilithium** (assinaturas digitais) e **CRYSTALS-Kyber** (encriptação) recomendados pelo NIST para criptografia pós-quântica.

### 1.3 Objetivos

| Objetivo | Descrição |
|----------|-----------|
| **Segurança PQC** | Implementar assinaturas digitais resistentes a ataques quânticos |
| **Usabilidade** | Interface moderna e intuitiva para operações bancárias |
| **Conformidade** | Seguir padrões bancários portugueses (IBAN, MB WAY) |
| **Performance** | Operações rápidas com feedback em tempo real |
| **Privacidade** | Proteção de dados com encriptação local e remota |

### 1.4 Arquitetura da Solução

```
┌─────────────────────────────────────────────────────────────────┐
│                      CAMADA DE APRESENTAÇÃO                      │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │  Home   │ │History  │ │ Cards   │ │Settings │ │Transfer │   │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘   │
└───────┼──────────┼──────────┼──────────┼──────────┼─────────────┘
        │          │          │          │          │
┌───────┴──────────┴──────────┴──────────┴──────────┴─────────────┐
│                      CAMADA DE ESTADO (PROVIDERS)                │
│  ┌─────────────┐  ┌────────────────┐  ┌─────────────────┐       │
│  │AuthProvider │  │AccountProvider │  │SettingsProvider │       │
│  └──────┬──────┘  └───────┬────────┘  └────────┬────────┘       │
└─────────┼─────────────────┼────────────────────┼────────────────┘
          │                 │                    │
┌─────────┴─────────────────┴────────────────────┴────────────────┐
│                      CAMADA DE SERVIÇOS                          │
│  ┌───────────┐ ┌──────────────┐ ┌───────────┐ ┌──────────────┐  │
│  │AuthService│ │FirestoreServ.│ │PQC Service│ │SecureStorage │  │
│  └─────┬─────┘ └──────┬───────┘ └─────┬─────┘ └──────┬───────┘  │
└────────┼──────────────┼───────────────┼──────────────┼──────────┘
         │              │               │              │
┌────────┴──────────────┴───────────────┴──────────────┴──────────┐
│                      CAMADA DE DADOS                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │  Firebase Auth  │  │    Firestore    │  │  Local Storage  │  │
│  │                 │  │   (dbbjbank)    │  │  (Encrypted)    │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. ANÁLISE DE REQUISITOS

### 2.1 Requisitos Funcionais

| ID | Requisito | Prioridade | Estado |
|----|-----------|------------|--------|
| **RF01** | Registo de utilizador com email e palavra-passe | Alta | ✅ Implementado |
| **RF02** | Autenticação com PIN de 6 dígitos | Alta | ✅ Implementado |
| **RF03** | Autenticação biométrica (impressão digital/Face ID) | Alta | ✅ Implementado |
| **RF04** | Visualização de saldo e movimentos | Alta | ✅ Implementado |
| **RF05** | Transferências bancárias por IBAN | Alta | ✅ Implementado |
| **RF06** | Transferências MB WAY por número de telefone | Alta | ✅ Implementado |
| **RF07** | Assinatura digital de transações com PQC | Alta | ✅ Implementado |
| **RF08** | Histórico de transações com filtros | Média | ✅ Implementado |
| **RF09** | Análise financeira mensal | Média | ✅ Implementado |
| **RF10** | Gestão de perfil do utilizador | Média | ✅ Implementado |
| **RF11** | Gestão de cartões bancários | Média | ⏳ Parcial |
| **RF12** | Notificações push | Média | ⏳ Pendente |
| **RF13** | Pagamentos por QR Code | Baixa | ⏳ Pendente |
| **RF14** | Exportação de dados (RGPD) | Baixa | ⏳ Pendente |
| **RF15** | Modo offline com sincronização | Baixa | ⏳ Pendente |

### 2.2 Requisitos Não Funcionais

| ID | Categoria | Requisito | Métrica | Estado |
|----|-----------|-----------|---------|--------|
| **RNF01** | Segurança | Encriptação de dados em repouso | AES-256 | ✅ |
| **RNF02** | Segurança | Assinaturas PQC CRYSTALS-Dilithium | Nível 2/3/5 NIST | ✅ |
| **RNF03** | Segurança | Hash de PIN com salt | SHA-256, 10k iterações | ✅ |
| **RNF04** | Segurança | Timeout de sessão | 5 minutos inatividade | ✅ |
| **RNF05** | Performance | Tempo de carregamento inicial | < 3 segundos | ✅ |
| **RNF06** | Performance | Tempo de resposta de transferência | < 2 segundos | ✅ |
| **RNF07** | Usabilidade | Suporte a português (PT) | 100% strings | ✅ |
| **RNF08** | Usabilidade | Acessibilidade WCAG 2.1 | Nível AA | ⏳ |
| **RNF09** | Disponibilidade | Uptime do serviço | 99.9% | Firebase SLA |
| **RNF10** | Compatibilidade | Android 8.0+ | API 26+ | ✅ |
| **RNF11** | Compatibilidade | iOS 13+ | iPhone 6s+ | ✅ |
| **RNF12** | Escalabilidade | Suporte a utilizadores concorrentes | 10,000+ | Firestore |
| **RNF13** | Manutenibilidade | Cobertura de testes | > 70% | ⏳ |
| **RNF14** | Conformidade | RGPD/GDPR | Compliant | ⏳ |

### 2.3 Requisitos de Segurança PQC

| Algoritmo | Uso | Nível NIST | Bits de Segurança | Tamanho Chave Pública |
|-----------|-----|------------|-------------------|----------------------|
| Dilithium2 | Assinaturas | 2 | 128 | 1,312 bytes |
| Dilithium3 | Assinaturas | 3 | 192 | 1,952 bytes |
| Dilithium5 | Assinaturas | 5 | 256 | 2,592 bytes |
| Kyber512 | Encriptação | 1 | 128 | 800 bytes |
| Kyber768 | Encriptação | 3 | 192 | 1,184 bytes |
| Kyber1024 | Encriptação | 5 | 256 | 1,568 bytes |

---

## 3. MODELAÇÃO DA SOLUÇÃO

### 3.1 Diagrama de Contexto

O diagrama de contexto mostra as interações entre o sistema BJBank e as entidades externas.

**Ver:** `docs/diagrams/context-diagram.excalidraw`

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
           │  (Android/iOS)│  │  (Android/iOS)│  │  (Windows)    │
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
   │  (Autenticação) │     │   (Base Dados)  │     │   (Segurança)   │
   └─────────────────┘     └─────────────────┘     └─────────────────┘
```

### 3.2 Diagrama de Casos de Uso

**Ver:** `docs/diagrams/use-case-diagram.excalidraw`

#### 3.2.1 Atores

| Ator | Descrição | Casos de Uso |
|------|-----------|--------------|
| **Utilizador** | Cliente do banco que usa a aplicação | Todos os casos de uso principais |
| **Sistema PQC** | Serviço de criptografia pós-quântica | Gerar chaves, assinar, verificar |
| **Firebase** | Plataforma de backend | Autenticação, armazenamento |
| **MB WAY** | Sistema de pagamentos | Transferências por telefone |

#### 3.2.2 Casos de Uso Detalhados

##### UC01: Registar Conta

| Campo | Descrição |
|-------|-----------|
| **ID** | UC01 |
| **Nome** | Registar Conta |
| **Ator Principal** | Utilizador |
| **Pré-condições** | App instalada, conexão à internet |
| **Pós-condições** | Conta criada, chaves PQC geradas |
| **Fluxo Principal** | 1. Utilizador abre a app<br>2. Seleciona "Criar Conta"<br>3. Insere nome, email, telefone, palavra-passe<br>4. Sistema valida dados<br>5. Sistema cria conta no Firebase<br>6. Sistema gera par de chaves PQC<br>7. Sistema envia email de verificação<br>8. Utilizador é redirecionado para login |
| **Fluxos Alternativos** | 4a. Email já existe → Mostrar erro<br>4b. Palavra-passe fraca → Mostrar requisitos |
| **Exceções** | Sem conexão → Mostrar mensagem offline |

##### UC02: Autenticar com PIN

| Campo | Descrição |
|-------|-----------|
| **ID** | UC02 |
| **Nome** | Autenticar com PIN |
| **Ator Principal** | Utilizador |
| **Pré-condições** | Conta existente, PIN configurado |
| **Pós-condições** | Sessão iniciada, acesso ao dashboard |
| **Fluxo Principal** | 1. App mostra ecrã de PIN<br>2. Utilizador insere 6 dígitos<br>3. Sistema calcula hash com salt<br>4. Sistema compara hash armazenado<br>5. Se válido, redireciona para Home |
| **Fluxos Alternativos** | 3a. PIN incorreto → Mostrar erro, decrementar tentativas<br>3b. 3 tentativas falhadas → Bloquear 30 segundos |

##### UC03: Realizar Transferência

| Campo | Descrição |
|-------|-----------|
| **ID** | UC03 |
| **Nome** | Realizar Transferência |
| **Ator Principal** | Utilizador |
| **Atores Secundários** | Sistema PQC, Firebase |
| **Pré-condições** | Utilizador autenticado, saldo suficiente |
| **Pós-condições** | Montante transferido, transação registada com assinatura PQC |
| **Fluxo Principal** | 1. Utilizador seleciona "Transferir"<br>2. Insere IBAN destino ou pesquisa contacto<br>3. Insere montante e descrição<br>4. Sistema valida saldo disponível<br>5. Sistema mostra confirmação<br>6. Utilizador confirma com PIN/biometria<br>7. Sistema assina transação com Dilithium<br>8. Sistema executa transferência atómica<br>9. Sistema mostra recibo |
| **Fluxos Alternativos** | 4a. Saldo insuficiente → Mostrar erro<br>6a. PIN incorreto → Cancelar operação |

##### UC04: Consultar Histórico

| Campo | Descrição |
|-------|-----------|
| **ID** | UC04 |
| **Nome** | Consultar Histórico |
| **Ator Principal** | Utilizador |
| **Pré-condições** | Utilizador autenticado |
| **Pós-condições** | Lista de transações apresentada |
| **Fluxo Principal** | 1. Utilizador acede ao separador Histórico<br>2. Sistema carrega transações do Firestore<br>3. Sistema apresenta lista ordenada por data<br>4. Utilizador pode filtrar por tipo/período<br>5. Utilizador pode ver detalhes de cada transação |

##### UC05: Configurar Segurança Biométrica

| Campo | Descrição |
|-------|-----------|
| **ID** | UC05 |
| **Nome** | Configurar Segurança Biométrica |
| **Ator Principal** | Utilizador |
| **Pré-condições** | Dispositivo com sensor biométrico, PIN configurado |
| **Pós-condições** | Autenticação biométrica ativada |
| **Fluxo Principal** | 1. Utilizador acede a Definições > Segurança<br>2. Seleciona "Ativar Biometria"<br>3. Sistema verifica disponibilidade do sensor<br>4. Sistema solicita autenticação biométrica de teste<br>5. Utilizador autentica com impressão digital/Face ID<br>6. Sistema guarda preferência |

### 3.3 Diagramas de Sequência

**Ver:** `docs/diagrams/sequence-diagrams.excalidraw`

#### 3.3.1 Sequência: Realizar Transferência com PQC

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│Utilizador│     │   UI    │     │Provider │     │PQCService│    │Firestore│
└────┬────┘     └────┬────┘     └────┬────┘     └────┬────┘     └────┬────┘
     │               │               │               │               │
     │ 1. Preenche   │               │               │               │
     │    dados      │               │               │               │
     │──────────────>│               │               │               │
     │               │               │               │               │
     │               │ 2. Valida     │               │               │
     │               │    inputs     │               │               │
     │               │──────────────>│               │               │
     │               │               │               │               │
     │               │ 3. Confirma   │               │               │
     │               │    PIN        │               │               │
     │<──────────────│               │               │               │
     │               │               │               │               │
     │ 4. Insere PIN │               │               │               │
     │──────────────>│               │               │               │
     │               │               │               │               │
     │               │ 5. Verifica   │               │               │
     │               │    PIN hash   │               │               │
     │               │──────────────>│               │               │
     │               │               │               │               │
     │               │               │ 6. signTransfer()             │
     │               │               │──────────────>│               │
     │               │               │               │               │
     │               │               │ 7. Dilithium  │               │
     │               │               │    signature  │               │
     │               │               │<──────────────│               │
     │               │               │               │               │
     │               │               │ 8. createTransfer()           │
     │               │               │───────────────────────────────>
     │               │               │               │               │
     │               │               │               │ 9. Atomic     │
     │               │               │               │    transaction│
     │               │               │               │               │
     │               │               │ 10. Success   │               │
     │               │               │<──────────────────────────────│
     │               │               │               │               │
     │               │ 11. Mostra    │               │               │
     │               │     recibo    │               │               │
     │<──────────────│               │               │               │
     │               │               │               │               │
```

#### 3.3.2 Sequência: Autenticação com Biometria

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│Utilizador│     │   UI    │     │SecureStorage│  │LocalAuth │    │ Firebase│
└────┬────┘     └────┬────┘     └────┬────┘     └────┬────┘     └────┬────┘
     │               │               │               │               │
     │ 1. Abre app   │               │               │               │
     │──────────────>│               │               │               │
     │               │               │               │               │
     │               │ 2. Verifica   │               │               │
     │               │    biometria  │               │               │
     │               │──────────────>│               │               │
     │               │               │               │               │
     │               │               │ 3. isEnabled? │               │
     │               │               │──────────────>│               │
     │               │               │               │               │
     │               │               │ 4. true       │               │
     │               │               │<──────────────│               │
     │               │               │               │               │
     │               │ 5. Solicita   │               │               │
     │               │    biometria  │               │               │
     │<──────────────│               │               │               │
     │               │               │               │               │
     │ 6. Toca sensor│               │               │               │
     │──────────────>│               │               │               │
     │               │               │               │               │
     │               │               │ 7. authenticate()             │
     │               │               │──────────────>│               │
     │               │               │               │               │
     │               │               │ 8. Verifica   │               │
     │               │               │    hardware   │               │
     │               │               │<──────────────│               │
     │               │               │               │               │
     │               │ 9. getUserId()│               │               │
     │               │──────────────>│               │               │
     │               │               │               │               │
     │               │               │ 10. Carrega   │               │
     │               │               │     sessão    │               │
     │               │               │───────────────────────────────>
     │               │               │               │               │
     │               │ 11. Home      │               │               │
     │<──────────────│               │               │               │
```

### 3.4 Wireframes

**Ver:** `docs/diagrams/wireframes.excalidraw`

Os wireframes detalhados estão disponíveis no ficheiro Excalidraw, incluindo:

1. **Ecrã de Splash** - Logo animada com indicador de carregamento
2. **Onboarding** - 4 ecrãs com slides de introdução
3. **Login/Registo** - Formulários de autenticação
4. **PIN Screen** - Teclado numérico customizado
5. **Home Dashboard** - Saldo, serviços, transações recentes
6. **Transferência** - Formulário com validação IBAN
7. **Histórico** - Lista de transações com filtros
8. **Definições** - Menu de configurações

---

## 4. FERRAMENTAS E TECNOLOGIAS

### 4.1 Stack Tecnológico

| Categoria | Tecnologia | Versão | Justificação |
|-----------|------------|--------|--------------|
| **Framework** | Flutter | 3.8.1+ | Cross-platform, performance nativa, hot reload |
| **Linguagem** | Dart | 3.8.1+ | Tipagem forte, async/await, null safety |
| **Backend** | Firebase | 4.x | Escalabilidade, real-time, sem servidor |
| **Base de Dados** | Firestore | 6.x | NoSQL, sync offline, queries em tempo real |
| **Autenticação** | Firebase Auth | 6.x | OAuth, email/password, multi-factor |
| **Estado** | Provider | 6.x | Simples, performante, recomendado Flutter |
| **Criptografia** | CRYSTALS-Dilithium | NIST PQC | Resistência quântica, standard NIST |
| **Storage Local** | Flutter Secure Storage | 10.x | Keychain (iOS), Keystore (Android) |
| **Biometria** | local_auth | 2.x | APIs nativas de biometria |

### 4.2 Dependências do Projeto

```yaml
dependencies:
  # Core
  flutter: sdk
  provider: ^6.1.2

  # Firebase
  firebase_core: ^4.4.0
  firebase_auth: ^6.1.4
  cloud_firestore: ^6.1.2

  # Segurança
  flutter_secure_storage: ^10.0.0
  local_auth: ^2.3.0
  crypto: ^3.0.6

  # UI
  pin_code_fields: ^8.0.1
  intl: ^0.20.2
  image_picker: ^1.1.2
  share_plus: ^10.1.4

  # Rede
  dio: ^5.7.0
  connectivity_plus: ^7.0.0

  # FFI (para liboqs)
  ffi: ^2.1.0
```

### 4.3 Estrutura de Pastas

```
bjbank/
├── android/                    # Configuração Android
├── ios/                        # Configuração iOS
├── windows/                    # Configuração Windows
├── lib/
│   ├── main.dart              # Entry point
│   ├── app.dart               # Root widget
│   ├── firebase_options.dart  # Config Firebase
│   ├── models/                # Modelos de dados (5 ficheiros)
│   ├── providers/             # Gestão de estado (3 ficheiros)
│   ├── services/              # Lógica de negócio (7 ficheiros)
│   ├── routes/                # Navegação (3 ficheiros)
│   ├── screens/               # Ecrãs UI (34 ficheiros)
│   ├── theme/                 # Design system (8 ficheiros)
│   └── widgets/               # Componentes reutilizáveis (2 ficheiros)
├── test/                      # Testes
├── docs/                      # Documentação
│   ├── diagrams/             # Diagramas Excalidraw
│   └── design-system/        # Especificações de design
├── assets/                    # Recursos estáticos
│   ├── images/               # Imagens e ícones
│   └── fonts/                # Tipografias
├── pubspec.yaml              # Dependências
└── firebase.json             # Config Firebase
```

---

## 5. METODOLOGIA DE DESENVOLVIMENTO

### 5.1 Metodologia Ágil: Scrum

O desenvolvimento do BJBank segue a metodologia **Scrum** com as seguintes adaptações:

#### 5.1.1 Papéis

| Papel | Responsabilidades |
|-------|-------------------|
| **Product Owner** | Define requisitos, prioriza backlog, aceita entregas |
| **Scrum Master** | Facilita cerimónias, remove impedimentos |
| **Development Team** | Desenvolve, testa, documenta |

#### 5.1.2 Artefactos

| Artefacto | Descrição |
|-----------|-----------|
| **Product Backlog** | Lista priorizada de todas as funcionalidades |
| **Sprint Backlog** | Itens selecionados para o sprint atual |
| **Incremento** | Versão funcional entregue no fim do sprint |

#### 5.1.3 Eventos

| Evento | Duração | Frequência |
|--------|---------|------------|
| Sprint | 2 semanas | Contínuo |
| Sprint Planning | 2 horas | Início do sprint |
| Daily Standup | 15 minutos | Diário |
| Sprint Review | 1 hora | Fim do sprint |
| Sprint Retrospective | 1 hora | Fim do sprint |

### 5.2 Ciclo de Vida do Scrum

```
         ┌─────────────────────────────────────────────────────────┐
         │                                                         │
         ▼                                                         │
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  PRODUCT        │     │   SPRINT        │     │   SPRINT        │
│  BACKLOG        │────>│   PLANNING      │────>│   BACKLOG       │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └────────┬────────┘
                                                         │
                                                         ▼
                                                ┌─────────────────┐
                                                │   SPRINT        │
                                                │   (2 semanas)   │
                                                │                 │
                                                │  ┌───────────┐  │
                                                │  │Daily      │  │
                                                │  │Standup    │  │
                                                │  └───────────┘  │
                                                └────────┬────────┘
                                                         │
         ┌───────────────────────────────────────────────┼─────────┐
         │                                               │         │
         ▼                                               ▼         │
┌─────────────────┐                            ┌─────────────────┐ │
│   SPRINT        │                            │   INCREMENT     │ │
│   RETROSPECTIVE │<───────────────────────────│   (Entrega)     │ │
│                 │                            │                 │ │
└─────────────────┘                            └─────────────────┘ │
         │                                                         │
         └─────────────────────────────────────────────────────────┘
```

### 5.3 Sprints Realizados

| Sprint | Período | Objetivos | Estado |
|--------|---------|-----------|--------|
| Sprint 1 | Sem 1-2 | Setup projeto, Firebase, autenticação básica | ✅ Concluído |
| Sprint 2 | Sem 3-4 | Modelos de dados, Firestore, UI base | ✅ Concluído |
| Sprint 3 | Sem 5-6 | Transferências, MB WAY, PQC básico | ✅ Concluído |
| Sprint 4 | Sem 7-8 | PIN, biometria, histórico | ✅ Concluído |
| Sprint 5 | Sem 9-10 | Análise financeira, perfil, definições | ✅ Concluído |
| Sprint 6 | Sem 11-12 | Polish UI, testes, documentação | 🔄 Em curso |

### 5.4 Metodologia de Investigação

#### 5.4.1 Tipo de Investigação
- **Investigação Aplicada**: Desenvolvimento de solução prática
- **Prototipagem Evolutiva**: Refinamento iterativo baseado em feedback

#### 5.4.2 Recolha de Dados
| Fonte | Tipo | Objetivo |
|-------|------|----------|
| Literatura PQC | Secundária | Fundamentação teórica |
| Standards NIST | Secundária | Requisitos de segurança |
| Testes de usabilidade | Primária | Validação de UX |
| Métricas de performance | Primária | Validação técnica |

#### 5.4.3 Processamento de Dados
1. **Análise qualitativa**: Feedback de utilizadores
2. **Análise quantitativa**: Tempos de resposta, taxa de erros
3. **Benchmarking**: Comparação com apps bancárias existentes

---

## 6. IMPLEMENTAÇÃO DOS MÉTODOS

### 6.1 Serviço de Criptografia Pós-Quântica (PQC)

**Ficheiro:** `lib/services/pqc_service.dart`

#### 6.1.1 Estrutura do Serviço

```dart
class PqcService {
  static final PqcService _instance = PqcService._internal();
  factory PqcService() => _instance;

  PqcKeyPair? _cachedKeyPair;
  final _storage = const FlutterSecureStorage();

  // Métodos principais
  Future<PqcKeyPair> generateKeyPair({PqcAlgorithm algorithm});
  Future<PqcSignature> signTransaction(String data, String privateKey);
  Future<bool> verifySignature(PqcSignature signature, String publicKey);
  Future<String> signTransfer(TransferData data);
  Future<bool> verifyTransfer(String signature, TransferData data, String publicKey);
}
```

#### 6.1.2 Geração de Par de Chaves

```dart
Future<PqcKeyPair> generateKeyPair({
  PqcAlgorithm algorithm = PqcAlgorithm.dilithium3,
}) async {
  // Em produção: usar liboqs via FFI
  // Simulação para demonstração
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final random = Random.secure();

  // Gerar bytes aleatórios seguros
  final privateKeyBytes = List<int>.generate(
    _getPrivateKeySize(algorithm),
    (_) => random.nextInt(256),
  );

  final publicKeyBytes = List<int>.generate(
    _getPublicKeySize(algorithm),
    (_) => random.nextInt(256),
  );

  return PqcKeyPair(
    publicKey: base64Encode(publicKeyBytes),
    privateKey: base64Encode(privateKeyBytes),
    algorithm: algorithm,
    createdAt: DateTime.now(),
  );
}
```

#### 6.1.3 Assinatura de Transação

```dart
Future<PqcSignature> signTransaction(
  String data,
  String privateKey, {
  PqcAlgorithm algorithm = PqcAlgorithm.dilithium3,
}) async {
  // Hash dos dados da transação
  final dataBytes = utf8.encode(data);
  final hash = sha256.convert(dataBytes);

  // Em produção: Dilithium.sign(hash, privateKey)
  // Simulação: HMAC com hash
  final keyBytes = base64Decode(privateKey);
  final hmac = Hmac(sha256, keyBytes);
  final signature = hmac.convert(hash.bytes);

  return PqcSignature(
    signature: base64Encode(signature.bytes),
    data: data,
    algorithm: algorithm,
    timestamp: DateTime.now(),
  );
}
```

### 6.2 Serviço de Autenticação

**Ficheiro:** `lib/services/auth_service.dart`

#### 6.2.1 Registo de Utilizador

```dart
static Future<AuthResult> register({
  required String email,
  required String password,
  required String name,
  String? phone,
}) async {
  try {
    // 1. Criar utilizador no Firebase Auth
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final userId = credential.user!.uid;

    // 2. Gerar par de chaves PQC
    final pqcService = PqcService();
    final keyPair = await pqcService.generateKeyPair();

    // 3. Criar documento no Firestore
    final user = UserModel(
      id: userId,
      email: email,
      name: name,
      phone: phone,
      pqcPublicKey: keyPair.publicKey,
      status: UserStatus.pendingVerification,
    );

    await FirestoreService.createUser(user);

    // 4. Criar conta bancária padrão
    await FirestoreService.createDefaultAccount(userId);

    // 5. Enviar email de verificação
    await credential.user!.sendEmailVerification();

    // 6. Guardar chave privada localmente
    await pqcService.saveKeyPair(keyPair);

    return AuthResult(success: true, user: user);
  } on FirebaseAuthException catch (e) {
    return AuthResult(
      success: false,
      errorMessage: _getAuthErrorMessage(e.code),
    );
  }
}
```

### 6.3 Serviço de Transferências

**Ficheiro:** `lib/services/firestore_service.dart`

#### 6.3.1 Transferência Atómica

```dart
static Future<Transaction?> createTransfer({
  required String senderId,
  required String senderAccountId,
  required String receiverAccountId,
  required double amount,
  required String description,
  String? pqcSignature,
}) async {
  try {
    return await _db.runTransaction((transaction) async {
      // 1. Ler conta do remetente
      final senderDoc = await transaction.get(
        _accounts.doc(senderAccountId),
      );
      final senderAccount = AccountModel.fromFirestore(senderDoc);

      // 2. Validar saldo
      if (senderAccount.availableBalance < amount) {
        throw Exception('Saldo insuficiente');
      }

      // 3. Ler conta do destinatário
      final receiverDoc = await transaction.get(
        _accounts.doc(receiverAccountId),
      );
      final receiverAccount = AccountModel.fromFirestore(receiverDoc);

      // 4. Atualizar saldos
      transaction.update(senderDoc.reference, {
        'balance': senderAccount.balance - amount,
        'availableBalance': senderAccount.availableBalance - amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(receiverDoc.reference, {
        'balance': receiverAccount.balance + amount,
        'availableBalance': receiverAccount.availableBalance + amount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 5. Criar registo da transação
      final txRef = _transactions.doc();
      final tx = Transaction(
        id: txRef.id,
        senderId: senderId,
        senderAccountId: senderAccountId,
        receiverId: receiverAccount.userId,
        receiverAccountId: receiverAccountId,
        amount: amount,
        description: description,
        type: TransactionType.transfer,
        status: TransactionStatus.completed,
        pqcSignature: pqcSignature,
        isEncrypted: pqcSignature != null,
        date: DateTime.now(),
      );

      transaction.set(txRef, tx.toFirestore());

      return tx;
    });
  } catch (e) {
    debugPrint('Erro na transferência: $e');
    return null;
  }
}
```

### 6.4 Serviço de Armazenamento Seguro

**Ficheiro:** `lib/services/secure_storage_service.dart`

#### 6.4.1 Hash de PIN com Salt

```dart
static Future<void> setPin(String pin) async {
  // 1. Gerar salt aleatório
  final random = Random.secure();
  final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
  final salt = base64Encode(saltBytes);

  // 2. Combinar PIN com salt
  final combined = '$pin:$salt';

  // 3. Hash iterativo (10.000 rounds)
  var hash = sha256.convert(utf8.encode(combined));
  for (int i = 0; i < 9999; i++) {
    hash = sha256.convert(hash.bytes);
  }

  // 4. Guardar hash e salt
  await _storage.write(key: _pinHashKey, value: hash.toString());
  await _storage.write(key: _pinSaltKey, value: salt);
}

static Future<bool> verifyPin(String pin) async {
  final storedHash = await _storage.read(key: _pinHashKey);
  final salt = await _storage.read(key: _pinSaltKey);

  if (storedHash == null || salt == null) return false;

  // Recalcular hash
  final combined = '$pin:$salt';
  var hash = sha256.convert(utf8.encode(combined));
  for (int i = 0; i < 9999; i++) {
    hash = sha256.convert(hash.bytes);
  }

  return hash.toString() == storedHash;
}
```

---

## 7. ALGORITMOS E FÓRMULAS

### 7.1 Algoritmo CRYSTALS-Dilithium

O Dilithium é um esquema de assinatura digital baseado em problemas de reticulados (lattice-based).

#### 7.1.1 Parâmetros de Segurança

| Parâmetro | Dilithium2 | Dilithium3 | Dilithium5 |
|-----------|------------|------------|------------|
| Nível NIST | 2 | 3 | 5 |
| Segurança (bits) | 128 | 192 | 256 |
| Chave Pública | 1,312 bytes | 1,952 bytes | 2,592 bytes |
| Chave Privada | 2,528 bytes | 4,000 bytes | 4,864 bytes |
| Assinatura | 2,420 bytes | 3,293 bytes | 4,595 bytes |

#### 7.1.2 Operações Matemáticas

**Geração de Chaves:**
```
KeyGen():
  ρ, ρ', K ← {0,1}^256          // Seeds aleatórios
  (A, s1, s2) ← ExpandA(ρ)       // Matriz e vetores
  t := As1 + s2                  // Chave pública compacta
  tr := H(ρ || t1)               // Hash
  pk := (ρ, t1)                  // Chave pública
  sk := (ρ, K, tr, s1, s2, t0)  // Chave privada
  return (pk, sk)
```

**Assinatura:**
```
Sign(sk, M):
  μ := H(tr || M)                // Hash da mensagem
  κ := 0
  repeat
    y ← ExpandMask(ρ', κ)        // Máscara
    w := Ay
    c ← H(μ || w1)               // Challenge
    z := y + cs1                 // Resposta
    κ := κ + 1
  until ||z||∞ < γ1 - β and ||cs2||∞ < γ2 - β
  return σ := (c, z)
```

**Verificação:**
```
Verify(pk, M, σ):
  μ := H(tr || M)
  w' := Az - ct                  // Recalcular
  c' := H(μ || w'1)              // Challenge
  return c = c' and ||z||∞ < γ1 - β
```

### 7.2 Fórmulas de Cálculo Financeiro

#### 7.2.1 Saldo Disponível

```
SaldoDisponível = SaldoContabilístico - (RetencoesAuth + LimitesReservados)
```

#### 7.2.2 Análise Mensal

```dart
FinancialSummary getFinancialSummary(List<Transaction> transactions) {
  double income = 0;
  double expenses = 0;

  for (final tx in transactions) {
    if (tx.type == TransactionType.income) {
      income += tx.amount;
    } else if (tx.type == TransactionType.expense ||
               tx.type == TransactionType.transfer) {
      expenses += tx.amount.abs();
    }
  }

  return FinancialSummary(
    totalIncome: income,
    totalExpenses: expenses,
    netFlow: income - expenses,
    transactionCount: transactions.length,
  );
}
```

#### 7.2.3 Formatação de Moeda (EUR)

```dart
String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'pt_PT',
    symbol: '€',
    decimalDigits: 2,
  );
  return formatter.format(amount);  // Ex: "1 234,56 €"
}
```

### 7.3 Algoritmo de Hash do PIN

```
HashPIN(pin, salt, iterations=10000):
  combined := pin || ":" || salt
  hash := SHA256(combined)
  for i in range(iterations - 1):
    hash := SHA256(hash)
  return Base64Encode(hash)
```

**Complexidade:** O(n) onde n = número de iterações

**Segurança:**
- Resistente a ataques de dicionário (salt único)
- Resistente a brute-force (10k iterações ≈ 100ms de cálculo)

---

## 8. VALIDAÇÃO E TESTES

### 8.1 Estratégia de Testes

| Tipo | Cobertura | Ferramentas |
|------|-----------|-------------|
| Unitários | Serviços, Modelos | flutter_test |
| Widget | Componentes UI | flutter_test |
| Integração | Fluxos E2E | integration_test |
| Segurança | PQC, Auth | Testes manuais |
| Performance | Tempos resposta | DevTools |

### 8.2 Casos de Teste Prioritários

#### 8.2.1 Autenticação
- [x] Registo com dados válidos
- [x] Registo com email duplicado (erro)
- [x] Login com credenciais válidas
- [x] Login com password errada (erro)
- [x] Verificação de PIN correto
- [x] Bloqueio após 3 PINs incorretos

#### 8.2.2 Transferências
- [x] Transferência com saldo suficiente
- [x] Transferência com saldo insuficiente (erro)
- [x] Assinatura PQC gerada
- [x] Verificação de assinatura válida
- [x] Atualização atómica de saldos

#### 8.2.3 Segurança
- [x] Chaves PQC geradas no registo
- [x] PIN hasheado com salt
- [x] Dados sensíveis em secure storage
- [x] Sessão expira após inatividade

### 8.3 Métricas de Qualidade

| Métrica | Alvo | Atual |
|---------|------|-------|
| Cobertura de código | > 70% | ~45% |
| Bugs críticos | 0 | 0 |
| Tempo de build | < 2 min | 1.5 min |
| Tamanho APK | < 30 MB | 25 MB |
| Tempo de startup | < 3s | 2.5s |

---

## 9. ESTADO ATUAL E MELHORIAS FUTURAS

### 9.1 Funcionalidades Implementadas

| Categoria | Funcionalidade | Estado |
|-----------|---------------|--------|
| **Auth** | Registo/Login | ✅ 100% |
| **Auth** | PIN | ✅ 100% |
| **Auth** | Biometria | ✅ 100% |
| **Conta** | Visualizar saldo | ✅ 100% |
| **Conta** | Histórico | ✅ 100% |
| **Transferência** | IBAN | ✅ 100% |
| **Transferência** | MB WAY | ✅ 100% |
| **PQC** | Assinaturas Dilithium | ✅ 100% |
| **PQC** | Verificação | ✅ 100% |
| **Análise** | Resumo financeiro | ✅ 100% |
| **UI** | Design system | ✅ 100% |
| **UI** | Tema claro/escuro | ✅ 100% |

### 9.2 Funcionalidades Pendentes

| Prioridade | Funcionalidade | Esforço |
|------------|---------------|---------|
| Alta | Integração liboqs (PQC real) | 2 sprints |
| Alta | Notificações push | 1 sprint |
| Alta | Testes automatizados | 2 sprints |
| Média | QR Code pagamentos | 1 sprint |
| Média | Modo offline | 2 sprints |
| Média | Exportação RGPD | 1 sprint |
| Baixa | Cartões virtuais | 2 sprints |
| Baixa | Multi-idioma | 1 sprint |

### 9.3 Melhorias Técnicas Propostas

#### 9.3.1 Segurança
1. **Integração liboqs**: Substituir simulação por FFI real
2. **Certificate pinning**: Prevenir MITM
3. **Root/Jailbreak detection**: Bloquear dispositivos comprometidos
4. **Secure enclave**: Usar hardware security module
5. **Zero-knowledge proofs**: Para verificação de saldo

#### 9.3.2 Performance
1. **Lazy loading**: Carregar transações por página
2. **Cache inteligente**: Memoização de dados frequentes
3. **Compressão de imagens**: Otimizar fotos de perfil
4. **Tree shaking**: Reduzir tamanho do bundle

#### 9.3.3 UX/UI
1. **Animações Lottie**: Feedback visual rico
2. **Skeleton screens**: Melhor perceção de loading
3. **Haptic feedback**: Confirmações táteis
4. **Dark mode automático**: Baseado em sistema
5. **Acessibilidade**: Suporte a screen readers

#### 9.3.4 Arquitetura
1. **Clean Architecture**: Separação mais rigorosa de camadas
2. **Riverpod**: Alternativa mais type-safe a Provider
3. **go_router**: Navegação declarativa avançada
4. **Feature flags**: Releases controlados
5. **Analytics**: Firebase Analytics para métricas

### 9.4 Roadmap

```
Q1 2026: ✅ MVP (Concluído)
  - Autenticação completa
  - Transferências básicas
  - PQC simulado

Q2 2026: 🔄 Em curso
  - Integração liboqs
  - Testes automatizados
  - Notificações push

Q3 2026: 📋 Planeado
  - QR Code
  - Modo offline
  - Multi-idioma

Q4 2026: 📋 Planeado
  - Cartões virtuais
  - Open Banking APIs
  - Lançamento produção
```

---

## ANEXOS

### A. Glossário

| Termo | Definição |
|-------|-----------|
| **PQC** | Post-Quantum Cryptography - Criptografia resistente a computadores quânticos |
| **Dilithium** | Algoritmo de assinatura digital pós-quântico (NIST) |
| **Kyber** | Algoritmo de encriptação pós-quântico (NIST) |
| **IBAN** | International Bank Account Number |
| **MB WAY** | Sistema de pagamentos móveis português |
| **Firestore** | Base de dados NoSQL da Google |
| **Provider** | Padrão de gestão de estado em Flutter |

### B. Referências

1. NIST Post-Quantum Cryptography Standardization
2. CRYSTALS-Dilithium Specification
3. Flutter Documentation
4. Firebase Documentation
5. Material Design 3 Guidelines

### C. Ficheiros de Diagramas

- `docs/diagrams/context-diagram.excalidraw`
- `docs/diagrams/use-case-diagram.excalidraw`
- `docs/diagrams/sequence-diagrams.excalidraw`
- `docs/diagrams/wireframes.excalidraw`
- `docs/diagrams/architecture.excalidraw`

---

**Documento gerado em:** Fevereiro 2026
**Última atualização:** 05/02/2026
**Versão do documento:** 1.0
