

# Corrigir acesso externo — Variáveis Supabase ausentes no deploy

## Problema
O site publicado em `construble-sync.lovable.app` mostra tela em branco porque o Supabase client falha com **"supabaseUrl is required"**. As variáveis `VITE_SUPABASE_URL` e `VITE_SUPABASE_PUBLISHABLE_KEY` existem apenas no `.env` local (usado no dev preview), mas não foram adicionadas como Secrets do projeto Lovable — por isso o build publicado não as tem.

## Solução
1. **Adicionar os dois secrets** ao projeto via ferramenta `add_secret`:
   - `VITE_SUPABASE_URL` = `https://ebyruchdswmkuynthiqi.supabase.co`
   - `VITE_SUPABASE_PUBLISHABLE_KEY` = (a anon key do seu projeto Supabase)

2. **Republicar** o projeto clicando em "Update" no diálogo de Publish para que o build use as novas variáveis.

## Observação
Os valores dessas variáveis estão no arquivo `.env` atual do projeto. Vou lê-lo e adicioná-los como secrets automaticamente na implementação.

