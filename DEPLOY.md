# Como publicar o painel (custo zero)

## 1. Aplicar as políticas de segurança no Supabase
1. Abra seu projeto no Supabase → menu **SQL Editor**.
2. Cole o conteúdo de `01_rls_policies.sql` e execute (Run).
3. Confirme em **Authentication → Policies** que `pd_ultimo_estagio`, `mo_3104` e `etl_controle` aparecem com RLS habilitado e uma policy de SELECT para `anon`.

## 2. Pegar a Anon Key
1. No Supabase, vá em **Project Settings → API**.
2. Copie a **URL do projeto** e a **anon public key** (não é a `service_role`, essa nunca deve ir para o frontend).

## 3. Configurar o `index.html`
Abra o arquivo `index.html` e edite as 2 primeiras linhas do bloco `CONFIG`, no topo do `<script>`:

```js
SUPABASE_URL: 'https://SEU-PROJETO.supabase.co',
SUPABASE_ANON_KEY: 'SUA-ANON-KEY-AQUI',
```

Salve o arquivo.

## 4. Publicar no Vercel (grátis)
Opção mais simples, sem precisar de Git:
1. Crie uma conta em vercel.com (pode usar login do GitHub/Google).
2. No dashboard da Vercel, clique em **Add New → Project**.
3. Escolha **Deploy without Git** / arraste a pasta contendo o `index.html` para a área de upload.
4. Confirme o deploy. A Vercel vai te dar uma URL pública (ex: `seu-painel.vercel.app`).

## 5. Exibir na TV
1. Conecte um Chromecast/Fire TV Stick/mini PC à TV (o que você já tiver disponível).
2. Abra a URL no navegador em tela cheia (F11) — ou use uma extensão de "kiosk mode" se o dispositivo suportar.
3. Deixe a aba aberta. O painel se atualiza só (sem precisar de F5).

## 6. Testar antes de fixar na TV
- Espere 1-2 minutos e confirme que os números mudam conforme o Supabase atualiza.
- Espere 15 segundos e confirme que a tela alterna entre "pedidos travados" e "falta de entrega".
- Pare o fluxo do n8n de propósito por alguns minutos e confirme que aparece o aviso de atualização atrasada no canto superior direito.
