# Roadmap Futuro - BibliApp

**Última atualização**: 2024-12-19
**Status**: Planejamento de Features Futuras

---

## 🎯 Features Planejadas

### 1. 📚 Planos de Leitura (Reading Plans)

#### Descrição
Sistema completo de planos de leitura bíblica com acompanhamento de progresso.

#### Funcionalidades
- Planos pré-definidos (30 dias, 90 dias, 1 ano)
- Planos temáticos (Salmos, Provérbios, Novo Testamento)
- Progresso visual (% concluído)
- Notificações diárias
- Histórico de leituras

#### Integração com Desafios
- **Desafio `study`**: Vinculado aos planos de leitura
- Exemplo: "Complete 5 dias do plano de leitura"
- XP por dia concluído + bônus por plano completo

#### Estrutura de Dados
```sql
-- Tabela: reading_plans
id, title, description, duration_days, plan_type, books_order

-- Tabela: user_reading_plans
user_id, plan_id, current_day, started_at, completed_at

-- Tabela: reading_plan_progress
user_id, plan_id, day_number, completed_at
```

---

### 2. ❤️ Sistema de Favoritos Expandido

#### Descrição
Favoritar versículos e devocionais com categorização.

#### Funcionalidades
- **Favoritar Versículos**: Salvar versículos específicos
- **Favoritar Devocionais**: Marcar devocionais completos
- **Categorias**: Esperança, Fé, Amor, Sabedoria
- **Notas**: Adicionar reflexões pessoais
- **Compartilhamento**: Compartilhar favoritos

#### Integração com Desafios
- **Desafio `favorite`**: Tipos específicos
  - "Favorite 3 versículos sobre fé"
  - "Favorite 2 devocionais esta semana"
- Validação por tipo (verse vs devotional)

#### Estrutura de Dados
```sql
-- Tabela: user_favorites
id, user_id, favorite_type (verse/devotional), 
reference_id, category, note, created_at

-- Tipos de favoritos
favorite_type: 'verse' | 'devotional'
```

---

### 3. 📝 Sistema de Anotações Avançado

#### Descrição
Anotações ricas com contagem de palavras e análise.

#### Funcionalidades
- Editor de texto rico
- Contagem de palavras em tempo real
- Tags e categorias
- Busca por conteúdo
- Exportar anotações (PDF/TXT)

#### Integração com Desafios
- **Desafio `note`**: Validação por tamanho
  - "Faça 2 anotações de pelo menos 50 palavras"
  - "Escreva uma reflexão de 100+ palavras"
- Campo `word_count` na tabela

#### Estrutura de Dados
```sql
-- Tabela: user_notes
id, user_id, devotional_id, content, 
word_count, tags, created_at, updated_at
```

---

## 🏆 Desafios Mensais (Monthly Challenges)

### Descrição
Desafios de longo prazo com recompensas maiores.

### Características
- **Duração**: 30 dias
- **XP Reward**: 100-500 XP
- **Coin Reward**: 50-200 Talentos
- **Dificuldade**: Alta
- **Tipos**: Complexos e compostos

### Tipos de Desafios Mensais

#### 1. 📖 Leitura de Livro Completo
```
Título: "Mestre em Salmos"
Descrição: Leia todos os 150 Salmos e escreva um resumo de 200 palavras
Target: 150 capítulos + 1 resumo
XP: 300
Validação: 
  - reading_plan_progress (150 dias)
  - user_notes (word_count >= 200)
```

#### 2. 📝 Anotações Profundas
```
Título: "Escriba Dedicado"
Descrição: Faça 10 anotações com mais de 100 palavras cada
Target: 10 anotações
XP: 200
Validação: user_notes (word_count >= 100)
```

#### 3. 🎯 Plano de Leitura Completo
```
Título: "Jornada de 30 Dias"
Descrição: Complete um plano de leitura de 30 dias sem falhar
Target: 30 dias consecutivos
XP: 400
Validação: user_reading_plans (completed_at IS NOT NULL)
```

