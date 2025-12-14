Crie um app chamado **BibliApp**, voltado para cristãos que desejam ter uma jornada espiritual rica, organizada e envolvente. O app deve ser desenvolvido com **Flutter**, estilizado com **material ui**, e utilizar **Supabase** como backend. O objetivo é oferecer devocionais, planos de leitura e uma experiência gamificada completa.

---

## 🧱 Estrutura de Telas e Funcionalidades

### 🏠 Tela Inicial (Explorar)
- Seções com listas horizontais: Devocionais do dia, Estudos em destaque, Versículo do dia
- Imagens integradas com Unsplash aleatoriamente de natureza

---
### Paleta de Cores
A identidade visual do BibliApp será baseada em uma paleta harmônica, moderna e acolhedora, utilizando as seguintes cores principais:

| Nome           | Código Hex | Descrição/Aplicação Sugerida                |
|----------------|:----------:|---------------------------------------------|
| Monocromático  | #005954    | Cor principal, botões, header, destaques    |
| Complementar   | #338b85    | Ações secundárias, ícones, links            |
| Análogo        | #5dc1b9    | Backgrounds suaves, cards, elementos leves  |
| Tríade         | #9ce0db    | Detalhes, hover, estados intermediários     |
| Tetrádico      | #fffffd    | Fundo, áreas de respiro, contraste sutil    |

---

### 📖 Leitura Bíblica
- Navegação completa por livros, capítulos e versículos
- Sistema de marcação e anotações por versículo
- Suporte a múltiplas versões bíblicas (ex: NVIPT, NAA, NTLH)
- Busca avançada por palavra, frase ou referência
- Histórico de leitura, versos favoritos, cores dos versos destacados/favoritos sincronizado com Supabase, 
- Para carregamento da Bíblia utilizar a https://bolls.life/api/

---

### 🙏 Devocionais
- Devocionais diários com título, versículo base e corpo do texto
- Imagem de capa aleatória do Unsplash
- Reflexões e meditações com botão "Marcar como lido" (+XP)
- Versículo do dia destacado
- Botão para compartilhar citação como imagem (versículo + frase)
- Favoritar devocionais (salvos no Supabase)
- Todos os devocionais vem da tabela devotionals que está no Supabase

---

### 📅 Planos de Leitura
- Planos pré-definidos como:
  - "Sabedoria em 45 Dias" (Jó, Provérbios, Eclesiastes)
  - "40 Dias Convivendo com Jesus" (Evangelhos)
- Criação de planos personalizados
- Progresso diário com barra de leitura
- Lembretes com notificações locais (`expo-notifications`)
- Leitura do dia carregada de um arquivo JSON salvo em `/assets/planos/`

---

### 👥 Recursos Sociais
- Perfil do usuário com nome, avatar e estatísticas
- Compartilhamento de versículos e devocionais
- Feed de atividades recentes (opcional para versão futura)
- Estatísticas de leitura (dias ativos, versículos lidos, planos completos)

---

## 🏆 Sistema de Gamificação Completo

### 📋 Bibliotecas Flutter Utilizadas

#### Dependências no pubspec.yaml:
```yaml
dependencies:
  badges: ^3.1.2                    # Sistema de badges e notificações
  percent_indicator: ^4.2.3         # Barras de progresso para XP e níveis
  shared_preferences: ^2.2.2        # Cache local para dados de gamificação
  supabase_flutter: ^latest         # Conexão com backend
```

### 🎮 Mecânicas de Gamificação

#### Sistema de XP (Experience Points):
- **Leitura de Devocional**: +10 XP
- **Completar Estudo**: +20 XP  
- **Leitura Bíblica (por capítulo)**: +5 XP
- **Streak de 3 dias**: +25 XP (bônus)
- **Completar Plano de Leitura**: +50 XP
- **Compartilhar Versículo**: +5 XP
- **Primeira leitura do dia**: +15 XP (bônus matinal)

#### Sistema de Níveis:
- **Nível 1**: 0-100 XP (Novato na Fé)
- **Nível 2**: 101-250 XP (Buscador)
- **Nível 3**: 251-500 XP (Discípulo)
- **Nível 4**: 501-800 XP (Servo Fiel)
- **Nível 5**: 801-1200 XP (Estudioso)
- **Nível 6**: 1201-1700 XP (Sábio)
- **Nível 7**: 1701-2300 XP (Mestre)
- **Nível 8**: 2301-3000 XP (Líder Espiritual)
- **Nível 9**: 3001-4000 XP (Mentor)
- **Nível 10**: 4001+ XP (Gigante da Fé)

