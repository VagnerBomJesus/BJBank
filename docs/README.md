# BJBank - Documentação Técnica

## Aplicação Móvel Bancária com Criptografia Pós-Quântica

---

## Índice de Documentos

### 1. Documentação Principal

| Documento | Descrição |
|-----------|-----------|
| [TECHNICAL_DOCUMENTATION.md](TECHNICAL_DOCUMENTATION.md) | Documentação técnica completa com requisitos, modelação, arquitetura |
| [PQC-IMPLEMENTATION.md](PQC-IMPLEMENTATION.md) | Implementação detalhada da Criptografia Pós-Quântica |
| [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) | Estado atual de implementação e roadmap |

### 2. Diagramas (Excalidraw)

| Diagrama | Ficheiro | Descrição |
|----------|----------|-----------|
| Contexto | [diagrams/context-diagram.excalidraw](diagrams/context-diagram.excalidraw) | Visão geral do sistema e entidades externas |
| Casos de Uso | [diagrams/use-case-diagram.excalidraw](diagrams/use-case-diagram.excalidraw) | Atores e funcionalidades |
| Sequência | [diagrams/sequence-diagrams.excalidraw](diagrams/sequence-diagrams.excalidraw) | Fluxos de transferência e autenticação |
| Wireframes | [diagrams/wireframes.excalidraw](diagrams/wireframes.excalidraw) | Protótipos de interface |
| Arquitetura | [diagrams/architecture.excalidraw](diagrams/architecture.excalidraw) | Arquitetura técnica em camadas |

### 3. Design System

| Documento | Descrição |
|-----------|-----------|
| [design-system/](design-system/) | Especificações de cores, tipografia, componentes |

---

## Resumo Executivo

### Sobre o Projeto

O **BJBank** é uma aplicação móvel bancária desenvolvida em Flutter que implementa **Criptografia Pós-Quântica (PQC)** utilizando os algoritmos CRYSTALS-Dilithium e CRYSTALS-Kyber padronizados pelo NIST (FIPS 203, 204).

### Stack Tecnológico

- **Framework:** Flutter (Dart SDK ^3.8.1)
- **Backend:** Firebase (Auth + Firestore)
- **Criptografia:** CRYSTALS-Dilithium (Nível 3, 192 bits)
- **Plataformas:** Android, iOS, Windows

### Funcionalidades Principais

| Categoria | Funcionalidades |
|-----------|-----------------|
| **Autenticação** | Email/password, PIN 6 dígitos, Biometria |
| **Operações** | Transferência IBAN, MB WAY, Histórico |
| **Segurança PQC** | Assinatura de transações, Verificação |
| **Análise** | Resumo financeiro, Gráficos mensais |

### Estado de Implementação

```
Implementado:     ████████████████████░░░░  75%
Em progresso:     ████░░░░░░░░░░░░░░░░░░░░  15%
Pendente:         ██░░░░░░░░░░░░░░░░░░░░░░  10%
```

---

## Estrutura do Projeto

```
bjbank/
├── lib/                          # Código fonte Dart
│   ├── models/                   # 5 modelos de dados
│   ├── providers/                # 3 providers (estado)
│   ├── services/                 # 7 serviços
│   ├── screens/                  # 34 ecrãs UI
│   ├── theme/                    # 8 ficheiros design system
│   └── widgets/                  # 2 widgets reutilizáveis
├── docs/                         # Documentação
│   ├── diagrams/                 # Diagramas Excalidraw
│   └── design-system/            # Especificações de design
├── test/                         # Testes
└── assets/                       # Recursos estáticos
```

---

## Algoritmos PQC Implementados

### CRYSTALS-Dilithium (Assinaturas)

| Parâmetro | Dilithium3 (Padrão) |
|-----------|---------------------|
| Nível NIST | 3 |
| Segurança | 192 bits |
| Chave Pública | 1,952 bytes |
| Chave Privada | 4,000 bytes |
| Assinatura | 3,293 bytes |

### CRYSTALS-Kyber (Encriptação) - Futuro

| Parâmetro | Kyber768 (Planeado) |
|-----------|---------------------|
| Nível NIST | 3 |
| Segurança | 192 bits |
| Chave Pública | 1,184 bytes |
| Texto Cifrado | 1,088 bytes |

---

## Fluxo de Segurança

```
1. Autenticação Firebase (email/password)
         ↓
2. Verificação PIN (SHA-256, 10K iterações)
         ↓
3. Autenticação Biométrica (opcional)
         ↓
4. Assinatura de Transações (Dilithium)
         ↓
5. Armazenamento Seguro (Keychain/Keystore)
```

---

## Como Usar os Diagramas

Os diagramas estão no formato **Excalidraw** (JSON). Para visualizar:

1. Aceder a [excalidraw.com](https://excalidraw.com)
2. Clicar em "Open" → "Open from file"
3. Selecionar o ficheiro `.excalidraw`

Alternativamente, usar a extensão "Excalidraw" no VS Code.

---

## Contactos

**Projeto:** BJBank - Mobile Banking com PQC
**Versão:** 1.0.0
**Data:** Fevereiro 2026

---

*Documentação gerada automaticamente para o projeto de dissertação de mestrado.*
