-- =====================================================================
-- Achou: filial/pedido/item já estão corretos (text). O erro agora é
-- em "valor_pedido", que ficou como smallint (deveria ser numeric).
-- smallint não aceita decimais (ex.: 13355.32) nem valores grandes,
-- por isso o "smallint out of range" continua.
--
-- A view depende dessa coluna também, então repete o padrão: remove a
-- view, corrige o tipo, recria a view.
-- =====================================================================

DROP VIEW IF EXISTS public.vw_pedido_status_estagio;

ALTER TABLE public.pd_item_estagio
  ALTER COLUMN valor_pedido TYPE numeric USING valor_pedido::numeric;

CREATE OR REPLACE VIEW public.vw_pedido_status_estagio AS
SELECT
  filial,
  pedido,
  MIN(flag_estagio)        AS flag_estagio_atual,
  MAX(data_hora_inclusao)  AS data_hora_inclusao,
  MAX(valor_pedido)        AS valor_pedido, -- mesmo valor em todos os itens do pedido; MAX só pra agregar
  CASE
    WHEN MIN(flag_estagio) IS NULL          THEN 'OUTROS'
    WHEN MIN(flag_estagio) <= 251           THEN 'OUTROS'
    WHEN MIN(flag_estagio) IN (301,351,401) THEN 'FATURADO'
    WHEN MIN(flag_estagio) = 451            THEN 'SEPARAÇÃO'
    WHEN MIN(flag_estagio) >= 501           THEN 'SEPARADO'
    ELSE 'OUTROS'
  END AS status_resumo
FROM public.pd_item_estagio
GROUP BY filial, pedido;

-- Confirma o resultado final:
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'pd_item_estagio'
ORDER BY ordinal_position;
