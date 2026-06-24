-- =====================================================================
-- Tabela "historico_pedidos" — eventos de histórico do pedido
-- (VDPVENDAHISTORICO) dos últimos 7 dias, filtrados por SEPARAÇÃO/
-- FATURAMENTO. Grão: 1 linha por evento de histórico (filial+pedido+
-- sequencia), não por pedido — um mesmo pedido pode ter várias linhas
-- aqui, uma para cada evento relevante que passou pela observação.
-- =====================================================================
-- Execute este script no SQL Editor do Supabase ANTES de importar o
-- workflow n8n atualizado. Depois, rode novamente o 01_rls_policies.sql
-- (já atualizado com esta tabela) para liberar a leitura via Anon Key.
--
-- filial/pedido como text: mesma convenção já adotada em
-- pd_item_estagio (ver 06_pd_item_estagio_schema.sql) — evita o
-- problema de "smallint/integer out of range" que já apareceu antes
-- nesse projeto, e mantém o padrão de chave multi-filial (pedido pode
-- repetir número entre filiais diferentes).
--
-- dias_desde_evento: calculado no próprio SELECT do ERP via
-- DATEDIFF(DAY, DATAHORAINCLUSAO, GETDATE()) — like dias_no_estagio em
-- pd_ultimo_estagio, esse valor é recalculado a cada execução do n8n
-- (a cada 5 minutos), então a coluna salva aqui reflete o valor no
-- momento da última sincronização, não em tempo real.
-- =====================================================================

CREATE TABLE IF NOT EXISTS public.historico_pedidos (
  id                  bigserial PRIMARY KEY,
  filial              text NOT NULL,
  pedido              text NOT NULL,
  status              text,
  valor_pedido        numeric,
  sequencia           integer NOT NULL,
  flag_tipo_alteracao text,
  data_pedido         timestamptz,
  data_hora_inclusao  timestamptz,
  data_hora_alteracao timestamptz,
  observacao          text,
  status_resumo       text,
  dias_desde_evento   integer,
  atualizado_em       timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT historico_pedidos_filial_pedido_sequencia_uk
    UNIQUE (filial, pedido, sequencia)
);

CREATE INDEX IF NOT EXISTS historico_pedidos_pedido_idx
  ON public.historico_pedidos (filial, pedido);
CREATE INDEX IF NOT EXISTS historico_pedidos_atualizado_em_idx
  ON public.historico_pedidos (atualizado_em);

-- =====================================================================
-- Como confirmar:
-- 1. Rode este script no SQL Editor do Supabase.
-- 2. Rode 01_rls_policies.sql de novo (já inclui esta tabela).
-- 3. Importe o workflow n8n atualizado e execute — a branch
--    "ERP - Buscar historico_pedidos" deve popular a tabela sem erros.
-- =====================================================================
