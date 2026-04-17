# BJBank - Plano de Implementação de Badges

## 📊 Análise Atual

### Badges Existentes (3)

✅ **Implementados e Funcionais:**
1. `QuantumSafeBadge` (lib/widgets/pqc/quantum_safe_badge.dart)
   - Versões: Full + Compact
   - Cores: Quantum (Cyan #00BCD4)
   - Ícone: Shield
   - Status: ✅ Completo e testado

2. `EncryptedBadge` (lib/widgets/pqc/quantum_safe_badge.dart)
   - Cores: Encrypted (Green #8BC34A)
   - Ícone: Lock
   - Status: ✅ Completo

3. `VerifiedBadge` (lib/widgets/pqc/quantum_safe_badge.dart)
   - Cores: Verified (Teal #009688)
   - Ícone: Verified User
   - Status: ✅ Completo

4. `SecurityBadge` (lib/screens/home/widgets/security_badge.dart)
   - Tamanho customizável
   - Formato circular
   - Status: ✅ Completo

5. `EncryptedTransactionBadge` (lib/screens/home/widgets/security_badge.dart)
   - Ícone Lock compacto
   - Status: ✅ Completo

---

## ❌ Badges Faltando / Incompletos

### 1. **NotificationBadge** (CRÍTICO)
**Status:** ❌ Não existe
**Localização recomendada:** `lib/widgets/notification_badge.dart`
**Uso:** Mostrar contador de notificações no ícone do menu

```dart
Features necessárias:
├─ Badge com número (0-9, ou "9+")
├─ Cores por tipo:
│  ├─ Vermelha para urgente
│  ├─ Laranja para aviso
│  └─ Azul para informação
├─ Animação de entrada/saída
├─ Pulse animation quando nova notificação
└─ Suporte a custom color
```

**Estimativa:** 1 dia
**Prioridade:** 🔴 CRÍTICA

---

### 2. **CounterBadge / StatusBadge** (IMPORTANTE)
**Status:** ❌ Não existe
**Localização recomendada:** `lib/widgets/counter_badge.dart`
**Uso:** Contar faturas vencidas, pagamentos pendentes, alertas

```dart
Features necessárias:
├─ Badge com número
├─ Cores customizáveis
├─ Sizes: small, medium, large
├─ Shapes: circle, rounded rectangle
├─ Labels opcionais
└─ Animação de flutter/bounce
```

**Uso em:**
- Contar faturas vencidas
- Notificações pendentes
- Alertas de orçamento
- Empréstimos com atrasos

**Estimativa:** 1 dia
**Prioridade:** 🟠 IMPORTANTE

---

### 3. **StatusBadge** (IMPORTANTE)
**Status:** ❌ Não existe
**Localização recomendada:** `lib/widgets/status_badge.dart`
**Uso:** Mostrar status de transações, faturas, metas

```dart
Features necessárias:
├─ Status com cores:
│  ├─ Pending: Laranja #FF9800
│  ├─ Approved: Verde #4CAF50
│  ├─ Completed: Azul #2196F3
│  ├─ Failed: Vermelho #BA1A1A
│  ├─ Cancelled: Cinzento #9E9E9E
│  └─ Overdue: Vermelho intenso #D32F2F
├─ Ícones apropriados
├─ Tamanhos customizáveis
├─ Texto customizável
└─ Versão compacta (ícone só)
```

**Uso em:**
- Home screen (transações)
- Bills screen
- Loans screen
- Transfer confirmations

**Estimativa:** 1 dia
**Prioridade:** 🟠 IMPORTANTE

---

### 4. **CategoryBadge** (RECOMENDADO)
**Status:** ❌ Não existe
**Localização recomendada:** `lib/widgets/category_badge.dart`
**Uso:** Mostrar categoria de faturas, transações, investimentos

```dart
Features necessárias:
├─ Cores por categoria:
│  ├─ Utilities: Laranja
│  ├─ Insurance: Azul
│  ├─ Subscription: Roxo
│  ├─ Rent: Castanho
│  ├─ Education: Verde
│  ├─ Healthcare: Rosa
│  ├─ Transport: Vermelho
│  ├─ Entertainment: Amarelo
│  ├─ Telecom: Ciano
│  └─ Other: Cinzento
├─ Ícones apropriados
├─ Labels com categoria name
└─ Compacto (ícone + cor)
```

**Uso em:**
- Bills listing
- Transactions history
- Budget breakdown
- Investment categories

**Estimativa:** 1.5 dias
**Prioridade:** 🟡 RECOMENDADO

---

### 5. **PriorityBadge** (RECOMENDADO)
**Status:** ❌ Não existe
**Localização recomendada:** `lib/widgets/priority_badge.dart`
**Uso:** Mostrar prioridade de metas, lembretes, tarefas

```dart
Features necessárias:
├─ 4 níveis:
│  ├─ Low: Verde #4CAF50
│  ├─ Medium: Laranja #FF9800
│  ├─ High: Vermelho #F44336
│  └─ Critical: Vermelho intenso #B71C1C
├─ Labels: "Baixa", "Média", "Alta", "Crítica"
├─ Ícones: arrow ou estrela
├─ Compacto (só cor + ícone)
└─ Full (com label)
```

**Uso em:**
- Savings goals
- Bills important
- Loan alerts

**Estimativa:** 1 dia
**Prioridade:** 🟡 RECOMENDADO

---

### 6. **ProgressBadge** (NICE TO HAVE)
**Status:** ❌ Não existe
**Localização recomendada:** `lib/widgets/progress_badge.dart`
**Uso:** Mostrar progresso de metas, budgets, investimentos

```dart
Features necessárias:
├─ Progress percentage
├─ Circular ou linear
├─ Cores customizáveis
├─ Label com %
├─ Animação de preenchimento
└─ Tooltip com detalhes
```

**Estimativa:** 1.5 dias
**Prioridade:** 💙 NICE TO HAVE

---

### 7. **TypeBadge** (NICE TO HAVE)
**Status:** ❌ Não existe
**Localização recomendada:** `lib/widgets/type_badge.dart`
**Uso:** Mostrar tipo de investimento, empréstimo, cartão

```dart
Features necessárias:
├─ Tipo com cores:
│  ├─ Investment types: stocks, bonds, crypto, etc
│  ├─ Loan types: personal, mortgage, auto, etc
│  ├─ Card types: credit, debit, virtual
│  └─ Savings types: emergency, vacation, etc
├─ Labels com tradução PT
├─ Ícones apropriados
└─ Compacto + full
```

**Estimativa:** 1.5 dias
**Prioridade:** 💙 NICE TO HAVE

---

## 🔧 Problemas a Corrigir nos Badges Existentes

### 1. **QuantumSafeBadge** - Melhorias
```dart
// ATUAL (Linha 36 e 39):
color: BJBankColors.quantum.withValues(alpha:0.15),
color: BJBankColors.quantum.withValues(alpha:0.3),

// PROBLEMA: Whitespace em withValues(alpha:0.15)
// CORREÇÃO: com espaço correto
color: BJBankColors.quantum.withValues(alpha: 0.15),
color: BJBankColors.quantum.withValues(alpha: 0.3),

// ADICIONAR:
├─ Animação subtle de pulse quando PQC ativo
├─ Tooltip explicando "Assinado com criptografia pós-quântica"
├─ Variante com label longo para onboarding
└─ Dark theme support melhorado
```

**Estimativa:** 1 dia
**Prioridade:** 🟠 IMPORTANTE

---

### 2. **SecurityBadge** - Melhorias
```dart
// ADICIONAR:
├─ Animação de entrada (fade + scale)
├─ Tooltip "Protegido por PQC"
├─ Variantes: shield, lock, verified
├─ Dark theme adaptation
└─ Accessibility labels
```

**Estimativa:** 1 dia
**Prioridade:** 🟠 IMPORTANTE

---

### 3. **EncryptedBadge** - Melhorias
```dart
// ADICIONAR:
├─ Tooltip "Encriptado localmente"
├─ Animação sutil
├─ Versão com label
└─ Dark theme support
```

**Estimativa:** 1 dia
**Prioridade:** 🟡 RECOMENDADO

---

## 📝 Implementação Recomendada

### **Fase 1: CRÍTICA (Semana 1)**
1. ❌ → ✅ **NotificationBadge** (1 dia)
2. 🔧 **QuantumSafeBadge** improvements (1 dia)
3. 🔧 **SecurityBadge** improvements (1 dia)

**Output:** Badges de notificação + segurança melhorados

---

### **Fase 2: IMPORTANTE (Semana 2)**
1. ❌ → ✅ **CounterBadge** (1 dia)
2. ❌ → ✅ **StatusBadge** (1 dia)
3. 🔧 **EncryptedBadge** improvements (0.5 dias)

**Output:** Badges de contagem e status funcional

---

### **Fase 3: RECOMENDADO (Semana 3)**
1. ❌ → ✅ **CategoryBadge** (1.5 dias)
2. ❌ → ✅ **PriorityBadge** (1 dia)

**Output:** Badges categorias e prioridades

---

### **Fase 4: NICE TO HAVE (Semana 4)**
1. ❌ → ✅ **ProgressBadge** (1.5 dias)
2. ❌ → ✅ **TypeBadge** (1.5 dias)

**Output:** Badges de progresso e tipo

---

## 🎨 Design System para Badges

### Cores Definidas (de colors.dart)

```dart
// Semantic Colors
- Success: #4CAF50 (Completado, Aprovado)
- Warning: #FF9800 (Pendente, Aviso)
- Error: #BA1A1A (Falha, Vencido)
- Info: #2196F3 (Informação)

// PQC Colors
- Quantum: #00BCD4 (PQC Safe)
- Encrypted: #8BC34A (Encriptado)
- Shield: #3F51B5 (Proteção)
- Verified: #009688 (Verificado)

// Category Colors (Sugeridas)
- Utilities: #FF9800
- Insurance: #2196F3
- Subscription: #9C27B0
- Rent: #795548
- Education: #4CAF50
- Healthcare: #E91E63
- Transport: #F44336
- Entertainment: #FFC107
- Telecom: #00BCD4
- Other: #9E9E9E
```

### Tamanhos Padrão

```dart
// Sizes
- xxs: 8px (ícone)
- xs: 12px (ícone)
- sm: 16px (ícone)
- md: 20px (ícone)
- lg: 24px (ícone)

// Paddings
- Compact: 4px all
- Normal: 8px all
- Large: 12px horizontal, 8px vertical
```

### Animações

```dart
// Entrada
- Fade: 300ms
- Scale: 300ms
- SlideIn: 300ms

// Contínua
- Pulse: 2s infinite (amplitude 0.1)
- Float: 3s infinite (offset 2px)

// Evento
- Bounce: 500ms (ao mudar valor)
- Flash: 1s (ao adicionar nova notificação)
```

---

## 📁 Estrutura de Ficheiros

```
lib/widgets/
├── badges/                          (NEW FOLDER)
│   ├── notification_badge.dart      (❌ → ✅ NOVO)
│   ├── counter_badge.dart           (❌ → ✅ NOVO)
│   ├── status_badge.dart            (❌ → ✅ NOVO)
│   ├── category_badge.dart          (❌ → ✅ NOVO)
│   ├── priority_badge.dart          (❌ → ✅ NOVO)
│   ├── progress_badge.dart          (❌ → ✅ NOVO)
│   ├── type_badge.dart              (❌ → ✅ NOVO)
│   └── badge_base.dart              (UTILITY CLASS)
│
├── pqc/
│   └── quantum_safe_badge.dart      (✅ EXISTENTE, melhorias)
│
└── ... (outros)

lib/screens/home/widgets/
└── security_badge.dart              (✅ EXISTENTE, melhorias)
```

---

## 🧪 Teste Recomendado

Cada badge deve ter testes para:
1. Renderização correta
2. Cores aplicadas
3. Tamanhos corretos
4. Animações (se houver)
5. Dark/Light theme

```dart
// test/widgets/badges/notification_badge_test.dart
testWidgets('NotificationBadge renders with count', (WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: NotificationBadge(count: 5),
      ),
    ),
  );

  expect(find.text('5'), findsOneWidget);
  expect(find.byType(NotificationBadge), findsOneWidget);
});
```

---

## 📊 Impacto Esperado

### Antes (Atual)
```
✅ 5 badges básicos
❌ Sem notificações
❌ Sem contador de items
❌ Sem status visual
```

### Depois (Completo)
```
✅ 12 badges especializados
✅ Notificações com badges
✅ Contadores de items
✅ Status visual claro
✅ Categorias com cores
✅ Prioridades visíveis
✅ Progresso visual
✅ Dark theme completo
```

---

## 🎯 Recomendação Final

**INICIAR POR:**

### Semana 1 (CRÍTICA)
```
1. NotificationBadge         [1 dia]
2. Melhoria QuantumSafeBadge [1 dia]
3. Melhoria SecurityBadge    [1 dia]
```

**Output:** Sistema de badges funcional com notificações

**Depois:**
- Semana 2: CounterBadge + StatusBadge
- Semana 3: CategoryBadge + PriorityBadge
- Semana 4: ProgressBadge + TypeBadge

**Total:** 4 semanas para sistema completo

---

## 📋 Checklist de Implementação

### NotificationBadge
- [ ] Criar widget com contador
- [ ] Cores por tipo (error, warning, info)
- [ ] Animação de entrada
- [ ] Pulse animation ao novo
- [ ] Tests
- [ ] Dark theme

### CounterBadge
- [ ] Widget base com número
- [ ] Suporte a "9+" quando > 9
- [ ] Sizes customizáveis
- [ ] Shapes (circle, rounded)
- [ ] Tests
- [ ] Dark theme

### StatusBadge
- [ ] Enum com 6 statuses
- [ ] Cores e ícones apropriados
- [ ] Labels em português
- [ ] Versão compacta
- [ ] Tests
- [ ] Dark theme

### E assim para cada badge...

---

**Documento:** BADGES_IMPLEMENTATION_PLAN.md
**Data:** 17/04/2026
**Versão:** 1.0
**Prioridade:** 🔴 CRÍTICA → 💙 NICE TO HAVE
