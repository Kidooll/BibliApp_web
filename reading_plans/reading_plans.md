# 📘 Documentação — Funcionalidade de Planos de Leitura e Dashboard

## 📚 1. **Planos de Leitura**

### 🔧 Estrutura Técnica

* Base de dados já existente no **Supabase**.
* Planos cadastrados via CSV ou JSON (como `profetas_menores.json`).
* Arquivos adicionais: progresso (`reading_progress_rows.csv`) e histórico (`reading_history_rows.csv`).
* Integração com API da **Bible Bolls** para abrir capítulos diretamente no app.

### 🧱 Entidades e Models

* `ReadingPlan`

  * `id`, `title`, `description`, `duration`, `chapters[]`, `cover_image`, `is_active`, `start_date`, `end_date`
* `ReadingProgress`

  * `user_id`, `plan_id`, `current_day`, `completed_chapters[]`, `percentage`
* `ReadingHistory`

  * `user_id`, `chapter`, `timestamp`, `plan_id` (opcional)

### 📂 Repositórios

* `ReadingPlanRepository` (para Supabase e cache local)
* `ReadingProgressRepository`
* `ReadingHistoryRepository`

### ⚙️ UseCases

* `GetPlans()`
* `GetPlanDetails(planId)`
* `GetUserProgress(planId)`
* `MarkChapterAsRead(planId, chapter)`
* `SyncProgressWithBackend()`

### 📱 Telas

* **Lista de Planos de Leitura**

  * Cards com: título, dias restantes, status (ativo/concluído), botão iniciar.
* **Detalhes do Plano**

  * Capa, descrição, metas diárias, lista de capítulos, progresso em barra.
  * Botão de iniciar ou continuar leitura.
* **Leitura Diária**

  * Apresentação do trecho do dia via API.
  * Ações: Marcar como lido, Compartilhar, Favoritar, Notas.

---

## 📊 2. **Dashboard do Usuário**

### 📈 Objetivo

Dar uma visão clara do desempenho e engajamento do usuário com leitura bíblica no app.

### 📋 Itens Apresentados

#### 1. **Horas de Leitura**

* Donut chart:

  * Total: `200h`
  * Antigo Testamento: `160h`
  * Novo Testamento: `40h`
* Cores: tons suaves de verde.
* Design com profundidade e sombra.

#### 2. **Horas por Mês (Gráfico de Linha)**

* Eixo X: dias da semana.
* Eixo Y: percentual de leitura em relação ao ideal.
* Linha verde com destaques em roxo no dia atual.
* Ajuda o usuário a visualizar picos e quedas semanais.

#### 3. **Média Diária de Capítulos**

* Valor calculado com base no histórico.
* Exemplo: `3,2 capítulos/dia`
* Indicador: abaixo/acima da média esperada.
* Cartão com ícone, descrição e incentivo.
* Pode incluir moedas e ranking futuramente.

#### 4. **Sugestão do Dia / Plano Ativo**

* Card com:

  * Dia da leitura
  * Capítulos
  * Tempo estimado
  * Botão “Continuar”

---

## 🎨 3. **Mockups Criados**

### 📱 Planos de Leitura - Tela Inicial

* Cards com imagens e nomes dos planos.
* Design moderno, visualmente leve e agradável.
* Botão “Ver mais” em cada card.

### 📖 Detalhes do Plano

* Capa ilustrativa
* Descrição do plano
* Progresso em barra
* Lista dos dias com marcação de capítulos lidos
* Botões:

  * Marcar capítulo como lido
  * Compartilhar progresso
  * Iniciar plano

### 📈 Dashboard Melhorado

* Layout otimizado com separação de seções.
* Gráficos integrados com a paleta do app.
* Cards adicionais para gamificação (moedas, XP, conquistas).

---

## 🏆 4. **Gamificação e Engajamento**

* **XP e Moedas**

  * Leitura de capítulos = XP + moedas
  * Compartilhar reflexões = bônus
  * Concluir plano = conquistas

* **Desafios Semanais**

  * Lidos do Supabase, verificados por `end_date`
  * Cada desafio traz recompensa única

* **Progressão Natural**

  * Integração com leitura da Bíblia fluida, sem fricção
  * Registro automático de capítulos lidos
  * Animações e feedbacks visuais ao completar etapas

