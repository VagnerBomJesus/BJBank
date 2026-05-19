# Envio de OTP por Email

A aplicação BJBank envia códigos OTP através da Edge Function `send_otp_email` no Supabase, com integração ao serviço Resend.

## Implementação

### Edge Function `send_otp_email`

Localização: `supabase/functions/send_otp_email/index.ts`. Já deployada no projecto `jdybjrpmybkmmfdlwrzp`.

A função:

- Aceita `{ email, otp, phone? }` no body
- Se `RESEND_API_KEY` estiver configurada nos secrets, envia HTML formatado via Resend
- Sem API key, regista o código nos logs da Edge Function (modo dev) e devolve `{ ok: true, devMode: true }`
- Exige JWT válido (proteção contra spam)

### Configuração do Resend (opcional)

1. Criar conta gratuita em [resend.com](https://resend.com)
2. Obter API key no dashboard Resend
3. No Supabase Dashboard → Project Settings → Edge Functions → Secrets:
   - `RESEND_API_KEY=re_xxxxxxxxx`
   - (Opcional) `OTP_EMAIL_FROM=BJBank <noreply@teu-dominio.com>` (default: `BJBank <onboarding@resend.dev>`)

### Sem configuração

Sem `RESEND_API_KEY`, o OTP gerado fica visível em **Supabase Dashboard → Edge Functions → `send_otp_email` → Logs**. Útil para desenvolvimento e testes.

### Cliente Flutter

O serviço `OtpService._sendOtpViaEmail` chama directamente a Edge Function:

```dart
final response = await sb.functions.invoke(
  'send_otp_email',
  body: {'email': email, 'otp': otp, 'phone': phone},
);
```

## Ver também

- `docs/DEPLOYMENT.md` — guia completo de configuração Supabase
- `docs/ARCHITECTURE.md` — arquitectura técnica
- `lib/services/otp_service.dart` — implementação cliente
