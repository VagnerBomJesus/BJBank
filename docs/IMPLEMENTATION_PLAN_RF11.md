# RF11: Card Management Backend - Plano de Implementação

**Prioridade:** 🔴 CRÍTICA
**Estimativa:** 3-4 dias
**Status:** Iniciando

---

## 📋 O Que Precisa Ser Feito

### 1. Card Model (150 linhas)
**Arquivo:** `lib/models/card_model.dart`

```dart
Estrutura:
├── Enums
│   ├── CardType { physical, virtual }
│   └── CardStatus { active, blocked, expired, cancelled }
├── CardModel class
│   ├── id
│   ├── userId
│   ├── cardNumber (encrypted)
│   ├── cardHolder
│   ├── expiryDate
│   ├── cvv (encrypted)
│   ├── cardLimit
│   ├── spentAmount
│   ├── availableBalance
│   ├── type (physical/virtual)
│   ├── status
│   ├── createdAt
│   ├── updatedAt
│   └── Methods:
│       ├── formatCardNumber() → "****1234"
│       ├── isExpired()
│       ├── availableBalance()
│       ├── maskSensitiveData()
│       ├── toJson()
│       └── fromJson()
```

---

### 2. Card Service (250 linhas)
**Arquivo:** `lib/services/card_service.dart`

```dart
Métodos:
├── createCard(CardModel) → Future<CardModel>
├── getCard(cardId) → Future<CardModel?>
├── getCards() → Future<List<CardModel>>
├── updateCard(cardId, updates) → Future<void>
├── blockCard(cardId) → Future<void>
├── unblockCard(cardId) → Future<void>
├── updateCardLimit(cardId, newLimit) → Future<void>
├── deleteCard(cardId) → Future<void>
├── getCardStatistics() → Future<CardStats>
├── streamCards() → Stream<List<CardModel>>
└── Firestore integration
```

---

### 3. Card Provider (100 linhas)
**Arquivo:** `lib/providers/card_provider.dart` (EXTEND)

```dart
Adicionar:
├── _cardService = CardService()
├── List<CardModel> _cards = []
├── Loading/Error states
├── Real-time listeners
├── Methods:
│   ├── fetchCards()
│   ├── createCard()
│   ├── blockCard()
│   ├── updateCardLimit()
│   └── getAvailableBalance()
```

---

### 4. Firestore Collections (Security Rules)

```json
/users/{userId}/cards/{cardId}
{
  "id": "card_001",
  "userId": "user_123",
  "cardNumber": "encrypted_number",
  "cardHolder": "João Silva",
  "expiryDate": "12/2028",
  "cvv": "encrypted_cvv",
  "limit": 5000,
  "spent": 1234,
  "type": "physical",
  "status": "active",
  "createdAt": "2026-04-17T10:00:00Z",
  "updatedAt": "2026-04-17T10:00:00Z"
}
```

---

## 🎯 Passos de Implementação

### Dia 1: Models + Service Base
- [ ] Criar CardModel enum + class (150 linhas)
- [ ] Criar CardService skeleton (50 linhas)
- [ ] Unit tests para CardModel

### Dia 2: Card Service Completo
- [ ] Implementar todos os métodos do CardService (250 linhas)
- [ ] Firestore integration
- [ ] Error handling

### Dia 3: Provider + Integration
- [ ] Extend CardProvider
- [ ] Stream listeners
- [ ] Real-time updates

### Dia 4: Testing + Polish
- [ ] Unit tests para CardService
- [ ] Integration tests
- [ ] Error handling

---

## ✅ Próximo Passo

Começamos? Vou:
1. Criar `lib/models/card_model.dart`
2. Criar `lib/services/card_service.dart`
3. Extend `lib/providers/card_provider.dart`

Pronto? 🚀
