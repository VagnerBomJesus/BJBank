# BJBank - Badges Quick Reference Guide

A quick lookup guide for all available badge widgets and their usage.

---

## 📌 Badge Index

| Badge | Purpose | File | Variants | Status |
|-------|---------|------|----------|--------|
| **NotificationBadge** | Notifications with counter | `badges/notification_badge.dart` | 2 | ✅ Phase 1 |
| **CounterBadge** | Generic counters | `badges/counter_badge.dart` | 3 | ✅ Phase 1 |
| **StatusBadge** | Transaction/Bill status | `badges/status_badge.dart` | 4 | ✅ Phase 1 |
| **QuantumSafeBadge** | PQC protection indicator | `pqc/quantum_safe_badge.dart` | 3 | ✅ Phase 2 |
| **EncryptedBadge** | Encryption indicator | `pqc/quantum_safe_badge.dart` | 1 | ✅ Phase 2 |
| **VerifiedBadge** | Verification indicator | `pqc/quantum_safe_badge.dart` | 1 | ✅ Phase 2 |
| **SecurityBadge** | Security/Protection icon | `home/security_badge.dart` | 2 | ✅ Phase 2 |
| **EncryptedTransactionBadge** | Transaction encryption | `home/security_badge.dart` | 1 | ✅ Phase 2 |
| **CategoryBadge** | Transaction category | `badges/category_badge.dart` | 3 | ✅ Phase 3 |
| **PriorityBadge** | Task/Goal priority | `badges/priority_badge.dart` | 5 | ✅ Phase 3 |

---

## 🎯 Badge Usage by Screen

### Home Screen
```dart
// Display security indicator
SecurityBadge(size: 16)

// Show transaction encryption
EncryptedTransactionBadge()

// PQC signature badge
QuantumSafeBadge(compact: true)
```

### Bills Screen
```dart
// Show bill status
StatusBadge(status: StatusType.completed)

// Show category
CategoryBadge(category: TransactionCategory.utilities, compact: true)

// Show if overdue
StatusBadge(status: StatusType.overdue)

// Show amount if paid/pending
CounterBadge(count: 3, color: Colors.orange)
```

### Notifications
```dart
// Show notification count
NotificationBadge(
  count: 5,
  type: NotificationType.alert,
  showPulse: true,
)

// Simple counter
SimpleNotificationBadge(count: 3)
```

### Transaction History
```dart
// Status
StatusBadge(
  status: StatusType.completed,
  compact: true,
)

// Category indicator
CategoryBadgeIndicator(category: TransactionCategory.transport)

// Encryption badge
EncryptedBadge(compact: true)
```

### Savings Goals
```dart
// Priority level
PriorityBadge(level: PriorityLevel.high)

// Progress visualization
PriorityIndicator(level: PriorityLevel.critical)

// Alert with pulse
PriorityAlertBadge(level: PriorityLevel.critical)
```

---

## 📚 Detailed Badge Documentation

### 1. NotificationBadge

**Purpose:** Display notification count with type indicator

**Variants:**
- `NotificationBadge` - Full badge with icon and counter
- `SimpleNotificationBadge` - Counter only

**Types:** Alert, Warning, Info, Success

```dart
// Alert with pulse animation
NotificationBadge(
  count: 5,
  type: NotificationType.alert,
  showPulse: true,
)

// Warning notification
NotificationBadge(
  count: 2,
  type: NotificationType.warning,
  size: 24,
)

// Simple counter (max 99)
SimpleNotificationBadge(
  count: 12,
  backgroundColor: BJBankColors.error,
  size: 20,
)
```

---

### 2. CounterBadge

**Purpose:** Display numeric counters for bills, alerts, etc.

**Variants:**
- `CounterBadge` - Counter with animation
- `CounterBadgeWithLabel` - Counter + label below
- `InlineCounterBadge` - Counter + label inline

```dart
// Overdue bills counter
CounterBadge(
  count: 3,
  size: BadgeSize.large,
  shape: BadgeShape.circle,
  maxCount: 99,
)

// With label
CounterBadgeWithLabel(
  count: 5,
  label: 'Vencidas',
  color: BJBankColors.error,
)

// Inline version
InlineCounterBadge(
  count: 3,
  label: 'Alertas',
  color: BJBankColors.warning,
)
```

**Sizes:** Small (16px), Medium (20px), Large (28px)

