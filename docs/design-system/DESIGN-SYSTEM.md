# BJBank Design System

> Sistema de Design para aplicativo de banco digital com foco em Criptografia Pós-Quântica

**Versão:** 1.0.0
**Framework:** Flutter / Material Design 3

---

## Sumário

1. [Cores](#cores)
2. [Tipografia](#tipografia)
3. [Espaçamento](#espaçamento)
4. [Border Radius](#border-radius)
5. [Elevação](#elevação)
6. [Componentes](#componentes)
7. [Ícones](#ícones)
8. [Animações](#animações)
9. [Breakpoints](#breakpoints)
10. [Acessibilidade](#acessibilidade)
11. [Tema PQC](#tema-pqc)

---

## Cores

### Cores Primárias

| Nome | Hex | Uso |
|------|-----|-----|
| Primary | `#6750A4` | Botões principais, links, elementos de destaque |
| Primary Light | `#EADDFF` | Backgrounds de containers |
| Primary Dark | `#21005D` | Texto sobre superfícies claras |
| On Primary | `#FFFFFF` | Texto/ícones sobre primary |

### Cores Secundárias

| Nome | Hex | Uso |
|------|-----|-----|
| Secondary | `#625B71` | Elementos secundários |
| Secondary Light | `#E8DEF8` | Backgrounds alternativos |
| Secondary Dark | `#1D192B` | Texto secundário |

### Cores Terciárias

| Nome | Hex | Uso |
|------|-----|-----|
| Tertiary | `#7D5260` | Acentos e destaques |
| Tertiary Light | `#FFD8E4` | Backgrounds de destaque |
| Tertiary Dark | `#31111D` | Texto de destaque |

### Cores Semânticas

| Nome | Main | Light | Dark | Uso |
|------|------|-------|------|-----|
| Success | `#4CAF50` | `#C8E6C9` | `#2E7D32` | Operações bem-sucedidas |
| Warning | `#FF9800` | `#FFE0B2` | `#EF6C00` | Alertas e avisos |
| Error | `#BA1A1A` | `#FFDAD6` | `#93000A` | Erros e falhas |
| Info | `#2196F3` | `#BBDEFB` | `#1565C0` | Informações |

### Cores Neutras

| Nome | Hex | Uso |
|------|-----|-----|
| Surface | `#FFFBFE` | Superfícies de cards e modais |
| Surface Variant | `#E7E0EC` | Superfícies alternativas |
| On Surface | `#1C1B1F` | Texto principal |
| On Surface Variant | `#49454F` | Texto secundário |
| Outline | `#79747E` | Bordas e divisores |
| Background | `#FFFBFE` | Background principal |

### Cores de Segurança (PQC)

| Nome | Hex | Uso |
|------|-----|-----|
| Quantum | `#00BCD4` | Indicadores de segurança quântica |
| Encrypted | `#8BC34A` | Status de criptografia |
| Shield | `#3F51B5` | Elementos de proteção |
| Verified | `#009688` | Verificação concluída |

---

## Tipografia

**Font Family Principal:** Roboto
**Font Family Secundária:** Roboto Mono (código, valores)

### Escala Tipográfica

| Estilo | Tamanho | Altura de Linha | Peso | Letter Spacing |
|--------|---------|-----------------|------|----------------|
| Display Large | 57px | 64px | 400 | -0.25 |
| Display Medium | 45px | 52px | 400 | 0 |
| Display Small | 36px | 44px | 400 | 0 |
| Headline Large | 32px | 40px | 400 | 0 |
| Headline Medium | 28px | 36px | 400 | 0 |
| Headline Small | 24px | 32px | 400 | 0 |
| Title Large | 22px | 28px | 400 | 0 |
| Title Medium | 16px | 24px | 500 | 0.15 |
| Title Small | 14px | 20px | 500 | 0.1 |
| Body Large | 16px | 24px | 400 | 0.5 |
| Body Medium | 14px | 20px | 400 | 0.25 |
| Body Small | 12px | 16px | 400 | 0.4 |
| Label Large | 14px | 20px | 500 | 0.1 |
| Label Medium | 12px | 16px | 500 | 0.5 |
| Label Small | 11px | 16px | 500 | 0.5 |

### Uso Recomendado

- **Display:** Números grandes (saldo, valores)
- **Headline:** Títulos de seção
- **Title:** Títulos de cards e itens
- **Body:** Texto de conteúdo
- **Label:** Botões, chips, labels de campos

---

## Espaçamento

**Unidade Base:** 4px

| Token | Valor | Uso |
|-------|-------|-----|
| `xxs` | 4px | Espaçamento mínimo |
| `xs` | 8px | Entre elementos inline |
| `sm` | 12px | Padding interno de chips |
| `md` | 16px | Padding padrão de cards |
| `lg` | 24px | Margem entre seções |
| `xl` | 32px | Espaçamento de seções |
| `xxl` | 48px | Áreas de respiro |
| `xxxl` | 64px | Separação de blocos |

---

## Border Radius

| Token | Valor | Uso |
|-------|-------|-----|
| `none` | 0 | Elementos retangulares |
| `xs` | 4px | Inputs, campos de texto |
| `sm` | 8px | Chips, tags |
| `md` | 12px | Cards |
| `lg` | 16px | Cards maiores |
| `xl` | 28px | Dialogs, modais |
| `full` | 9999px | Botões pill, avatares |

---

## Elevação

| Nível | Valor | Uso |
|-------|-------|-----|
| Level 0 | 0dp | Elementos flat |
| Level 1 | 1dp | Cards elevados |
| Level 2 | 3dp | Botões elevados |
| Level 3 | 6dp | Modais, dropdowns |
| Level 4 | 8dp | Navigation drawer |
| Level 5 | 12dp | Dialogs |

---

## Componentes

### Botões

#### Filled Button
- Border Radius: 20px
- Min Height: 40px
- Padding Horizontal: 24px
- Background: Primary
- Text: On Primary

#### Outlined Button
- Border Radius: 20px
- Min Height: 40px
- Border Width: 1px
- Border Color: Outline
- Text: Primary

#### Text Button
- Border Radius: 20px
- Min Height: 40px
- Padding Horizontal: 12px
- Text: Primary

#### States
| Estado | Opacidade |
|--------|-----------|
| Default | 100% |
| Hovered | 92% |
| Focused | 88% |
| Pressed | 88% |
| Disabled | 38% |

### Cards

#### Elevated Card
- Border Radius: 12px
- Elevation: 1dp
- Padding: 16px
- Background: Surface

#### Filled Card
- Border Radius: 12px
- Elevation: 0dp
- Padding: 16px
- Background: Surface Variant

#### Outlined Card
- Border Radius: 12px
- Border Width: 1px
- Padding: 16px
- Border Color: Outline

### Inputs

#### Text Field
- Border Radius: 4px (top)
- Min Height: 56px
- Padding Horizontal: 16px
- Variants: Filled, Outlined

#### Search Bar
- Border Radius: 28px
- Min Height: 56px
- Background: Surface Variant

### Navigation

#### Bottom Navigation Bar
- Height: 80px
- Icon Size: 24px
- Label: Label Medium

#### App Bar
- Height: 64px
- Elevation: 0dp

### Chips

- Border Radius: 8px
- Height: 32px
- Padding Horizontal: 16px

### Dialogs

- Border Radius: 28px
- Min Width: 280px
- Max Width: 560px
- Padding: 24px

---

## Ícones

**Tamanhos:**

| Token | Tamanho |
|-------|---------|
| `xs` | 16px |
| `sm` | 20px |
| `md` | 24px |
| `lg` | 32px |
| `xl` | 48px |

### Ícones Bancários
- `account_balance` - Banco
- `account_balance_wallet` - Carteira
- `credit_card` - Cartão
- `payments` - Pagamentos
- `savings` - Poupança
- `currency_exchange` - Câmbio
- `receipt_long` - Extrato
- `attach_money` - Dinheiro

### Ícones de Segurança
- `lock` - Bloqueado
- `security` - Segurança
- `verified_user` - Verificado
- `shield` - Escudo
- `fingerprint` - Biometria
- `face` - Face ID
- `vpn_key` - Chave
- `enhanced_encryption` - Criptografia

### Ícones de Navegação
- `home` - Início
- `history` - Histórico
- `pie_chart` - Gráficos
- `settings` - Configurações
- `person` - Perfil
- `notifications` - Notificações

### Ícones de Ação
- `send` - Enviar
- `qr_code_scanner` - Scanner QR
- `add` - Adicionar
- `remove` - Remover
- `edit` - Editar
- `delete` - Excluir
- `share` - Compartilhar
- `copy` - Copiar

---

## Animações

### Durações

| Token | Duração | Uso |
|-------|---------|-----|
| `instant` | 0ms | Sem animação |
| `fast` | 100ms | Micro interações |
| `normal` | 200ms | Transições padrão |
| `slow` | 300ms | Modais, expansões |
| `slower` | 500ms | Animações complexas |

### Easing

| Nome | Curva | Uso |
|------|-------|-----|
| Standard | `cubic-bezier(0.2, 0.0, 0, 1.0)` | Padrão |
| Standard Decelerate | `cubic-bezier(0, 0, 0, 1)` | Entrada |
| Standard Accelerate | `cubic-bezier(0.3, 0, 1, 1)` | Saída |
| Emphasized | `cubic-bezier(0.2, 0.0, 0, 1.0)` | Destaque |
| Emphasized Decelerate | `cubic-bezier(0.05, 0.7, 0.1, 1.0)` | Entrada enfatizada |
| Emphasized Accelerate | `cubic-bezier(0.3, 0.0, 0.8, 0.15)` | Saída enfatizada |

---

## Breakpoints

| Nome | Largura Mínima | Uso |
|------|----------------|-----|
| Compact | 0px | Celulares |
| Medium | 600px | Tablets portrait |
| Expanded | 840px | Tablets landscape |
| Large | 1200px | Desktop |
| Extra Large | 1600px | Desktop grande |

---

## Acessibilidade

### Requisitos

| Especificação | Valor |
|---------------|-------|
| Min Touch Target | 48px |
| Focus Indicator Width | 2px |
| Contrast Ratio (Normal) | 4.5:1 |
| Contrast Ratio (Large) | 3:1 |

### Diretrizes

1. Todos os elementos interativos devem ter área de toque mínima de 48x48px
2. Textos devem manter contraste adequado com o fundo
3. Elementos focados devem ter indicador visual claro
4. Suporte a leitor de tela com labels descritivos
5. Suporte a modo escuro

---

## Tema PQC

### Indicadores de Segurança

| Indicador | Ícone | Cor | Label |
|-----------|-------|-----|-------|
| Quantum Safe | `shield` | `#00BCD4` | "Quantum Safe" |
| Encrypted | `enhanced_encryption` | `#8BC34A` | "Encrypted" |
| Verified | `verified_user` | `#009688` | "Verified" |

### Algoritmos Suportados

- **CRYSTALS-Kyber** - Key encapsulation
- **CRYSTALS-Dilithium** - Digital signatures
- **SPHINCS+** - Hash-based signatures
- **FALCON** - Lattice-based signatures

### Padrões Visuais PQC

1. Indicadores de segurança devem estar sempre visíveis em transações
2. Status de criptografia deve usar cores semânticas de segurança
3. Ícones de escudo/cadeado para elementos protegidos
4. Badge de verificação para operações concluídas

---

## Implementação Flutter

### Uso do Theme

```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF6750A4),
    brightness: Brightness.light,
  ),
)
```

### Tokens de Cor

```dart
// lib/theme/colors.dart
class BJBankColors {
  static const primary = Color(0xFF6750A4);
  static const secondary = Color(0xFF625B71);
  static const tertiary = Color(0xFF7D5260);

  // Semantic
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFBA1A1A);

  // PQC Security
  static const quantum = Color(0xFF00BCD4);
  static const encrypted = Color(0xFF8BC34A);
  static const shield = Color(0xFF3F51B5);
  static const verified = Color(0xFF009688);
}
```

### Tokens de Espaçamento

```dart
// lib/theme/spacing.dart
class BJBankSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}
```

---

## Arquivos Relacionados

- `design-system.json` - Tokens em formato JSON
- `design-system.excalidraw` - Diagrama visual do design system

---

*BJBank Design System v1.0.0 - Segurança Quântica para seu Futuro Financeiro*
