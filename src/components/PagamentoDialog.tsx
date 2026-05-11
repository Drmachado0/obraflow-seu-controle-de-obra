import { useState, useEffect } from "react";
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { supabase } from "@/integrations/supabase/client";
import { formatCurrency } from "@/lib/formatters";
import { toast } from "sonner";
import { Upload, Loader2, CreditCard, Wallet, Receipt } from "lucide-react";
import { PERCENTUAL_COMISSAO_CONSTRUTOR, registrarTransacaoComComissao } from "@/lib/comissao";

interface PagamentoDialogProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
  tipo: "nf" | "compra";
  id: string;
  fornecedor: string;
  valor: number;
  categoria: string;
  descricao?: string;
  userId: string;
}

interface ContaFinanceira {
  id: string;
  nome: string;
  tipo: string;
  cor: string;
}

export default function PagamentoDialog({
  open, onClose, onSuccess, tipo, id, fornecedor, valor, categoria, descricao, userId,
}: PagamentoDialogProps) {
  const [contas, setContas] = useState<ContaFinanceira[]>([]);
  const [contaId, setContaId] = useState("");
  const [metodo, setMetodo] = useState("PIX");
  const [arquivo, setArquivo] = useState<File | null>(null);
  const [gerarComissao, setGerarComissao] = useState(true);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!open) return;
    supabase
      .from("obra_contas_financeiras")
      .select("id, nome, tipo, cor")
      .eq("user_id", userId)
      .eq("ativa", true)
      .then(({ data }) => {
        if (data) {
          setContas(data);
          if (data.length === 1) setContaId(data[0].id);
        }
      });
  }, [open, userId]);

  const hoje = new Date().toISOString().slice(0, 10);
  const comissaoValor = valor * (PERCENTUAL_COMISSAO_CONSTRUTOR / 100);

  const handleConfirmar = async () => {
    if (!contaId) {
      toast.error("Selecione uma conta");
      return;
    }
    setLoading(true);
    try {
      let storagePath = "";

      // Upload receipt if provided
      if (arquivo) {
        const ext = arquivo.name.split(".").pop();
        const path = `${userId}/recibos/${id}/${Date.now()}.${ext}`;
        const { error: uploadErr } = await supabase.storage
          .from("documentos")
          .upload(path, arquivo);
        if (uploadErr) throw new Error("Erro ao enviar recibo: " + uploadErr.message);
        storagePath = path;
      }

      if (tipo === "nf") {
        if (gerarComissao) {
          // Use the atomic RPC when commission should be created together with the payment
          const mes = new Date().toISOString().slice(0, 7);
          const { error } = await supabase.rpc("pagar_nf_atomica", {
            p_nf_id: id,
            p_conta_id: contaId,
            p_metodo: metodo,
            p_transacao: {
              descricao: `NF ${descricao || fornecedor}`,
              categoria,
              valor,
              forma_pagamento: metodo,
              observacoes: `Fornecedor: ${fornecedor}`,
            },
            p_comissao: {
              mes,
              valor: comissaoValor,
              pago: false,
              observacoes: `Comissão automática NF - ${fornecedor}`,
            },
          });
          if (error) throw error;
        } else {
          const referencia = `NF-${id}`;
          const { data: existente } = await supabase
            .from("obra_transacoes_fluxo")
            .select("id")
            .eq("user_id", userId)
            .eq("referencia", referencia)
            .is("deleted_at", null)
            .maybeSingle();

          if (existente?.id) throw new Error("Esta nota fiscal já possui lançamento no fluxo de caixa");

          const { transacaoError } = await registrarTransacaoComComissao({
            supabase,
            fornecedor,
            gerarComissao: false,
            transacao: {
              user_id: userId,
              tipo: "Saída",
              valor,
              data: hoje,
              categoria,
              descricao: `NF ${descricao || fornecedor}`,
              forma_pagamento: metodo,
              conta_id: contaId,
              recorrencia: "Única",
              referencia,
              observacoes: `Fornecedor: ${fornecedor} | Sem comissão por opção do usuário`,
              origem_tipo: "nf",
              origem_id: id,
            },
          });
          if (transacaoError) throw transacaoError;
          await supabase
            .from("obra_notas_fiscais")
            .update({ status: "Paga", forma_pagamento: metodo })
            .eq("id", id);
        }
      } else {
        // Para compras, o caixa nasce no pagamento (não no cadastro), com idempotência por referência.
        const referencia = `COMPRA-${id}`;
        const { data: existente } = await supabase
          .from("obra_transacoes_fluxo")
          .select("id")
          .eq("user_id", userId)
          .eq("referencia", referencia)
          .is("deleted_at", null)
          .maybeSingle();

        if (existente?.id) throw new Error("Esta compra já possui lançamento no fluxo de caixa");

        const { transacaoError, comissaoError } = await registrarTransacaoComComissao({
          supabase,
          fornecedor,
          gerarComissao,
          transacao: {
            user_id: userId,
            tipo: "Saída",
            valor,
            data: hoje,
            categoria,
            descricao: `Compra - ${descricao || fornecedor}`,
            forma_pagamento: metodo,
            conta_id: contaId,
            recorrencia: "Única",
            referencia,
            observacoes: `Fornecedor: ${fornecedor}${gerarComissao ? "" : " | Sem comissão por opção do usuário"}`,
            origem_tipo: "compra",
            origem_id: id,
          },
        });
        if (transacaoError) throw transacaoError;
        if (gerarComissao && comissaoError) toast.warning("Pagamento registrado, mas houve erro ao criar comissão automática");

        // Update compra status
        await supabase
          .from("obra_compras")
          .update({ status_entrega: "Entregue" })
          .eq("id", id);
      }

      // Register receipt as processed document in Pasta Sync
      if (storagePath && arquivo) {
        await supabase.from("obra_documentos_processados").insert({
          user_id: userId,
          nome_arquivo: arquivo.name,
          tipo_arquivo: arquivo.type || "application/pdf",
          storage_path: storagePath,
          caminho_origem: storagePath,
          hash_arquivo: `${id}-${Date.now()}`,
          status_processamento: "processado",
          tipo_documento: "recibo",
          confianca_extracao: 100,
          origem_arquivo: "pagamento",
          payload_normalizado: {
            tipo_documento: "recibo",
            fornecedor_ou_origem: fornecedor,
            valor_total: valor,
            descricao: `Recibo de pagamento - ${descricao || fornecedor}`,
            data_documento: hoje,
            categoria,
            metodo_pagamento: metodo,
          },
        });
      }

      toast.success("Pagamento registrado com sucesso!");
      setArquivo(null);
      setContaId("");
      setMetodo("PIX");
      setGerarComissao(true);
      onSuccess();
      onClose();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Erro ao registrar pagamento");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={(v) => !v && onClose()}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <CreditCard className="w-5 h-5 text-primary" />
            Confirmar Pagamento
          </DialogTitle>
          <DialogDescription>
            Registre o pagamento e anexe o comprovante
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          {/* Summary */}
          <div className="p-3 rounded-lg bg-secondary/50 border border-border space-y-1.5 min-w-0">
            <div className="flex flex-col gap-0.5 sm:flex-row sm:justify-between text-sm">
              <span className="text-muted-foreground">Fornecedor</span>
              <span className="font-medium break-words sm:text-right">{fornecedor}</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-muted-foreground">Valor</span>
              <span className="font-bold text-lg">{formatCurrency(valor)}</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-muted-foreground">Comissão (8%)</span>
              <Badge variant="outline" className="text-xs">{gerarComissao ? formatCurrency(comissaoValor) : "Não gerar"}</Badge>
            </div>
            {categoria && (
              <div className="flex justify-between text-sm">
                <span className="text-muted-foreground">Categoria</span>
                <span>{categoria}</span>
              </div>
            )}
          </div>

          {/* Conta */}
          <div className="space-y-1.5">
            <Label className="text-xs">Conta de débito</Label>
            <Select value={contaId} onValueChange={setContaId}>
              <SelectTrigger>
                <SelectValue placeholder="Selecione a conta" />
              </SelectTrigger>
              <SelectContent>
                {contas.map((c) => (
                  <SelectItem key={c.id} value={c.id}>
                    <div className="flex items-center gap-2">
                      <div className="w-2 h-2 rounded-full" style={{ background: c.cor || "#3B82F6" }} />
                      {c.nome} ({c.tipo})
                    </div>
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {/* Método */}
          <div className="space-y-1.5">
            <Label className="text-xs">Forma de pagamento</Label>
            <Select value={metodo} onValueChange={setMetodo}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="PIX"><div className="flex items-center gap-2"><Wallet className="w-3 h-3" />PIX</div></SelectItem>
                <SelectItem value="Cartão"><div className="flex items-center gap-2"><CreditCard className="w-3 h-3" />Cartão</div></SelectItem>
                <SelectItem value="Boleto"><div className="flex items-center gap-2"><Receipt className="w-3 h-3" />Boleto</div></SelectItem>
                <SelectItem value="Transferência">Transferência</SelectItem>
                <SelectItem value="Dinheiro">Dinheiro</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <label className="flex items-start gap-3 rounded-lg border border-border/60 bg-secondary/30 p-3 text-sm">
            <input
              type="checkbox"
              checked={gerarComissao}
              onChange={(e) => setGerarComissao(e.target.checked)}
              className="mt-1 h-4 w-4 accent-primary"
            />
            <span>
              <span className="font-medium">Gerar comissão automática de 8%</span>
              <span className="block text-xs text-muted-foreground">
                Desmarque para registrar o pagamento apenas nos gastos, sem comissão do construtor.
              </span>
            </span>
          </label>

          {/* Receipt upload */}
          <div className="space-y-1.5">
            <Label className="text-xs">Comprovante / Recibo (opcional)</Label>
            <div className="relative">
              <Input
                type="file"
                accept="image/*,application/pdf"
                onChange={(e) => setArquivo(e.target.files?.[0] || null)}
                className="text-xs"
              />
              {arquivo && (
                <p className="text-xs text-muted-foreground mt-1">
                  <Upload className="w-3 h-3 inline mr-1" />
                  {arquivo.name} — será salvo na Pasta Sync como recibo
                </p>
              )}
            </div>
          </div>
        </div>

        <DialogFooter className="gap-2 sm:gap-0">
          <Button variant="outline" onClick={onClose} disabled={loading} className="w-full sm:w-auto">
            Cancelar
          </Button>
          <Button onClick={handleConfirmar} disabled={loading} className="w-full sm:w-auto">
            {loading ? <Loader2 className="w-4 h-4 animate-spin mr-1" /> : <CreditCard className="w-4 h-4 mr-1" />}
            Confirmar Pagamento
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
