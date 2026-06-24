-- =====================================================================
-- Atualização da tabela "pd_criado_despachado_intelipost" para a nova
-- lógica do n8n: cada pedido agora gera APENAS 1 linha (a do status
-- mais recente dele), em vez de até 2 linhas (uma "criado" + uma
-- "despachado"). Execute no SQL Editor do Supabase ANTES de rodar o
-- workflow atualizado.
-- =====================================================================

-- 1) Nova coluna com a data/hora real da última alteração de status
--    no ERP (COD.DataHoraAlteracao).
ALTER TABLE public.pd_criado_despachado_intelipost
  ADD COLUMN IF NOT EXISTS data_alteracao timestamptz;

-- 2) Como a chave única antiga era (id_pedido, flagsituacao) e agora
--    cada pedido só deve ter 1 linha (a do status atual), zera a
--    tabela: o próximo ciclo do n8n já repopula tudo corretamente.
TRUNCATE TABLE public.pd_criado_despachado_intelipost;

-- 3) Troca a chave única: agora é só id_pedido. Isso faz o upsert do
--    n8n SUBSTITUIR a linha do pedido quando o status mudar (ex.: de
--    801 para 811), em vez de criar uma segunda linha.
ALTER TABLE public.pd_criado_despachado_intelipost
  DROP CONSTRAINT IF EXISTS pd_criado_despachado_intelipost_pedido_situacao_uk;

ALTER TABLE public.pd_criado_despachado_intelipost
  ADD CONSTRAINT pd_criado_despachado_intelipost_pedido_uk UNIQUE (id_pedido);
