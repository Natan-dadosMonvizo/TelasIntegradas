-- =====================================================================
-- Tabela "pd_sem_intelipost" — pedidos faturados sem código de
-- integração Intelipost (FLAGPERFILCODIGO = 801) gerado.
-- =====================================================================
-- Execute este script no SQL Editor do Supabase ANTES de importar o
-- workflow atualizado no n8n. Depois, rode novamente o
-- 01_rls_policies.sql (já atualizado com esta tabela) para liberar a
-- leitura via Anon Key no dashboard.
-- =====================================================================

CREATE TABLE IF NOT EXISTS public.pd_sem_intelipost (
  id_pedido         text PRIMARY KEY,
  dt_pedido_emissao timestamptz,
  id_cliente        text,
  id_vendedor       text,
  nome_vendedor     text,
  id_transportadora text,
  transportadora    text,
  atualizado_em     timestamptz NOT NULL DEFAULT now()
);

-- Caso você já tenha rodado uma versão anterior deste script (sem a
-- coluna nome_vendedor), este ALTER garante que ela seja adicionada.
ALTER TABLE public.pd_sem_intelipost
  ADD COLUMN IF NOT EXISTS nome_vendedor text;
