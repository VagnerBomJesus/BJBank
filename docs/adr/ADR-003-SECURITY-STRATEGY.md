# ADR-003: Estratégia de Segurança

**Data**: Maio de 2026
**Estado**: Aceite e implementado
**Autor**: Vagner Bom Jesus

---

## 1. Contexto

A aplicação BJBank executa operações bancárias sensíveis. Define-se uma estratégia de segurança em camadas (*defense in depth*) que protege:

- Autenticação de utilizadores
- Confidencialidade e integridade das transferências
- Resistência ao cenário *Harvest Now, Decrypt Later* (HNDL)
- Privacidade de dados sob RGPD

---

## 2. Decisão

Arquitectura de segurança em **cinco camadas** complementares:

| Camada | Mecanismo | Componente |
|---|---|---|
| 1. Transporte | TLS 1.3 sobre ECDHE-X25519 | Supabase (gerido) |
| 2. Autenticação | JWT emitido por Supabase Auth | `SupabaseAuthService` |
| 3. Autorização | Row Level Security em PostgreSQL | Políticas RLS |
| 4. Integridade da transacção | ML-DSA-65 (FIPS 204) | `flutter_sign_transfer` Edge Function |
| 5. Confidencialidade da payload | AES-256-GCM com HKDF-SHA-256 | `SupabaseTransferService` |

---

## 3. Modelo de ameaça

### 3.1. Ameaças identificadas

| ID | Ameaça | Severidade |
|---|---|---|
| T1 | HNDL — captura de dados cifrados hoje, decifragem futura com computador quântico | CRÍTICA |
| T2 | MITM no handshake (atacante intercepta e substitui chave do servidor) | ALTA |
| T3 | Replay de transferência (atacante reenvia mensagem assinada válida) | ALTA |
| T4 | Substituição de chave pública do cliente | MÉDIA |
| T5 | Race condition em transferências concorrentes | MÉDIA |
| T6 | Bypass de RLS para aceder a contas de outros utilizadores | ALTA |
| T7 | Acesso não autorizado à BD via service_role | CRÍTICA |
| T8 | Side-channel attacks (timing, cache) sobre primitivas PQC | BAIXA |

### 3.2. Mitigações aplicadas

| Ameaça | Mitigação |
|---|---|
| T1 | AES-256-GCM dentro de envelope assinado com ML-DSA-65 (FIPS 204) |
| T2 | TOFU pinning da chave pública ML-DSA do servidor (`TrustedServerKeyService`) + verificação `verify_dsa` da assinatura do transcript |
| T3 | `txId` UUID v4 (≈122 bits entropia) + UNIQUE PK em `transactions` + sessões com `expires_at` 1h |
| T4 | Pin de `pqc_public_key_base64` em `public.users` no primeiro signing; rejeição de chaves diferentes em assinaturas subsequentes |
| T5 | `SELECT FOR UPDATE` em `accounts` + transacção SQL atómica na RPC `executar_transferencia_atomica` |
| T6 | Políticas RLS declarativas em todas as tabelas; service_role só nas Edge Functions |
| T7 | service_role key apenas no servidor Supabase (nunca exposta no cliente); RPCs `SECURITY DEFINER` para lookup público controlado |
| T8 | Limitação aceite; aprofundamento previsto em trabalho futuro |

---

## 4. Pipeline criptográfico

### 4.1. Handshake (estabelecimento de chave de sessão)

```
Cliente                          Edge Function
   |  POST pqc_handshake_flutter      |
   |  { clientNonceBase64 }            |
   |---------------------------------->|
   |                                   | gera sharedSecret (32B)
   |                                   | assina transcript com ML-DSA-65
   |                                   | persiste em public.sessions
   |  { sessionId, sharedSecret,      |
   |    serverDsaPub, signature }     |
   |<----------------------------------|
   |
   | POST verify_dsa
   |---------------------------------->|
   | { valid: true }
   |<----------------------------------|
   |
   | TOFU pin da serverDsaPub
   | HKDF(sharedSecret, sid, info, 44)
   | -> aesKey (32B) + nonceBase (12B)
```

### 4.2. Transferência assinada

```
1. Construir payload canónico (bytes determinísticos)
2. Assinar payload com ML-DSA-65 (Edge Function)
3. Envelope = [4B|payload_len][payload][4B|sig_len][signature]
4. iv = nonceBase XOR txId[0..12]
5. aad = sessionId UTF-8
6. Cifrar envelope com AES-256-GCM
7. POST executar_transferencia
8. Servidor: decifra, verifica ML-DSA, reconstrói transcript, RPC atómica
```

---

## 5. Pinning TOFU

Implementação em `TrustedServerKeyService`:

```dart
class TrustedServerKeyService {
  static const _key = 'trusted_server_dsa_public';

  Future<void> setTrustedKey(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, base64Encode(bytes));
  }

  Future<bool> verificar(Uint8List serverKey) async {
    final stored = await getTrustedKey();
    if (stored == null) {
      await setTrustedKey(serverKey);
      return true;
    }
    return _bytesEqual(stored, serverKey);
  }
}
```

- **First Use**: a chave é guardada no primeiro contacto
- **Subsequente**: comparação byte-a-byte; rejeição em caso de mismatch

---

## 6. Row Level Security

Todas as 15 tabelas têm RLS activo. Exemplo das políticas em `accounts`:

```sql
CREATE POLICY accounts_select_own ON public.accounts
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY accounts_write_service ON public.accounts
  FOR ALL USING (auth.role() = 'service_role');
```

Lookup público de IBAN (sem expor saldo) via RPC `SECURITY DEFINER`:

```sql
CREATE FUNCTION public.lookup_account_by_iban(p_iban text)
RETURNS TABLE (account_id uuid, user_id uuid, iban text, owner_name text)
LANGUAGE sql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT a.id, a.user_id, a.iban, u.nome_completo
  FROM public.accounts a JOIN public.users u ON u.id = a.user_id
  WHERE a.iban = upper(regexp_replace(p_iban, '\s', '', 'g'))
  LIMIT 1;
$$;
```

---

## 7. Limitações reconhecidas

1. **Chave privada ML-DSA do cliente armazenada no servidor** (`flutter_client_keys.secret_key_base64`) por ausência de bibliotecas Dart fiáveis para ML-DSA. Mitigação em produção: HSM/KMS.
2. **Sem rotação automática de chaves do servidor** — exige intervenção manual via SQL Editor (`DELETE FROM public_config WHERE key='server_ml_dsa'`).
3. **Sem proteção explícita contra replay além do UUID** — recomendado adicionar `WHERE NOT EXISTS` na RPC atómica.
4. **Side-channels não analisados** — análise prevista em trabalho futuro.

---

## 8. Métricas de validação

- Cobertura de RLS: 100% das tabelas
- Sessões com `expires_at` ≤ 1h: 100% (enforced por código)
- Verificação ML-DSA antes de qualquer operação destrutiva: 100%
- IVs únicos garantidos pelo UUID v4 (entropia ≈ 122 bits): probabilidade de colisão negligenciável

---

## Decisões relacionadas

- **ADR-001 PQC Implementation** — estratégia de implementação dos algoritmos
- **ADR-002 State Management** — gestão de estado
