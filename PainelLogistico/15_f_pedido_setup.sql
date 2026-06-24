-- =====================================================================
-- Setup da tabela f_pedido (já criada pelo usuário) para uso no ETL/n8n
-- e no dashboard.
-- =====================================================================
-- A tabela f_pedido foi criada manualmente no Supabase com os dados de
-- cabeçalho do pedido (cliente, vendedor, valores, transportadora etc.),
-- mas faltam 2 coisas pra ela funcionar igual às outras tabelas do ETL:
--
-- 1) Uma constraint UNIQUE em id_pedido — sem isso o upsert do n8n
--    (ON CONFLICT / matchingColumns) dá erro "there is no unique or
--    exclusion constraint matching the ON CONFLICT specification"
--    (mesmo erro já visto em historico_pedidos, ver 14_historico_
--    pedidos_fix_constraint.sql). O índice idx_f_pedido_id_pedido que já
--    existe é só um índice normal, não substitui a constraint UNIQUE.
--
-- 2) Uma coluna atualizado_em — usada pelo n8n pra marcar quando cada
--    linha foi processada na última rodada do ETL, e pela rotina de
--    "limpar obsoletos" (remove linhas que não vieram mais do ERP),
--    igual já é feito em pd_ultimo_estagio, mo_3104, historico_pedidos
--    etc. A coluna inserido_em (DEFAULT NOW()) que já existe só é
--    preenchida na primeira inserção, não serve pra isso.
--
-- Execute este script no SQL Editor do Supabase.
-- =====================================================================

-- 1) Coluna de controle do ETL (idempotente)
ALTER TABLE public.f_pedido
  ADD COLUMN IF NOT EXISTS atualizado_em TIMESTAMP WITH TIME ZONE;

CREATE INDEX IF NOT EXISTS idx_f_pedido_atualizado_em ON public.f_pedido(atualizado_em);

-- 2) Constraint UNIQUE em id_pedido, só se ainda não existir (seguro pra
--    rodar mais de uma vez). Mesma convenção usada nas demais tabelas
--    deste dashboard (mo_3104, pd_sem_intelipost, pd_criado_despachado_
--    intelipost): cruzamento pelo número do pedido, sem filial.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'f_pedido_id_pedido_uk'
  ) THEN
    ALTER TABLE public.f_pedido
      ADD CONSTRAINT f_pedido_id_pedido_uk
      UNIQUE (id_pedido);
  END IF;
END $$;

-- 3) RLS — somente leitura para a Anon Key (mesmo padrão das outras
--    tabelas; ver 01_rls_policies.sql, que também já foi atualizado
--    com f_pedido).
ALTER TABLE public.f_pedido ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "tv_dashboard_select_only" ON public.f_pedido;

CREATE POLICY "tv_dashboard_select_only"
  ON public.f_pedido
  FOR SELECT
  TO anon
  USING (true);

-- =====================================================================
-- Como confirmar que está correto:
-- 1. SELECT conname, contype FROM pg_constraint
--    WHERE conrelid = 'public.f_pedido'::regclass;
--    deve mostrar f_pedido_id_pedido_uk com contype = 'u'.
-- 2. Em Authentication > Policies, f_pedido deve aparecer com RLS
--    "Enabled" e 1 policy de SELECT para anon.
-- =====================================================================