#### Sistema de Badges/Conquistas:
```dart
// Exemplos de conquistas implementadas
final List<Achievement> achievements = [
  Achievement(
    id: 'first_devotional',
    name: 'Primeiro Passo',
    description: 'Leia seu primeiro devocional',
    icon: Icons.favorite,
    xpReward: 10,
    coinReward: 5,
  ),
  Achievement(
    id: 'streak_7',
    name: 'Semana Sagrada',
    description: 'Mantenha uma sequência de 7 dias',
    icon: Icons.local_fire_department,
    xpReward: 50,
    coinReward: 25,
  ),
  Achievement(
    id: 'devotional_30',
    name: 'Dedicado',
    description: 'Complete 30 devocionais',
    icon: Icons.auto_awesome,
    xpReward: 100,
    coinReward: 50,
  ),
];
```

### 🗄️ Tabelas do Supabase Utilizadas

#### Tabela `user_profiles`:
```sql
-- Armazena dados principais do usuário e gamificação
- id (uuid, PK)
- username (varchar)
- avatar_url (varchar)
- total_devotionals_read (integer) -- Para tracking de conquistas
- total_xp (integer) -- XP total acumulado
- current_level (integer) -- Nível atual (1-10)
- xp_to_next_level (integer) -- XP restante para próximo nível
- coins (integer) -- Moedas virtuais para loja
- weekly_goal (integer) -- Meta semanal personalizada
```

#### Tabela `xp_transactions`:
```sql
-- Histórico detalhado de ganhos de XP
- id (integer, PK)
- user_profile_id (uuid, FK)
- amount (integer) -- Quantidade de XP ganha
- transaction_type (enum: 'earned', 'bonus', 'penalty')
- source_type (enum: 'devotional', 'reading', 'streak', 'study')
- source_id (integer) -- ID da fonte (devotional_id, etc)
- transaction_date (timestamp)
```

#### Tabela `xp_config`:
```sql
-- Configuração flexível de valores de XP
- action (text, PK) -- 'devotional_read', 'streak_3', etc
- xp_value (integer) -- Valor de XP para a ação
```

#### Tabela `levels`:
```sql
-- Definição dos níveis e requisitos
- id (integer, PK)
- level_number (integer, unique)
- required_xp (integer) -- XP necessário para alcançar este nível
```

#### Tabela `achievements`:
```sql
-- Definições das conquistas disponíveis
- id (integer, PK)
- name (varchar, unique) -- Nome da conquista
- description (text) -- Descrição detalhada
- icon_url (varchar) -- URL do ícone
- xp_reward (integer) -- XP ganho ao conquistar
- coin_reward (integer) -- Moedas ganhas ao conquistar
```

#### Tabela `user_achievements`:
```sql
-- Conquistas desbloqueadas pelo usuário
- id (integer, PK)
- user_profile_id (uuid, FK)
- achievement_id (integer, FK)
- earned_at (timestamp) -- Quando foi conquistado
```

#### Tabela `user_badges`:
```sql
-- Sistema flexível de badges
- id (uuid, PK)
- user_profile_id (uuid, FK)
- badge_type (enum: 'streak', 'reading', 'level', 'achievement', 'challenge')
- badge_name (varchar)
- badge_description (text)
- badge_data (jsonb) -- Dados extras do badge
- display_order (integer) -- Ordem de exibição
- is_visible (boolean) -- Se deve aparecer no perfil
- earned_at (timestamp)
```

#### Tabela `reading_streaks`:
```sql
-- Controle de sequências de leitura
- id (integer, PK)
- user_profile_id (uuid, FK)
- current_streak_days (integer)
- longest_streak_days (integer) -- Recorde pessoal
- last_active_date (date) -- Última atividade
```

#### Tabela `weekly_progress`:
```sql
-- Progresso semanal do usuário
- id (integer, PK)
- user_profile_id (uuid, FK)
- week_start_date (date)
- devotionals_read_this_week (integer)
```

### 🎨 Implementação Visual com Flutter

#### Barra de Progresso de XP:
```dart
import 'package:percent_indicator/percent_indicator.dart';

Widget buildXPProgressBar(int currentXP, int xpToNext) {
  double progress = currentXP / (currentXP + xpToNext);
  
  return LinearPercentIndicator(
    width: MediaQuery.of(context).size.width - 50,
    animation: true,
    lineHeight: 20.0,
    animationDuration: 1000,
    percent: progress,
    center: Text("${currentXP}/${currentXP + xpToNext} XP"),
    linearStrokeCap: LinearStrokeCap.roundAll,
    progressColor: Color(0xFF338b85), // Cor complementar
    backgroundColor: Color(0xFF9ce0db), // Cor tríade
  );
}
```