**Shapes:** Circle, RoundedRectangle, Rectangle

---

### 3. StatusBadge

**Purpose:** Display transaction, bill, or loan status

**Variants:**
- `StatusBadge` - Full or compact
- `HorizontalStatusBadge` - Horizontal layout
- `StatusPillBadge` - Pill/capsule shape
- `StatusLineIndicator` - Minimal line

**Statuses:**
```
├─ Pending    (Orange - schedule icon)
├─ Approved   (Green - checkmark)
├─ Completed  (Blue - verified)
├─ Failed     (Red - cancel)
├─ Cancelled  (Grey - block)
└─ Overdue    (Dark Red - warning)
```

```dart
// Full status badge
StatusBadge(status: StatusType.completed)

// Compact (icon only)
StatusBadge(
  status: StatusType.pending,
  compact: true,
)

// Horizontal layout
HorizontalStatusBadge(
  status: StatusType.completed,
  label: 'Transferência',
)

// Pill shape
StatusPillBadge(status: StatusType.approved)

// Line indicator
StatusLineIndicator(status: StatusType.overdue)
```

---

### 4. QuantumSafeBadge

**Purpose:** Indicate PQC (Post-Quantum Cryptography) protection

**Variants:**
- `QuantumSafeBadge` - Full or compact
- Extended variant for onboarding

```dart
// Full badge
QuantumSafeBadge()

// Compact for app bars
QuantumSafeBadge(compact: true)

// Extended for onboarding
QuantumSafeBadge(extended: true)

// With pulse animation
QuantumSafeBadge(
  compact: true,
  showPulse: true,
)
```

**Features:**
- Tooltip: "Protegido por criptografia pós-quântica"
- Pulse animation available
- NIST FIPS 203/204 certification in tooltip

---

### 5. EncryptedBadge

**Purpose:** Show data is encrypted

```dart
// Icon only
EncryptedBadge(compact: true)

// With label
EncryptedBadge(showLabel: true)

// Full size
EncryptedBadge(compact: false)
```

---

### 6. VerifiedBadge

**Purpose:** Show account/transaction is verified

```dart
// Compact
VerifiedBadge(compact: true)

// With label
VerifiedBadge(showLabel: true)
```

---

### 7. SecurityBadge

**Purpose:** Display security status on home screen

**Icon Types:**
- `SecurityIconType.shield` - Protection (default)
- `SecurityIconType.lock` - Encryption
- `SecurityIconType.verified` - Verification

```dart
// Default shield
SecurityBadge()

// Encryption lock
SecurityBadge(iconType: SecurityIconType.lock)

// Verification
SecurityBadge(
  size: 20,
  iconType: SecurityIconType.verified,
)
```

**Features:**
- Fade + scale entry animation
- Configurable size
- Three icon variants

---

### 8. EncryptedTransactionBadge

**Purpose:** Show transaction is encrypted

```dart
// Simple lock icon
EncryptedTransactionBadge()
```

**Features:**
- Scale entry animation
- Tooltip with explanation
- Dark theme aware

---

### 9. CategoryBadge

**Purpose:** Display transaction category

**Categories (10 total):**
- Utilities, Insurance, Subscription, Rent, Education
- Healthcare, Transport, Entertainment, Telecom, Other

**Variants:**
- `CategoryBadge` - Icon + label
- `CategoryBadgeIndicator` - Dot + label
- `CategoryChipBadge` - Selectable chip

```dart
// Full badge
CategoryBadge(category: TransactionCategory.utilities)

// Compact (icon only)
CategoryBadge(
  category: TransactionCategory.utilities,
  compact: true,
)

// Indicator dot
CategoryBadgeIndicator(category: TransactionCategory.education)

// Selectable chip
CategoryChipBadge(
  category: TransactionCategory.entertainment,
  selected: true,
  onTap: () => print('Selected'),
)
```

**Features:**
- 10 semantic colors
- Portuguese labels
- Dark theme support
- Category-specific icons

---

### 10. PriorityBadge

**Purpose:** Display priority level

**Priority Levels (4 total):**
- `PriorityLevel.low` - Green
- `PriorityLevel.medium` - Orange
- `PriorityLevel.high` - Red
- `PriorityLevel.critical` - Dark Red

**Variants:**
- `PriorityBadge` - Icon + label
- `PriorityIndicator` - Star-based (1-4 stars)
- `PriorityPillBadge` - Pill shape
- `PriorityAlertBadge` - Alert with pulse

