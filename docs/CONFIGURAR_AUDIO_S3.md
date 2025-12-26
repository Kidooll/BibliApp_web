# Configurar Áudios do Sleep (S3/CloudFront)

Este guia cobre a configuração de hospedagem dos áudios da seção “Dormir” usando
S3 (e opcionalmente CloudFront), e como atualizar o catálogo do app.

---

## 1) Decida o tipo de acesso

### Opção A — **Público (mais simples)**
- Os arquivos ficam públicos no bucket (ou via CloudFront).
- URL direta e estável, sem expiração.
- Ideal para assets que não precisam de proteção.

### Opção B — **Privado (mais seguro)**
- O bucket é privado.
- O app precisa de **URLs assinadas** (S3 presigned ou CloudFront signed).
- **Não** coloque URLs assinadas fixas no `sleep_catalog.json` (elas expiram).

---

## 2) Configurar bucket S3 (público)

1. No bucket, deixe **Public Access** permitido.
2. Adicione um bucket policy (exemplo):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::SEU_BUCKET/*"
    }
  ]
}
```

3. Garanta o **Content-Type** correto ao subir:
   - `audio/mpeg` para `.mp3`
   - `audio/mp4` para `.m4a`

4. (Opcional) Adicione Cache-Control:
   - `Cache-Control: public, max-age=31536000, immutable`

---

## 3) Configurar CORS (web)

No S3, em **CORS configuration**:

```json
[
  {
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": ["ETag", "Content-Length", "Content-Range"]
  }
]
```

Se quiser restringir, troque `"*"` pelo domínio do app.

---

## 4) Configurar CloudFront (recomendado)

Use CloudFront para:
- Melhor performance.
- URLs estáveis e curtas.
- Cache eficiente.

Configuração básica:
- Origin: seu bucket S3
- Viewer protocol: Redirect HTTP to HTTPS
- Default behavior: Cache GET/HEAD
- Se bucket for privado: usar **OAC** (Origin Access Control).

---

## 5) Atualizar o catálogo do app

Arquivo: `bibli_app/assets/data/sleep_catalog.json`

Troque o campo `"audio_url"` por uma URL **estável**:

Exemplo público:
```
https://SEU_BUCKET.s3.sa-east-1.amazonaws.com/bible_audio/arquivo.mp3
```

Exemplo com CloudFront:
```
https://d123abc.cloudfront.net/bible_audio/arquivo.mp3
```

**Evite** URLs com `X-Amz-Expires=300` (expiram em minutos).

---

## 6) Se o bucket for privado

Você precisa gerar **URLs assinadas em runtime**:

Opções:
1. **Backend** gera URL assinada e o app consome via API.
2. **CloudFront Signed URLs/Cookies** para distribuir conteúdo privado.

Nesse cenário, o `sleep_catalog.json` deve trazer **apenas o ID** do áudio,
e o app consulta um endpoint para obter a URL assinada.

---

## Checklist rápido

- [ ] Bucket com CORS liberado para GET
- [ ] Content-Type correto nos arquivos
- [ ] URLs estáveis no `sleep_catalog.json`
- [ ] (Opcional) CloudFront configurado
- [ ] (Se privado) URLs assinadas geradas em runtime

---

Se quiser, posso criar o endpoint de URL assinada e adaptar o app para buscar
as URLs em runtime. Também posso atualizar o `sleep_catalog.json` com as novas
URLs definitivas.  
