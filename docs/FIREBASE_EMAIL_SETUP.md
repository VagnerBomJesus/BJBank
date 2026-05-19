# Firebase Email Configuration - OTP via Email

## Overview

Este guia configura o envio automático de OTP (One-Time Password) via email usando Firebase Cloud Functions e Gmail SMTP.

**Custo**: Totalmente GRATUITO (limite de 100 emails/dia no plano gratuito do Firebase)

---

## 📋 Pré-requisitos

1. Projeto Firebase já configurado (bjbank)
2. Conta Google com Gmail habilitado
3. Node.js 20+ instalado
4. Firebase CLI instalado: `npm install -g firebase-tools`

---

## 🔧 Configuração do Gmail

### 1. Ativar Acesso a Apps Menos Seguros (Método Simples)

**Opção A: Se você não tem 2FA ativado**

1. Acesse: https://myaccount.google.com/apppasswords
2. Pode ser redirecionado para ativar 2FA primeiro
3. Depois, gera uma **Password de App** (16 caracteres)
4. Copie esta password (usaremos no passo 3)

**Opção B: Se tem 2FA ativado (recomendado)**

1. Acesse: https://myaccount.google.com/apppasswords
2. Selecione "Mail" e "Windows Computer"
3. Clique em "Gerar"
4. Google gera uma password de 16 caracteres
5. Copie esta password

### 2. Se Não Conseguir Gerar App Password

Use a senha da sua conta Google normalmente:
- Menos seguro, mas funciona
- Acesse: https://myaccount.google.com/security
- Procure por "Apps menos seguros" e ative

---

## 🚀 Deployment da Cloud Function

### 1. Instalar Dependências

```bash
cd functions
npm install
```

### 2. Configurar Variáveis de Ambiente

**Opção A: Via Firebase CLI (Recomendado)**

```bash
firebase functions:config:set gmail.user="seu_email@gmail.com" gmail.password="sua_password_de_app"
```

**Opção B: Arquivo .env.local**

Criar `functions/.env.local`:
```
GMAIL_USER=seu_email@gmail.com
GMAIL_PASSWORD=sua_password_de_app
```

### 3. Fazer Deploy

```bash
firebase deploy --only functions
```

O Firebase CLI vai:
- Compilar TypeScript → JavaScript
- Fazer upload da função
- Ativar a função `sendOtpEmail` automaticamente

**Saída esperada:**
```
✔  Deploy complete!

Function URL (sendOtpEmail(us-central1)):
https://us-central1-seu-projeto.cloudfunctions.net/sendOtpEmail
```

---

## 🧪 Testar Localmente (Opcional)

### 1. Iniciar Emulador

```bash
firebase emulators:start --only functions
```

### 2. Chamar Cloud Function (via curl)

```bash
curl -X POST http://localhost:5001/seu-projeto/us-central1/sendOtpEmail \
  -H "Content-Type: application/json" \
  -d '{
    "email": "seu_email@gmail.com",
    "otp": "123456",
    "phone": "+351912345678",
    "userName": "Joao"
  }'
```

---

## 📱 Usar no App Flutter

### 1. Código já está Pronto

Ficheiro: `lib/services/otp_service.dart`

A função `_sendOtpViaEmail()` já:
- ✓ Valida email
- ✓ Autentica com Firebase Auth
- ✓ Chama Cloud Function
- ✓ Trata erros gracefully

### 2. Fluxo de MB WAY

1. Utilizador abre "Ativar MB WAY" → `MbWayPhoneVerificationScreen`
2. Insere:
   - Numero de telemovel (9 digitos)
   - Email
3. Clica "Enviar Codigo"
4. `OtpService.sendOtp(phone, email: email)` é chamado
5. Cloud Function envia email com OTP
6. Utilizador recebe email com codigo de 6 digitos
7. Insere codigo na tela
8. MB WAY é ativado

### 3. Fallback para Demo

Se email não conseguir enviar:
- Mensagem aparece no console de debug
- App continua funcionando
- Permitir entrada manual de OTP

---

## 🔐 Segurança

### O que a Cloud Function Faz

✓ Valida autenticação do utilizador (Firebase Auth)
✓ Valida formato de email
✓ Valida OTP (6 digitos)
✓ Regista logs de auditoria no Firestore
✓ Criptografa conexão (HTTPS)
✓ Não armazena passwords em código

### O que NÃO é Guardado

❌ A função não armazena o OTP no Firestore (fica apenas local)
❌ A função não envia passwords
❌ A função não faz tracking de utilizadores

---

## 📊 Monitoring & Logs

### Ver Logs da Cloud Function

```bash
firebase functions:log
```

### Logs em Tempo Real

```bash
firebase functions:log --follow
```

### Firebase Console

1. Acesse: https://console.firebase.google.com/
2. Projeto → Functions
3. Selecione `sendOtpEmail`
4. Abas: Logs, Monitoring, etc.

---

## 🆘 Troubleshooting

### Erro: "Gmail Authentication Failed"

**Solução:**
- Verificar credentials em Firebase Config
- Testar password em: https://myaccount.google.com/apppasswords
- Regenerar password nova

```bash
firebase functions:config:set gmail.password="nova_password"
firebase deploy --only functions
```

### Erro: "Invalid Argument - Email"

**Causa:** Formato de email inválido

**Solução:**
- Verificar validação em `otp_service.dart`
- Assegurar que app envia email formatado corretamente

### Erro: "User not Authenticated"

**Causa:** Utilizador não fez login no Firebase

**Solução:**
- Função requer `context.auth` (implementado)
- Verificar que utilizador está autenticado antes

### Erro: "Cloud Functions not Available"

**Causa:** Função não fez deploy ou não está ativa

**Solução:**
```bash
# Verificar status
firebase functions:describe sendOtpEmail

# Fazer deploy novamente
firebase deploy --only functions
```

---

## 📧 Customização do Email

### Modificar Template

Editar: `functions/src/index.ts` → função `generateEmailTemplate()`

**Pode customizar:**
- Cores
- Logo/Branding
- Mensagens (português)
- Layout HTML

### Fazer Deploy da Alteração

```bash
npm run build
firebase deploy --only functions
```

---

## 💰 Custos

### Plano Gratuito Firebase

| Recurso | Limite Gratuito |
|---------|-----------------|
| Cloud Functions | 125.000 invocações/mês |
| CPU Time | 400.000 GB-segundos/mês |
| Envios de Email | Sem limite (mas relying em SMTP) |
| Firestore (logs) | 50k operações/dia |

### Estimativa de Uso

- 100 utilizadores/mês × 1 email cada = 100 emails
- 1 tentativa resend = 200 emails máximo/mês
- **Totalmente dentro do limite gratuito**

---

## ✅ Checklist de Implementação

- [ ] Conta Google com Gmail habilitado
- [ ] 2FA ativado na conta Google
- [ ] App Password gerada (16 caracteres)
- [ ] `npm install` executado em `functions/`
- [ ] Variáveis configuradas: `firebase functions:config:set`
- [ ] `firebase deploy --only functions` bem-sucedido
- [ ] Cloud Function ativa no Firebase Console
- [ ] App Flutter faz `flutter pub get` (nova dependência)
- [ ] Tela MB WAY com campo de email
- [ ] Testar fluxo completo: Phone + Email → OTP → Verificação

---

## 📞 Suporte

Para dúvidas ou problemas:

1. Verificar logs: `firebase functions:log`
2. Testar Cloud Function manualmente
3. Verificar credentials Gmail
4. Verificar Authentication Firebase

---

**Última atualização:** 2024
**Versão:** 1.0.0
