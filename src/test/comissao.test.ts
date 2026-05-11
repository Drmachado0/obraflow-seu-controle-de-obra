import { describe, it, expect } from "vitest";
import { buildComissaoPendente } from "@/lib/comissao";

describe("buildComissaoPendente", () => {
  it("cria comissão pendente de 8% vinculada a uma saída da obra", () => {
    const result = buildComissaoPendente({
      userId: "user-1",
      transacaoId: "tx-1",
      data: "2026-05-10",
      valorBase: 1250,
      descricao: "Compra cimento CP-II",
      categoria: "Material",
      fornecedor: "Depósito Central",
      formaPagamento: "PIX",
      documentoId: "doc-1",
    });

    expect(result).toEqual({
      user_id: "user-1",
      transacao_id: "tx-1",
      mes: "2026-05",
      valor: 100,
      pago: false,
      auto: true,
      categoria: "Material",
      fornecedor: "Depósito Central",
      forma_pagamento: "PIX",
      observacoes: "Auto 8% - Compra cimento CP-II | Doc: doc-1",
    });
  });

  it("arredonda comissão para centavos", () => {
    const result = buildComissaoPendente({
      userId: "user-1",
      transacaoId: "tx-1",
      data: "2026-05-10",
      valorBase: 333.33,
      descricao: "Recibo mão de obra",
      categoria: "Mão de Obra",
    });

    expect(result.valor).toBe(26.67);
  });
});
