-- =====================================================================
-- Tabela de controle para o "Padrão B" (tabelas históricas/incrementais)
-- =====================================================================
-- Objetivo: guardar, por tabela, a última data/hora até onde os dados já
-- foram sincronizados. Assim, ao adicionar as próximas 20-30 tabelas, o
-- workflow do n8n busca no ERP só os registros que mudaram desde a última
-- execução — em vez de escanear a tabela inteira a cada 5 minutos.
--
-- Observação: você já tem uma tabela "etl_controle" no Supabase (referenciada
-- em 01_rls_policies.sql). Este script usa "IF NOT EXISTS" / "ADD COLUMN IF
-- NOT EXISTS", então é seguro rodar de novo — ele não apaga nada. Mas se a
-- tabela já existir com colunas diferentes destas, me avise para eu ajustar
-- as queries do workflow para o nome certo.
-- =====================================================================

CREATE TABLE IF NOT EXISTS public.etl_controle (
  nome_tabela     text PRIMARY KEY,
  ultima_execucao timestamptz NOT NULL DEFAULT '2000-01-01T00:00:00Z',
  atualizado_em   timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.etl_controle
  ADD COLUMN IF NOT EXISTS ultima_execucao timestamptz NOT NULL DEFAULT '2000-01-01T00:00:00Z';

ALTER TABLE public.etl_controle
  ADD COLUMN IF NOT EXISTS atualizado_em timestamptz NOT NULL DEFAULT now();

-- =====================================================================
-- Como usar no n8n, para cada tabela nova do Padrão B (ex.: "cotacoes_frete"):
--
-- 1) Nó Postgres (SELECT) — ler a última execução:
--    SELECT ultima_execucao
--    FROM public.etl_controle
--    WHERE nome_tabela = 'cotacoes_frete';
--    (se não existir linha, faça um INSERT inicial — veja abaixo)
--
-- 2) Nó MSSQL (SELECT no ERP) — use a data lida acima no WHERE:
--    WHERE DATAHORAALTERACAO > '{{ $json.ultima_execucao }}'
--
-- 3) Nó Postgres (upsert) — grava os registros novos/alterados.
--
-- 4) Nó Postgres (UPDATE) — avança o marcador para "agora":
--    INSERT INTO public.etl_controle (nome_tabela, ultima_execucao, atualizado_em)
--    VALUES ('cotacoes_frete', NOW(), NOW())
--    ON CONFLICT (nome_tabela) DO UPDATE
--      SET ultima_execucao = EXCLUDED.ultima_execucao,
--          atualizado_em   = EXCLUDED.atualizado_em;
-- =====================================================================
