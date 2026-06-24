-- =====================================================================
-- ALTER da tabela "pd_ultimo_estagio" — adiciona valor do pedido e nome
-- do cliente, que antes não eram trazidos pela query do ERP.
-- =====================================================================
-- Execute este script no SQL Editor do Supabase ANTES de importar o
-- workflow n8n atualizado. As colunas são adicionadas com IF NOT EXISTS,
-- então é seguro rodar de novo caso já tenha sido aplicado.
-- =====================================================================

ALTER TABLE public.pd_ultimo_estagio
  ADD COLUMN IF NOT EXISTS valor_pedido  numeric,
  ADD COLUMN IF NOT EXISTS nome_cliente  text;

-- Não é necessário alterar a RLS: a policy "tv_dashboard_select_only"
-- já liberada em 01_rls_policies.sql cobre a tabela inteira (SELECT *),
-- então as novas colunas já ficam visíveis pra Anon Key automaticamente.
