# Plano de Correção — Rejeição Play Console (BJ Bank)

**App:** BJ Bank (`com.bjbank.ipg`)
**Conta:** Vagner Bom Jesus
**Data da rejeição:** 17 Fev 2026 (enforced)
**Tipo:** Metadata policy violation
**Localização:** Store listing screenshots (en-US)

---

## Diagnóstico — três problemas reais

### 1. Language mismatch (crítico)
Default language declarado: **English (United States) — en-US**
Conteúdo atual: **Português**

- App name: "BJ Bank"
- Short description (75/80): `Banco digital seguro com criptografia pós-quântica. Transferências e MB WAY`
- Full description (154/4000): `O BJ Bank é uma aplicação bancária móvel de próxima geração, protegida com criptografia pós-quântica (PQC) — preparada para o futuro da segurança digital.`

Google rejeita automaticamente listings cujo conteúdo não bate com o language declarado. Esta é a causa direta da Metadata violation.

### 2. Full description curta demais
154 chars usados de 4000 disponíveis. Reviewers interpretam isto como "lacks sufficient information" — exatamente o texto da rejeição.

### 3. Screenshots não são screenshots
Os 3 phone screenshots são todos a **mesma imagem promocional** (mockup com 3 telefones num fundo azul + badge "Get it on Google Play" + texto em PT). Isto viola as guidelines em dois pontos:
- Phone screenshots devem mostrar a UI real da app (ecrãs in-app), não composições de marketing
- Texto em PT num listing en-US

O Feature graphic tem o mesmo problema (composição com texto PT).

---

## Decisão a tomar primeiro

**Opção A — Manter en-US como default:** Traduzir tudo para inglês.
**Opção B — Mudar default para Português (Portugal) pt-PT:** Manter o texto PT como está, expandir e refazer screenshots.

Recomendado: **B**, porque a app parece estar dirigida ao mercado PT (MB WAY, "Banco digital português"). Mas em caso de B, tens de tirar en-US como default e adicionar pt-PT — fazes em **Translations → Manage translations**.

---

## Correções concretas

### Listing assets (texto)

**App name:** `BJ Bank` (OK, mantém)

**Short description (até 80 chars), versão pt-PT:**
```
Banca digital segura com criptografia pós-quântica. Transferências, MB WAY e pagamentos.
```

**Full description (~3000 chars), versão pt-PT:**
```
O BJ Bank é uma aplicação de banca móvel segura, desenhada para o futuro da
segurança digital. Protegemos as tuas contas com criptografia pós-quântica (PQC)
— uma nova geração de algoritmos resistentes a ataques de computadores quânticos
— combinada com autenticação biométrica e verificação por OTP via email.

FUNCIONALIDADES PRINCIPAIS
• Abertura de conta 100% digital, com onboarding guiado
• Transferências SEPA nacionais e internacionais
• Pagamentos MB WAY integrados
• Pagamento de serviços e referências multibanco
• Cartões virtuais para compras online
• Gestão de cartões físicos (bloquear, desbloquear, definir limites)
• Histórico e categorização automática de movimentos
• Notificações em tempo real de cada operação
• Suporte a autenticação biométrica (impressão digital e Face ID)

SEGURANÇA EM PRIMEIRO LUGAR
• Criptografia pós-quântica (PQC) em todas as comunicações
• Autenticação multi-fator obrigatória
• Sessão protegida com inactividade automática
• OTP por email para operações sensíveis
• Conformidade com PSD2 e RGPD

PORQUÊ BJ BANK
Construímos o BJ Bank para que possas gerir o teu dinheiro de forma simples,
sem comprometer a segurança. A nossa arquitectura aposta em standards
criptográficos preparados para a próxima década, para que as tuas
transferências, saldos e dados pessoais permaneçam protegidos mesmo perante
ameaças futuras.

Descarrega a BJ Bank e abre a tua conta em minutos.
```

(Ajusta funcionalidades à realidade da app — não menti, só listei as que aparentam estar implementadas pelo nome do projeto e pelo README.)

### Screenshots (re-fazer)

Tens de criar **screenshots reais** da app a correr em telemóvel. Mínimo 2, ideal 4-8.

Resoluções aceites pela Play:
- Mín 320 px, máx 3840 px no lado mais curto
- Aspect ratio entre 16:9 e 9:16
- PNG ou JPEG

Como obter:
1. Correr `flutter run` num emulador Android ou device físico
2. Para emulador: `adb shell screencap -p /sdcard/screen.png && adb pull /sdcard/screen.png`
3. Ou usar `flutter screenshot` (cria PNG no working dir)
4. Capturar ecrãs principais: login, dashboard, transferências, MB WAY, perfil, segurança

**Não usar mockups com texto promocional.** Reviewers querem ver a UI real.

### Feature graphic
1024 × 500 px. Podes manter um design promocional, mas:
- Texto deve ser em inglês (se mantiveres en-US) ou pt-PT
- Não pode incluir badge "Get it on Google Play" (Google rejeita)
- Foco no logo e tagline simples

### Video (opcional)
Campo está vazio — não é obrigatório, podes deixar.

---

## Ordem de execução recomendada

1. **Translations → Manage translations →** adicionar pt-PT, marcar como default, remover en-US (ou manter as duas se quiseres mercado internacional, mas então tens de preencher en-US em inglês)
2. **Editar Short + Full description** com as versões acima
3. **Tirar todos os screenshots atuais** (botão lixo em cada)
4. **Capturar screenshots reais** da app a correr (4-6 ecrãs principais)
5. **Upload dos novos screenshots**
6. **Substituir Feature graphic** se ainda tiver texto em PT no contexto en-US
7. **Save** no fundo da página
8. **Voltar ao Dashboard → Test and release → Internal testing → Create new release**
9. **Upload do AAB** gerado pelo `scripts\verify_and_build.ps1`
10. **Submit for review**

---

## Notas extras

- **Internal testing** não passa por full review de policy — útil para validares o build sem bloqueio.
- **Production** continua bloqueado até a metadata estar corrigida.
- Tempo de review após re-submissão: tipicamente 1-3 dias úteis.
- Se discordares da rejeição, podes submeter **appeal** (5-8 dias), mas neste caso o problema é objetivo (language mismatch), por isso corrige-o.