#### 4. 🏅 Meta-Desafio Semanal
```
Título: "Campeão Semanal"
Descrição: Complete todos os 5 desafios semanais por 4 semanas
Target: 20 desafios (5 x 4 semanas)
XP: 500
Validação: user_challenge_progress (is_completed = true)
```

#### 5. 🔥 Streak Extremo
```
Título: "Gigante da Consistência"
Descrição: Mantenha um streak de 30 dias consecutivos
Target: 30 dias
XP: 350
Validação: user_profiles (current_streak_days >= 30)
```

### Estrutura de Dados

```sql
-- Tabela: monthly_challenges
CREATE TABLE monthly_challenges (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  challenge_type TEXT NOT NULL, -- 'book_reading', 'deep_notes', 'reading_plan', 'weekly_meta', 'streak'
  target_value INT NOT NULL,
  xp_reward INT NOT NULL,
  coin_reward INT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  
  -- Validação específica
  validation_config JSONB, -- { "word_count_min": 100, "book_id": 19 }
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabela: user_monthly_progress
CREATE TABLE user_monthly_progress (
  id SERIAL PRIMARY KEY,
  user_profile_id UUID REFERENCES user_profiles(id),
  challenge_id INT REFERENCES monthly_challenges(id),
  current_progress INT DEFAULT 0,
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMP,
  
  -- Metadados de progresso
  progress_details JSONB, -- { "days_completed": [1,2,3], "notes_ids": [123,456] }
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  UNIQUE(user_profile_id, challenge_id)
);
```

---

## 🤖 Geração Automática com IA

### Desafios Semanais (Atual)
- ✅ OpenAI gpt-4o-mini
- ✅ 5 desafios/semana
- ✅ Temas sazonais

### Desafios Mensais (Futuro)
```javascript
// n8n Workflow - Monthly Challenges
// Trigger: 1º dia do mês, 00:00

const prompt = `
Gere 5 desafios mensais para um app cristão:

1. Leitura de livro bíblico completo
2. Anotações profundas (10x 100+ palavras)
3. Plano de leitura de 30 dias
4. Meta: Completar 20 desafios semanais
5. Streak de 30 dias

Formato JSON:
{
  "challenges": [
    {
      "title": "...",
      "description": "...",
      "challenge_type": "book_reading",
      "target_value": 150,
      "xp_reward": 300,
      "coin_reward": 100,
      "validation_config": { "book_id": 19 }
    }
  ]
}

Tema do mês: ${getCurrentMonthTheme()}
`;
```

---

## 📊 Priorização

### Fase 1 (Próximos 3 meses)
1. ✅ Sistema de Favoritos Básico
2. ✅ Anotações com contagem de palavras
3. ⏳ Planos de Leitura (estrutura básica)

### Fase 2 (3-6 meses)
1. ⏳ Desafios Mensais (tabelas + lógica)
2. ⏳ Integração `study` com planos
3. ⏳ Validação avançada de desafios

### Fase 3 (6-12 meses)
1. ⏳ IA para desafios mensais
2. ⏳ Categorização de favoritos
3. ⏳ Exportação de anotações
4. ⏳ Análise de progresso (dashboards)

---

## 💡 Ideias Adicionais

### Gamificação Avançada
- **Títulos especiais**: "Mestre dos Salmos", "Escriba Dedicado"
- **Badges**: Ícones únicos por desafio mensal completo
- **Leaderboard**: Ranking mensal de XP

### Social
- **Grupos de leitura**: Planos compartilhados
- **Desafios em grupo**: Competir com amigos
- **Compartilhar progresso**: Stories de conquistas

### Personalização
- **Temas visuais**: Claro, escuro, sépia
- **Fontes**: Tamanho e estilo
- **Notificações**: Horários personalizados

---

## 🎯 Métricas de Sucesso

### Engajamento
- Taxa de conclusão de desafios mensais: > 30%
- Tempo médio no app: > 15 min/dia
- Retention 30 dias: > 60%

### Monetização
- Conversão Freemium → Premium: > 5%
- LTV (Lifetime Value): > R$ 100
- Churn rate: < 10%/mês

---

**Nota**: Este roadmap é flexível e será ajustado conforme feedback dos usuários e métricas de uso.
