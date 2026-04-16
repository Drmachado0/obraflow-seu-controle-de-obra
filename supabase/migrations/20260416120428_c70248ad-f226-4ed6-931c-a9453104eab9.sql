
-- =============================================
-- ObraFlow: Full Schema Migration
-- =============================================

-- 1. obra_config
CREATE TABLE public.obra_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nome_obra TEXT NOT NULL DEFAULT 'Minha Obra',
  orcamento_total NUMERIC NOT NULL DEFAULT 0,
  area_construida NUMERIC NOT NULL DEFAULT 0,
  data_inicio DATE,
  data_termino DATE,
  responsavel TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.obra_config ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own config" ON public.obra_config FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 2. obra_contas_financeiras
CREATE TABLE public.obra_contas_financeiras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  tipo TEXT NOT NULL DEFAULT 'Banco',
  saldo_inicial NUMERIC NOT NULL DEFAULT 0,
  cor TEXT NOT NULL DEFAULT '#3B82F6',
  ativa BOOLEAN NOT NULL DEFAULT true,
  observacoes TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.obra_contas_financeiras ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own contas" ON public.obra_contas_financeiras FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 3. obra_transacoes_fluxo
CREATE TABLE public.obra_transacoes_fluxo (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tipo TEXT NOT NULL CHECK (tipo IN ('Entrada', 'Saída')),
  valor NUMERIC NOT NULL DEFAULT 0,
  data DATE NOT NULL DEFAULT CURRENT_DATE,
  categoria TEXT NOT NULL DEFAULT '',
  descricao TEXT DEFAULT '',
  forma_pagamento TEXT DEFAULT '',
  observacoes TEXT DEFAULT '',
  origem_tipo TEXT,
  origem_id TEXT,
  conciliado BOOLEAN DEFAULT false,
  conciliado_em TIMESTAMPTZ,
  recorrencia TEXT DEFAULT 'Única',
  referencia TEXT DEFAULT '',
  conta_id TEXT DEFAULT '',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.obra_transacoes_fluxo ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own transacoes" ON public.obra_transacoes_fluxo FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 4. obra_compras
CREATE TABLE public.obra_compras (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fornecedor TEXT DEFAULT '',
  descricao TEXT DEFAULT '',
  categoria TEXT DEFAULT 'Material',
  valor_total NUMERIC NOT NULL DEFAULT 0,
  data DATE NOT NULL DEFAULT CURRENT_DATE,
  status_entrega TEXT DEFAULT 'Pedido',
  forma_pagamento TEXT DEFAULT 'PIX',
  numero_parcelas INT DEFAULT 1,
  parcelas JSONB DEFAULT '[]',
  observacoes TEXT DEFAULT '',
  nf_vinculada TEXT,
  conta_id TEXT DEFAULT '',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.obra_compras ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own compras" ON public.obra_compras FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 5. obra_comissao_pagamentos
CREATE TABLE public.obra_comissao_pagamentos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  mes TEXT DEFAULT '',
  valor NUMERIC NOT NULL DEFAULT 0,
  pago BOOLEAN DEFAULT false,
  data_pagamento TIMESTAMPTZ,
  observacoes TEXT DEFAULT '',
  auto BOOLEAN DEFAULT false,
  categoria TEXT DEFAULT '',
  fornecedor TEXT DEFAULT '',
  forma_pagamento TEXT DEFAULT '',
  transacao_id UUID,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.obra_comissao_pagamentos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own comissoes" ON public.obra_comissao_pagamentos FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 6. obra_notas_fiscais
CREATE TABLE public.obra_notas_fiscais (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  numero TEXT DEFAULT '',
  fornecedor TEXT DEFAULT '',
  descricao TEXT DEFAULT '',
  categoria TEXT DEFAULT '',
  valor_bruto NUMERIC DEFAULT 0,
  valor_liquido NUMERIC DEFAULT 0,
  data_emissao DATE,
  data_vencimento DATE,
  status TEXT DEFAULT 'Pendente',
  forma_pagamento TEXT DEFAULT '',
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.obra_notas_fiscais ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own nfs" ON public.obra_notas_fiscais FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 7. obra_cronograma
CREATE TABLE public.obra_cronograma (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  custo_previsto NUMERIC DEFAULT 0,
  custo_real NUMERIC DEFAULT 0,
  inicio_previsto DATE,
  fim_previsto DATE,
  status TEXT DEFAULT 'Pendente',
  percentual_conclusao NUMERIC DEFAULT 0,
  observacoes TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.obra_cronograma ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own cronograma" ON public.obra_cronograma FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 8. obra_documentos_processados
CREATE TABLE public.obra_documentos_processados (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nome_arquivo TEXT NOT NULL,
  tipo_arquivo TEXT DEFAULT '',
  origem_arquivo TEXT DEFAULT 'upload',
  caminho_origem TEXT DEFAULT '',
  hash_arquivo TEXT DEFAULT '',
  status_processamento TEXT DEFAULT 'pendente',
  tipo_documento TEXT DEFAULT '',
  confianca_extracao NUMERIC DEFAULT 0,
  payload_bruto JSONB,
  payload_normalizado JSONB,
  motivo_erro TEXT DEFAULT '',
  motivo_revisao TEXT DEFAULT '',
  duplicidade_status TEXT DEFAULT 'unico',
  duplicidade_score NUMERIC DEFAULT 0,
  documento_relacionado_id UUID,
  storage_path TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.obra_documentos_processados ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own documentos" ON public.obra_documentos_processados FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 9. obra_movimentacoes_extraidas
CREATE TABLE public.obra_movimentacoes_extraidas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  documento_id UUID REFERENCES public.obra_documentos_processados(id) ON DELETE CASCADE,
  data_movimentacao DATE,
  descricao TEXT DEFAULT '',
  valor NUMERIC NOT NULL DEFAULT 0,
  tipo_movimentacao TEXT DEFAULT '',
  saldo NUMERIC,
  categoria_sugerida TEXT DEFAULT '',
  score_confianca NUMERIC DEFAULT 0,
  score_duplicidade NUMERIC DEFAULT 0,
  status_revisao TEXT DEFAULT 'pendente',
  transacao_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.obra_movimentacoes_extraidas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own movimentacoes" ON public.obra_movimentacoes_extraidas FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 10. obra_eventos_processamento
CREATE TABLE public.obra_eventos_processamento (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  documento_id UUID REFERENCES public.obra_documentos_processados(id) ON DELETE CASCADE,
  etapa TEXT NOT NULL,
  status TEXT NOT NULL,
  mensagem TEXT DEFAULT '',
  detalhes JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.obra_eventos_processamento ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own eventos_proc" ON public.obra_eventos_processamento FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 11. obra_conciliacoes_bancarias
CREATE TABLE public.obra_conciliacoes_bancarias (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  movimentacao_extraida_id UUID REFERENCES public.obra_movimentacoes_extraidas(id),
  transacao_id UUID,
  status_conciliacao TEXT DEFAULT 'pendente',
  score_compatibilidade NUMERIC DEFAULT 0,
  tipo_conciliacao TEXT DEFAULT '',
  motivo_matching TEXT DEFAULT '',
  observacoes TEXT DEFAULT '',
  conciliado_por TEXT,
  conciliado_em TIMESTAMPTZ,
  desfeito_por TEXT,
  desfeito_em TIMESTAMPTZ,
  motivo_desfazer TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.obra_conciliacoes_bancarias ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own conciliacoes" ON public.obra_conciliacoes_bancarias FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 12. obra_sugestoes_conciliacao
CREATE TABLE public.obra_sugestoes_conciliacao (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  movimentacao_extraida_id UUID REFERENCES public.obra_movimentacoes_extraidas(id),
  transacao_id UUID,
  score_compatibilidade NUMERIC DEFAULT 0,
  motivo_matching TEXT DEFAULT '',
  status_sugestao TEXT DEFAULT 'pendente',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.obra_sugestoes_conciliacao ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own sugestoes" ON public.obra_sugestoes_conciliacao FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 13. obra_eventos_conciliacao
CREATE TABLE public.obra_eventos_conciliacao (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  conciliacao_id UUID REFERENCES public.obra_conciliacoes_bancarias(id),
  tipo_evento TEXT DEFAULT '',
  detalhes TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.obra_eventos_conciliacao ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own eventos_conc" ON public.obra_eventos_conciliacao FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 14. obra_notificacoes
CREATE TABLE public.obra_notificacoes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tipo TEXT DEFAULT '',
  titulo TEXT DEFAULT '',
  mensagem TEXT DEFAULT '',
  status TEXT DEFAULT 'nao_lida',
  prioridade TEXT DEFAULT 'normal',
  link TEXT DEFAULT '',
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.obra_notificacoes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own notificacoes" ON public.obra_notificacoes FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 15. obra_audit_log
CREATE TABLE public.obra_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  user_email TEXT DEFAULT '',
  acao TEXT NOT NULL,
  tabela TEXT NOT NULL,
  registro_id TEXT DEFAULT '',
  dados_anteriores JSONB,
  dados_novos JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.obra_audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users read own audit" ON public.obra_audit_log FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own audit" ON public.obra_audit_log FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 16. obra_funcionarios
CREATE TABLE public.obra_funcionarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  funcao TEXT DEFAULT '',
  telefone TEXT DEFAULT '',
  salario_diario NUMERIC DEFAULT 0,
  status TEXT DEFAULT 'ativo',
  observacoes TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.obra_funcionarios ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own funcionarios" ON public.obra_funcionarios FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 17. obra_medicoes
CREATE TABLE public.obra_medicoes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  data DATE NOT NULL,
  descricao TEXT DEFAULT '',
  percentual_geral NUMERIC DEFAULT 0,
  valor_total_medido NUMERIC DEFAULT 0,
  itens JSONB DEFAULT '[]',
  observacoes TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.obra_medicoes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own medicoes" ON public.obra_medicoes FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 18. obra_diario
CREATE TABLE public.obra_diario (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  data DATE NOT NULL,
  clima TEXT DEFAULT 'Ensolarado',
  atividades TEXT DEFAULT '',
  problemas TEXT DEFAULT '',
  observacoes TEXT DEFAULT '',
  avanco_percentual NUMERIC DEFAULT 0,
  equipes TEXT[] DEFAULT '{}',
  etapas_trabalhadas TEXT[] DEFAULT '{}',
  fotos TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.obra_diario ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own diario" ON public.obra_diario FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- =============================================
-- RPC: pagar_nf_atomica
-- =============================================
CREATE OR REPLACE FUNCTION public.pagar_nf_atomica(
  p_nf_id UUID,
  p_conta_id UUID,
  p_metodo TEXT,
  p_transacao JSONB,
  p_comissao JSONB
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_valor NUMERIC;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Verify NF belongs to user
  SELECT valor_liquido INTO v_valor FROM obra_notas_fiscais WHERE id = p_nf_id AND user_id = v_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'NF not found or not owned';
  END IF;

  -- Update NF status
  UPDATE obra_notas_fiscais SET status = 'Paga', forma_pagamento = p_metodo, updated_at = now() WHERE id = p_nf_id;

  -- Create transaction
  INSERT INTO obra_transacoes_fluxo (user_id, tipo, valor, data, categoria, descricao, forma_pagamento, observacoes, recorrencia, referencia, conta_id, origem_tipo, origem_id)
  VALUES (
    v_user_id,
    'Saída',
    (p_transacao->>'valor')::NUMERIC,
    CURRENT_DATE,
    p_transacao->>'categoria',
    p_transacao->>'descricao',
    p_transacao->>'forma_pagamento',
    p_transacao->>'observacoes',
    'Única',
    '',
    p_conta_id::TEXT,
    'nf',
    p_nf_id::TEXT
  );

  -- Create commission
  INSERT INTO obra_comissao_pagamentos (user_id, mes, valor, pago, observacoes, auto, categoria, fornecedor, forma_pagamento)
  VALUES (
    v_user_id,
    p_comissao->>'mes',
    (p_comissao->>'valor')::NUMERIC,
    false,
    COALESCE(p_comissao->>'observacoes', ''),
    true,
    COALESCE(p_comissao->>'categoria', ''),
    COALESCE(p_comissao->>'fornecedor', ''),
    COALESCE(p_comissao->>'forma_pagamento', '')
  );
END;
$$;

-- =============================================
-- Timestamp update trigger function
-- =============================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Apply updated_at triggers
CREATE TRIGGER update_obra_config_updated_at BEFORE UPDATE ON public.obra_config FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_obra_contas_updated_at BEFORE UPDATE ON public.obra_contas_financeiras FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_obra_transacoes_updated_at BEFORE UPDATE ON public.obra_transacoes_fluxo FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_obra_compras_updated_at BEFORE UPDATE ON public.obra_compras FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_obra_comissao_updated_at BEFORE UPDATE ON public.obra_comissao_pagamentos FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_obra_nfs_updated_at BEFORE UPDATE ON public.obra_notas_fiscais FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_obra_cronograma_updated_at BEFORE UPDATE ON public.obra_cronograma FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_obra_docs_updated_at BEFORE UPDATE ON public.obra_documentos_processados FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_obra_conciliacoes_updated_at BEFORE UPDATE ON public.obra_conciliacoes_bancarias FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_obra_funcionarios_updated_at BEFORE UPDATE ON public.obra_funcionarios FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_obra_medicoes_updated_at BEFORE UPDATE ON public.obra_medicoes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_obra_diario_updated_at BEFORE UPDATE ON public.obra_diario FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- =============================================
-- Storage bucket for documents
-- =============================================
INSERT INTO storage.buckets (id, name, public) VALUES ('documentos', 'documentos', false) ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Users upload own docs" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'documentos' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users read own docs" ON storage.objects FOR SELECT USING (bucket_id = 'documentos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Enable realtime for key tables
ALTER PUBLICATION supabase_realtime ADD TABLE obra_config, obra_transacoes_fluxo, obra_compras, obra_comissao_pagamentos, obra_contas_financeiras, obra_cronograma, obra_notas_fiscais, obra_notificacoes, obra_audit_log, obra_funcionarios, obra_medicoes, obra_diario, obra_documentos_processados, obra_movimentacoes_extraidas;
