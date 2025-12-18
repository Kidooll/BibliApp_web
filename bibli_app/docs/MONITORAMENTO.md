# Sistema de Monitoramento BibliApp - 100% Gratuito

## 🎯 Visão Geral

Sistema de monitoramento completo usando **apenas ferramentas gratuitas**:
- **Sentry** (gratuito até 5k eventos/mês) - Crash reporting
- **Supabase** (já usado no projeto) - Analytics customizados
- **Logs locais** - Debug e desenvolvimento

## 🔧 Arquitetura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   BibliApp      │───▶│  MonitoringService │───▶│    Sentry       │
│   (Flutter)     │    │   (Centralizado)   │    │  (Crashes)      │
└─────────────────┘    └─────────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │    Supabase     │
                       │   (Analytics)   │
                       └─────────────────┘
```

## 📊 Dados Coletados

### 1. Crash Reporting (Sentry)
- **Crashes automáticos**: Erros não tratados
- **Contexto**: Tela ativa, ações do usuário
- **Performance**: Tempo de carregamento
- **Dispositivo**: OS, versão, modelo

### 2. Analytics Customizados (Supabase)
- **Eventos de uso**: Leituras, compartilhamentos
- **Gamificação**: Level ups, streaks, XP
- **Navegação**: Telas visitadas, tempo de sessão
- **Engagement**: Frequência de uso, retenção

## 🚀 Como Funciona

### Coleta Automática
```dart
// Exemplo: Usuário lê devocional
await MonitoringService.logDevotionalRead('123');

// Automaticamente salva:
// 1. Sentry: Performance da operação
// 2. Supabase: Evento + timestamp + user_id
```

### Eventos Principais
| Evento | Sentry | Supabase | Dados |
|--------|--------|----------|-------|
| `app_launch` | ✅ Performance | ✅ Contagem | Tempo de inicialização |
| `devotional_read` | ❌ | ✅ Detalhado | ID, timestamp, duração |
| `level_up` | ❌ | ✅ Detalhado | Nível, XP total |
| `crash` | ✅ Completo | ❌ | Stack trace, contexto |
| `screen_view` | ❌ | ✅ Básico | Tela, timestamp |

## 💰 Custos (100% Gratuito)

### Sentry (Gratuito)
- **5.000 eventos/mês** - Suficiente para crashes
- **1 projeto** - BibliApp
- **Retenção**: 30 dias
- **Alertas**: Email básico

### Supabase (Já usado)
- **500MB database** - Analytics ocupam ~1MB/mês
- **2GB bandwidth** - Eventos são pequenos (~1KB cada)
- **50k requests/mês** - Eventos de analytics

### Estimativa de Uso
- **1000 usuários ativos/mês**
- **~2000 eventos Sentry** (crashes + performance)
- **~15000 eventos Supabase** (analytics detalhados)
- **Custo total: R$ 0,00**

## 📈 Dashboards

### 1. Sentry Dashboard
- **Issues**: Crashes por versão/dispositivo
- **Performance**: Tempo de carregamento
- **Releases**: Comparação entre versões
- **Alerts**: Email quando crash crítico

### 2. Supabase Dashboard (SQL Queries)
```sql
-- Usuários ativos por dia
SELECT DATE(created_at) as day, COUNT(DISTINCT user_id) as active_users
FROM app_events 
WHERE event_name = 'app_launch'
GROUP BY DATE(created_at)
ORDER BY day DESC;

-- Devocionais mais lidos
SELECT event_data->>'devotional_id' as devotional, COUNT(*) as reads
FROM app_events 
WHERE event_name = 'devotional_read'
GROUP BY devotional
ORDER BY reads DESC;
```

## 🔒 Privacidade

### Dados NÃO Coletados
- ❌ Informações pessoais (nome, email)
- ❌ Conteúdo dos devocionais
- ❌ Localização precisa
- ❌ Dados de outros apps

### Dados Coletados (Anônimos)
- ✅ ID do usuário (UUID anônimo)
- ✅ Eventos de uso (timestamps)
- ✅ Informações técnicas (OS, versão app)
- ✅ Métricas de performance

## 🛠 Implementação

### Setup Inicial (5 min)
1. **Criar conta Sentry** (gratuita)
2. **Copiar DSN** para .env
3. **Tabela Supabase** já criada automaticamente

### Uso no Código
```dart
// Tracking automático - já implementado
MonitoringService.logScreenView('home_screen');
MonitoringService.logDevotionalRead('123');
MonitoringService.logLevelUp(5, 1200);

// Crash reporting automático
try {
  // código que pode falhar
} catch (e, stack) {
  MonitoringService.recordError(e, stack, context: 'home_load');
}
```

## 📊 Métricas Importantes

### Engagement
- **DAU/MAU**: Usuários ativos
- **Session Length**: Tempo médio de uso
- **Retention**: Usuários que voltam

### Performance
- **Crash Rate**: % de sessões com crash
- **Load Time**: Tempo de inicialização
- **ANR Rate**: App não responsivo

### Gamificação
- **Level Distribution**: Usuários por nível
- **Streak Success**: Taxa de manutenção de streak
- **XP Sources**: Principais fontes de XP

## 🚨 Alertas Configurados

### Sentry (Automático)
- **Crash Rate > 1%**: Email imediato
- **Performance degradation**: Alerta diário
- **New release issues**: Monitoramento 24h

### Supabase (Manual via SQL)
- **Drop in DAU > 20%**: Query semanal
- **Crash spike**: Query diária
- **Feature adoption**: Query mensal

## 🔄 Manutenção

### Diária (2 min)
- Verificar alertas Sentry
- Revisar crashes críticos

### Semanal (15 min)
- Dashboard Supabase
- Análise de tendências
- Limpeza de dados antigos

### Mensal (30 min)
- Relatório completo
- Otimizações baseadas em dados
- Planejamento de features

## 📋 Checklist de Implementação

- [x] MonitoringService criado
- [x] Sentry configurado
- [x] Supabase analytics integrado
- [x] Eventos principais implementados
- [ ] Conta Sentry criada (você)
- [ ] DSN atualizado no .env (você)
- [ ] Teste em produção (você)

## 🎯 Benefícios

### Para Desenvolvimento
- **Bugs encontrados rapidamente**
- **Performance monitorada**
- **Decisões baseadas em dados**

### Para Usuários
- **App mais estável**
- **Melhor experiência**
- **Features mais relevantes**

### Para Negócio
- **Retenção melhorada**
- **Engagement aumentado**
- **Crescimento sustentável**

---

**Resultado**: Sistema profissional de monitoramento **100% gratuito** que escala até milhares de usuários sem custo adicional.