#### Sistema de Badges:
```dart
import 'package:badges/badges.dart' as badges;

Widget buildAchievementBadge(Achievement achievement, bool isEarned) {
  return badges.Badge(
    badgeContent: Icon(
      achievement.icon,
      color: Colors.white,
      size: 16,
    ),
    badgeStyle: badges.BadgeStyle(
      badgeColor: isEarned ? Color(0xFF005954) : Colors.grey,
      elevation: 4,
    ),
    child: Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF5dc1b9),
      ),
      child: Icon(
        achievement.icon,
        size: 30,
        color: isEarned ? Color(0xFF005954) : Colors.grey[600],
      ),
    ),
  );
}
```

### ⚡ Funções RPC do Supabase

#### Função para Award XP:
```sql
CREATE OR REPLACE FUNCTION award_xp(
  p_user_id UUID,
  p_source_type TEXT,
  p_source_id INTEGER DEFAULT NULL,
  p_custom_amount INTEGER DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  xp_amount INTEGER;
  new_total_xp INTEGER;
  current_level INTEGER;
  level_up BOOLEAN := FALSE;
  result JSON;
BEGIN
  -- Buscar valor de XP da configuração ou usar custom
  IF p_custom_amount IS NOT NULL THEN
    xp_amount := p_custom_amount;
  ELSE
    SELECT xp_value INTO xp_amount 
    FROM xp_config 
    WHERE action = p_source_type;
  END IF;
  
  -- Inserir transação de XP
  INSERT INTO xp_transactions (
    user_profile_id, amount, transaction_type, 
    source_type, source_id
  ) VALUES (
    p_user_id, xp_amount, 'earned', 
    p_source_type, p_source_id
  );
  
  -- Atualizar XP total do usuário
  UPDATE user_profiles 
  SET total_xp = total_xp + xp_amount
  WHERE id = p_user_id
  RETURNING total_xp, current_level INTO new_total_xp, current_level;
  
  -- Verificar level up
  IF new_total_xp >= (SELECT required_xp FROM levels WHERE level_number = current_level + 1) THEN
    UPDATE user_profiles 
    SET current_level = current_level + 1,
        xp_to_next_level = (
          SELECT required_xp FROM levels 
          WHERE level_number = current_level + 2
        ) - new_total_xp
    WHERE id = p_user_id;
    level_up := TRUE;
  END IF;
  
  -- Retornar resultado
  SELECT json_build_object(
    'xp_gained', xp_amount,
    'total_xp', new_total_xp,
    'level_up', level_up,
    'current_level', current_level
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;
```

#### Função para Check Achievements:
```sql
CREATE OR REPLACE FUNCTION check_and_award_achievements(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  user_stats RECORD;
  achievement RECORD;
  new_achievements JSON[] := '{}';
BEGIN
  -- Buscar estatísticas do usuário
  SELECT total_devotionals_read, current_level,
         (SELECT current_streak_days FROM reading_streaks 
          WHERE user_profile_id = p_user_id) as current_streak
  INTO user_stats
  FROM user_profiles 
  WHERE id = p_user_id;
  
  -- Verificar conquistas baseadas em devocionais
  FOR achievement IN 
    SELECT * FROM achievements 
    WHERE name IN ('first_devotional', 'devotional_10', 'devotional_30')
    AND id NOT IN (
      SELECT achievement_id FROM user_achievements 
      WHERE user_profile_id = p_user_id
    )
  LOOP
    -- Lógica para cada tipo de achievement...
    -- Inserir se conquistado
  END LOOP;
  
  RETURN array_to_json(new_achievements);
END;
$$ LANGUAGE plpgsql;
```

### 🎯 Fluxo de Gamificação no App

1. **Usuário completa uma ação** (lê devocional, etc)
2. **Flutter chama RPC** `award_xp()` no Supabase
3. **Supabase processa**: XP, level up, conquistas
4. **Flutter recebe resposta** e atualiza UI
5. **Animações visuais**: barra de XP, badges, level up
6. **Cache local** atualizado para performance

### 🔐 Backend
- Supabase para autenticação, banco de dados, favoritos, progresso
- Tabelas principais para gamificação:
  - `user_profiles`, `xp_transactions`, `xp_config`, `levels`
  - `achievements`, `user_achievements`, `user_badges`
  - `reading_streaks`, `weekly_progress`
- Assets estáticos (planos, versículos, temas) carregados via JSON em `/assets/`

---

### 🌗 Tema e Estilo
- Tema claro e escuro com alternância
- Estilização com React Native Paper

---

### 📲 Navegação
- Navegação por abas com React Navigation:
  - Explorar | Leitura | Devocional | Conquistas | Perfil

---

## 🎯 Público-Alvo
Usuários cristãos que buscam consistência espiritual, com ferramentas modernas, conteúdos inspiradores e incentivo à disciplina através da gamificação.

### Modelo do Projeto Figma
Todas as páginas e modelos visuais do App estão no figma.
https://www.figma.com/design/0xnGlyKg82fRRm5jvRCsjk/kMjcAecGwdQhHEg97NbJxj?node-id=0-1