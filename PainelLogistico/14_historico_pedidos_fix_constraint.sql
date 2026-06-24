-- =====================================================================
-- Corrige a falta da constraint UNIQUE em historico_pedidos.
-- =====================================================================
-- Erro no n8n: "there is no unique or exclusion constraint matching the
-- ON CONFLICT specification". Causa: a tabela historico_pedidos já
-- existia no Supabase (de alguma tentativa anterior) sem a constraint
-- UNIQUE (filial, pedido, sequencia). O CREATE TABLE IF NOT EXISTS do
-- 13_historico_pedidos_schema.sql não altera uma tabela já existente,
-- por isso a constraint nunca foi criada.
--
-- Este script adiciona a constraint só se ela ainda não existir
-- (seguro pra rodar mais de uma vez).
-- =====================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'historico_pedidos_filial_pedido_sequencia_uk'
  ) THEN
    ALTER TABLE public.historico_pedidos
      ADD CONSTRAINT historico_pedidos_filial_pedido_sequencia_uk
      UNIQUE (filial, pedido, sequencia);
  END IF;
END $$;

-- Confirma as constraints da tabela:
SELECT conname, contype
FROM pg_constraint
WHERE conrelid = 'public.historico_pedidos'::regclass;
