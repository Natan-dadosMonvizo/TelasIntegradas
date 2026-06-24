-- =====================================================================
-- Tabela "pd_criado_despachado_intelipost" — pedidos com código
-- Intelipost (VDPVENDACODIGOAUXILIAR) nas situações 801 (criado) ou
-- 811 (despachado), a partir de 2026-01-01.
-- =====================================================================
-- Execute este script no SQL Editor do Supabase ANTES de configurar o
-- node do n8n que vai popular esta tabela. Depois, rode novamente o
-- 01_rls_policies.sql (já atualizado com esta tabela) para liberar a
-- leitura via Anon Key no dashboard.
--
-- Observação sobre a chave: a query original junta VDPVENDAC com
-- VDPVENDACODIGOAUXILIAR por PEDIDO+FILIAL e filtra FlagSituacao IN
-- (801, 811). Um mesmo pedido pode ter as duas linhas (uma "criado" e
-- uma "despachado"), então id_pedido sozinho NÃO é único. Por isso:
--   - chave primária é um "id" surrogate (bigserial);
--   - UNIQUE(id_pedido, flagsituacao) garante 1 linha por pedido por
--     situação, e é a coluna a usar no ON CONFLICT do upsert no n8n.
-- =====================================================================

CREATE TABLE IF NOT EXISTS public.pd_criado_despachado_intelipost (
  id                 bigserial PRIMARY KEY,
  id_pedido          text NOT NULL,
  dt_pedido_emissao  timestamptz,
  id_cliente         text,
  id_vendedor        text,
  id_transportadora  text,
  transportadora     text,
  flagperfilcodigo   text,
  flagsituacao       text,
  desc_situacao      text,
  atualizado_em      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pd_criado_despachado_intelipost_pedido_situacao_uk
    UNIQUE (id_pedido, flagsituacao)
);

-- Índice para os filtros mais comuns do dashboard (por situação e por
-- data de emissão).
CREATE INDEX IF NOT EXISTS pd_criado_despachado_intelipost_situacao_idx
  ON public.pd_criado_despachado_intelipost (flagsituacao);
CREATE INDEX IF NOT EXISTS pd_criado_despachado_intelipost_emissao_idx
  ON public.pd_criado_despachado_intelipost (dt_pedido_emissao);
