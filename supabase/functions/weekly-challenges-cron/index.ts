// Edge Function para gerar desafios semanais automaticamente
// Deploy: supabase functions deploy weekly-challenges-cron

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verificar autorização (apenas cron jobs ou admin)
    const authHeader = req.headers.get('Authorization')
    if (!authHeader || !authHeader.includes(Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '')) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Criar cliente Supabase
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Executar função de geração de desafios para todos os usuários
    const { error: generateError } = await supabase.rpc('generate_challenges_for_all_users')
    
    if (generateError) {
      throw generateError
    }

    // Executar limpeza de desafios antigos
    const { error: cleanupError } = await supabase.rpc('cleanup_old_challenges')
    
    if (cleanupError) {
      throw cleanupError
    }

    // Buscar estatísticas de desafios gerados
    const { data: stats, error: fetchError } = await supabase
      .from('user_weekly_challenges')
      .select('user_id', { count: 'exact' })
      .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())

    if (fetchError) {
      throw fetchError
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Desafios personalizados gerados com sucesso',
        users_processed: stats?.length || 0,
        timestamp: new Date().toISOString()
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ 
        error: error.message,
        timestamp: new Date().toISOString()
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})