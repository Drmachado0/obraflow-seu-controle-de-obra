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