```dart
// Standard badge
PriorityBadge(level: PriorityLevel.high)

// Compact
PriorityBadge(
  level: PriorityLevel.critical,
  compact: true,
)

// Star indicator
PriorityIndicator(level: PriorityLevel.critical)

// Pill badge
PriorityPillBadge(
  level: PriorityLevel.high,
  label: 'Importante',
)

// Alert with pulse
PriorityAlertBadge(level: PriorityLevel.critical)
```

**Features:**
- 4 priority levels with escalating colors
- Arrow and icon indicators
- Pulse animation for high/critical
- Portuguese labels

---

## 🎨 Colors Reference

### Semantic Colors (Theme)
```dart
BJBankColors.success      // Green - #4CAF50
BJBankColors.warning      // Orange - #FF9800
BJBankColors.error        // Red - #BA1A1A
BJBankColors.info         // Blue - #2196F3
```

### PQC Colors (Theme)
```dart
BJBankColors.quantum      // Cyan - #00BCD4 (Quantum Safe)
BJBankColors.encrypted    // Green - #8BC34A (Encrypted)
BJBankColors.verified     // Teal - #009688 (Verified)
```

### Category Colors (Material)
```dart
Colors.orange             // Utilities
Colors.blue               // Insurance
Colors.purple             // Subscription
Colors.brown              // Rent
Colors.green              // Education
Colors.pink               // Healthcare
Colors.red                // Transport
Colors.amber              // Entertainment
Colors.cyan               // Telecom
Colors.grey               // Other
```

---

## 🎯 Design Patterns

### Animation Patterns Used

**Pulse Animation:**
```dart
Tween<double>(begin: 1.0, end: 1.05).animate(
  CurvedAnimation(parent: controller, curve: Curves.easeInOut),
)
// Duration: 2 seconds, repeating
```

**Bounce Animation:**
```dart
Tween<double>(begin: 0.8, end: 1.1).animate(
  CurvedAnimation(parent: controller, curve: Curves.elasticOut),
)
// Duration: 500ms, on value change
```

**Scale Animation:**
```dart
Tween<double>(begin: 0.8, end: 1.0).animate(
  CurvedAnimation(parent: controller, curve: Curves.easeOut),
)
// Duration: 400ms or 600ms, on entry
```

### Dark Theme Pattern

All badges use:
```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
color.withValues(alpha: isDark ? 0.2 : 0.15)
```

---

## ⚡ Performance Tips

1. **Use `compact: true`** for list items to reduce rendering
2. **Disable animations** when not needed (default is off)
3. **Use `showLabel: false`** for space-constrained areas
4. **Memoize color calculations** if using in loops

---

## 🔍 Accessibility

All badges include:
- ✅ Semantic labels for screen readers
- ✅ Tooltips with descriptions
- ✅ High contrast colors
- ✅ Dark theme support
- ✅ Proper icon labeling

---

## 📋 Complete Widget Tree

```
lib/widgets/
├── badges/
│   ├── notification_badge.dart
│   │   ├── NotificationBadge (with pulse)
│   │   └── SimpleNotificationBadge
│   ├── counter_badge.dart
│   │   ├── CounterBadge (with bounce)
│   │   ├── CounterBadgeWithLabel
│   │   └── InlineCounterBadge
│   ├── status_badge.dart
│   │   ├── StatusBadge
│   │   ├── HorizontalStatusBadge
│   │   ├── StatusPillBadge
│   │   └── StatusLineIndicator
│   ├── category_badge.dart
│   │   ├── CategoryBadge
│   │   ├── CategoryBadgeIndicator
│   │   └── CategoryChipBadge
│   └── priority_badge.dart
│       ├── PriorityBadge
│       ├── PriorityIndicator
│       ├── PriorityPillBadge
│       └── PriorityAlertBadge (with pulse)
├── pqc/
│   └── quantum_safe_badge.dart
│       ├── QuantumSafeBadge (with pulse)
│       ├── EncryptedBadge
│       └── VerifiedBadge
└── ...home/widgets/
    └── security_badge.dart
        ├── SecurityBadge (with animation)
        └── EncryptedTransactionBadge (with animation)
```

---

**Last Updated:** 17/04/2026
**Status:** ✅ Complete - All badges production-ready
**Next Phase:** Integration into screens and Phase 4 implementation

