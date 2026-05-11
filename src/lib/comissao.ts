export const PERCENTUAL_COMISSAO_CONSTRUTOR = 8;

export interface BuildComissaoPendenteInput {
  userId: string;
  transacaoId: string;
  data: string;
  valorBase: number;
  descricao?: string;
  categoria?: string;
  fornecedor?: string;
  formaPagamento?: string;
  documentoId?: string;
}

export interface ComissaoPendenteInsert {
  user_id: string;
  transacao_id: string;
  mes: string;
  valor: number;
  pago: boolean;
  auto: boolean;
  categoria: string;
  fornecedor: string;
  forma_pagamento: string;
  observacoes: string;
}

export interface TransacaoComComissaoInsert {
  user_id: string;
  tipo: string;
  valor: number;
  data: string;
  categoria?: string | null;
  descricao?: string | null;
  forma_pagamento?: string | null;
  observacoes?: string | null;
  [key: string]: unknown;
}

type SupabaseInsertResult = PromiseLike<{ error: unknown | null }> & {
  select: (columns: string) => {
    single: () => Promise<{ data: unknown; error: unknown | null }>;
  };
};

type SupabaseTable = {
  insert: (payload: unknown) => SupabaseInsertResult;
};

export interface RegistrarTransacaoComComissaoInput {
  supabase: {
    from: (table: string) => SupabaseTable;
  };
  transacao: TransacaoComComissaoInsert;
  fornecedor?: string;
  documentoId?: string;
  gerarComissao?: boolean;
}

export interface RegistrarTransacaoComComissaoResult {
  transacao: { id: string } | null;
  comissao: ComissaoPendenteInsert | null;
  transacaoError: unknown | null;
  comissaoError: unknown | null;
}

function roundCurrency(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

export function buildComissaoPendente(input: BuildComissaoPendenteInput): ComissaoPendenteInsert {
  const descricao = input.descricao?.trim() || "Despesa da obra";
  const documentoRef = input.documentoId ? ` | Doc: ${input.documentoId}` : "";

  return {
    user_id: input.userId,
    transacao_id: input.transacaoId,
    mes: input.data.slice(0, 7),
    valor: roundCurrency(input.valorBase * (PERCENTUAL_COMISSAO_CONSTRUTOR / 100)),
    pago: false,
    auto: true,
    categoria: input.categoria || "Outro",
    fornecedor: input.fornecedor || "",
    forma_pagamento: input.formaPagamento || "",
    observacoes: `Auto 8% - ${descricao}${documentoRef}`,
  };
}

export function deveGerarComissao(transacao: Pick<TransacaoComComissaoInsert, "tipo" | "valor">): boolean {
  return transacao.tipo === "Saída" && Number(transacao.valor) > 0;
}

export async function registrarTransacaoComComissao({
  supabase,
  transacao,
  fornecedor,
  documentoId,
  gerarComissao = true,
}: RegistrarTransacaoComComissaoInput): Promise<RegistrarTransacaoComComissaoResult> {
  const { data, error } = await supabase
    .from("obra_transacoes_fluxo")
    .insert(transacao)
    .select("id")
    .single();

  if (error || !data) {
    return {
      transacao: null,
      comissao: null,
      transacaoError: error || new Error("Transação não retornada"),
      comissaoError: null,
    };
  }

  const inserted = data as { id: string };
  if (!gerarComissao || !deveGerarComissao(transacao)) {
    return {
      transacao: inserted,
      comissao: null,
      transacaoError: null,
      comissaoError: null,
    };
  }

  const comissao = buildComissaoPendente({
    userId: transacao.user_id,
    transacaoId: inserted.id,
    data: transacao.data,
    valorBase: Number(transacao.valor),
    descricao: typeof transacao.descricao === "string" ? transacao.descricao : "",
    categoria: typeof transacao.categoria === "string" ? transacao.categoria : undefined,
    fornecedor,
    formaPagamento: typeof transacao.forma_pagamento === "string" ? transacao.forma_pagamento : undefined,
    documentoId,
  });

  const { error: comissaoError } = await supabase
    .from("obra_comissao_pagamentos")
    .insert(comissao);

  return {
    transacao: inserted,
    comissao: comissaoError ? null : comissao,
    transacaoError: null,
    comissaoError: comissaoError || null,
  };
}
