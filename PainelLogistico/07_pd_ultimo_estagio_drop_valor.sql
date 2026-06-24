-- =====================================================================
-- Remove valor_pedido de pd_ultimo_estagio.
-- =====================================================================
-- O valor do pedido deixou de ser necessário nesta tabela. Ele passou a
-- ser lido a partir de pd_item_estagio (coluna valor_pedido, ver
-- 06_pd_item_estagio_schema.sql), exposto por pedido através da view
-- vw_pedido_status_estagio. nome_cliente permanece em pd_ultimo_estagio,
-- só valor_pedido está sendo removido.
--
-- Execute este script no SQL Editor do Supabase. Depois de rodar,
-- reimporte o workflow n8n atualizado (que já não envia mais
-- valor_pedido para esta tabela).
-- =====================================================================

ALTER TABLE public.pd_ultimo_estagio
  DROP COLUMN IF EXISTS valor_pedido;
