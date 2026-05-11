import { describe, it, expect } from "vitest";
import { buildComissaoPendente, deveGerarComissao, registrarTransacaoComComissao } from "@/lib/comissao";

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

describe("deveGerarComissao", () => {
  it("gera comissão apenas para saída positiva", () => {
    expect(deveGerarComissao({ tipo: "Saída", valor: 100 })).toBe(true);
    expect(deveGerarComissao({ tipo: "Entrada", valor: 100 })).toBe(false);
    expect(deveGerarComissao({ tipo: "Saída", valor: 0 })).toBe(false);
  });
});

describe("registrarTransacaoComComissao", () => {
  function mockSupabase() {
    const calls: Array<{ table: string; payload: unknown }> = [];
    return {
      calls,
      supabase: {
        from(table: string) {
          return {
            insert(payload: unknown) {
              calls.push({ table, payload });
              if (table === "obra_transacoes_fluxo") {
                return {
                  select() {
                    return {
                      single: async () => ({ data: { id: "tx-1" }, error: null }),
                    };
                  },
                };
              }
              return Promise.resolve({ error: null });
            },
          };
        },
      },
    };
  }

  it("insere a transação e a comissão automática para saída", async () => {
    const { supabase, calls } = mockSupabase();

    const result = await registrarTransacaoComComissao({
      supabase,
      fornecedor: "Depósito Central",
      transacao: {
        user_id: "user-1",
        tipo: "Saída",
        valor: 500,
        data: "2026-05-11",
        categoria: "Material",
        descricao: "Compra cimento",
        forma_pagamento: "PIX",
      },
    });

    expect(result.transacao).toEqual({ id: "tx-1" });
    expect(result.comissao?.valor).toBe(40);
    expect(calls.map(c => c.table)).toEqual(["obra_transacoes_fluxo", "obra_comissao_pagamentos"]);
  });

  it("não cria comissão para entrada", async () => {
    const { supabase, calls } = mockSupabase();

    const result = await registrarTransacaoComComissao({
      supabase,
      transacao: {
        user_id: "user-1",
        tipo: "Entrada",
        valor: 500,
        data: "2026-05-11",
      },
    });

    expect(result.transacao).toEqual({ id: "tx-1" });
    expect(result.comissao).toBeNull();
    expect(calls.map(c => c.table)).toEqual(["obra_transacoes_fluxo"]);
  });

  it("mantém a saída nos gastos sem criar comissão quando o usuário excluir", async () => {
    const { supabase, calls } = mockSupabase();

    const result = await registrarTransacaoComComissao({
      supabase,
      gerarComissao: false,
      transacao: {
        user_id: "user-1",
        tipo: "Saída",
        valor: 500,
        data: "2026-05-11",
        descricao: "Despesa sem comissão",
      },
    });

    expect(result.transacao).toEqual({ id: "tx-1" });
    expect(result.comissao).toBeNull();
    expect(calls.map(c => c.table)).toEqual(["obra_transacoes_fluxo"]);
  });
});
