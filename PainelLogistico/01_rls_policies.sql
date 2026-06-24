-- =====================================================================
-- RLS (Row Level Security) somente-leitura para o TV Dashboard
-- =====================================================================
-- Objetivo: permitir que a Anon Key do Supabase (exposta no frontend)
-- consiga apenas LER (SELECT) estas 3 tabelas, e NUNCA inserir, alterar
-- ou apagar dados. Isso é o que torna seguro colocar a Anon Key direto
-- no código do dashboard que vai rodar na TV.
--
-- Execute este script no SQL Editor do Supabase (Database > SQL Editor).
-- =====================================================================

-- 1) Habilita RLS nas 3 tabelas (se RLS não estiver habilitado, a policy
--    abaixo não tem efeito e a tabela continua com acesso conforme as
--    permissões padrão do schema).
ALTER TABLE public.pd_ultimo_estagio              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mo_3104                        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.etl_controle                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pd_sem_intelipost               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pd_criado_despachado_intelipost ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pd_item_estagio                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.historico_pedidos               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.f_pedido                        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.f_faturamento_hist7              ENABLE ROW LEVEL SECURITY;

-- 2) Remove policies antigas com o mesmo nome, caso você rode este
--    script novamente (evita erro de "policy already exists").
DROP POLICY IF EXISTS "tv_dashboard_select_only" ON public.pd_ultimo_estagio;
DROP POLICY IF EXISTS "tv_dashboard_select_only" ON public.mo_3104;
DROP POLICY IF EXISTS "tv_dashboard_select_only" ON public.etl_controle;
DROP POLICY IF EXISTS "tv_dashboard_select_only" ON public.pd_sem_intelipost;
DROP POLICY IF EXISTS "tv_dashboard_select_only" ON public.pd_criado_despachado_intelipost;
DROP POLICY IF EXISTS "tv_dashboard_select_only" ON public.pd_item_estagio;
DROP POLICY IF EXISTS "tv_dashboard_select_only" ON public.historico_pedidos;
DROP POLICY IF EXISTS "tv_dashboard_select_only" ON public.f_pedido;
DROP POLICY IF EXISTS "tv_dashboard_select_only" ON public.f_faturamento_hist7;

-- 3) Cria a policy de leitura pública (role "anon" = Anon Key) somente
--    para SELECT. Não existe policy de INSERT/UPDATE/DELETE para "anon",
--    então essas operações continuam bloqueadas por padrão.
CREATE POLICY "tv_dashboard_select_only"
  ON public.pd_ultimo_estagio
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "tv_dashboard_select_only"
  ON public.mo_3104
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "tv_dashboard_select_only"
  ON public.etl_controle
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "tv_dashboard_select_only"
  ON public.pd_sem_intelipost
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "tv_dashboard_select_only"
  ON public.pd_criado_despachado_intelipost
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "tv_dashboard_select_only"
  ON public.pd_item_estagio
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "tv_dashboard_select_only"
  ON public.historico_pedidos
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "tv_dashboard_select_only"
  ON public.f_pedido
  FOR SELECT
  TO anon
  USING (true);

CREATE POLICY "tv_dashboard_select_only"
  ON public.f_faturamento_hist7
  FOR SELECT
  TO anon
  USING (true);

-- A view vw_pedido_status_estagio (criada em 06_pd_item_estagio_schema.sql)
-- já recebe GRANT SELECT direto pra "anon" naquele script — views não
-- usam policy de RLS, usam GRANT no próprio objeto.

-- =====================================================================
-- Como confirmar que está correto:
-- 1. Em Supabase > Authentication > Policies, cada uma das 3 tabelas
--    deve aparecer com RLS "Enabled" e 1 policy do tipo SELECT para anon.
-- 2. Teste no SQL Editor: SELECT * FROM pd_ultimo_estagio; (com seu
--    usuário admin) continua funcionando normalmente.
-- 3. Teste real: usando a Anon Key + supabase-js no navegador, um
--    SELECT funciona, mas um INSERT/UPDATE/DELETE retorna erro de
--    permissão (RLS policy violation). Isso é o esperado e desejado.
-- =====================================================================
