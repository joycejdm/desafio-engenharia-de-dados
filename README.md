# Desafio Técnico de Engenharia de Dados - Retize

## Visão Geral da Solução
Esta solução implementa um pipeline ELT (Extract, Load, Transform) rodando localmente para consolidar dados de performance de redes sociais (Instagram e TikTok). O objetivo é harmonizar métricas distintas em um modelo analítico unificado para responder a perguntas estratégicas de negócio, aplicando boas práticas de Engenharia de Dados, como modelagem dimensional básica e testes de qualidade de dados.

## Arquitetura e Fluxo Adotado
1. **Infraestrutura:** Banco de dados PostgreSQL executado via Docker Compose.
2. **Ingestão (Extract & Load):** Script Python (`src/ingestao.py`) utilizando `pandas` para ler os arquivos CSV locais e realizar a carga (append/replace) direta no banco de dados na camada crua (`raw_`).
3. **Transformação (Transform):** `dbt` (Data Build Tool) orquestrando a modelagem lógica dentro do banco de dados, dividida em:
   * **Staging:** Limpeza, padronização de nomenclatura, tratamentos de tipos de dados.
   * **Marts:** Tabelas finais de consumo analítico (`mart_posts_performance` e `mart_comments_sentiment`).
4. **Análise:** Consultas SQL (`queries/`) para extração de respostas analíticas diretas do banco.

---

## Como Executar o Projeto

### 1. Preparar o Ambiente e Subir o Banco de Dados
Certifique-se de ter o Docker e o Python 3 instalados na máquina.

```bash
# Suba o banco de dados PostgreSQL em background
docker-compose up -d
```

### 2. Executar a Ingestão (Python)
Os arquivos `.csv` originais devem estar na raiz do projeto (não versionados por segurança).

```bash
python3 -m venv venv
source venv/bin/activate  

pip install -r requirements.txt

# Execute a carga bruta
python src/ingestao.py
```

### 3. Executar as Transformações e Testes (dbt)

Com os dados brutos no banco, entraremos na pasta do dbt para executar a modelagem e garantir a qualidade dos dados.

```bash
# Acesse o diretório do dbt
cd retize_dbt

# Execute as transformações (Criação de Views e Tables)
dbt run

# Execute os testes de qualidade
dbt test
```

### 4. Rodar as Queries Analíticas

Com a tabela final `mart_posts_performance` construída, as queries de negócio estão na pasta `queries/`. Você pode executar cada arquivo `.sql` (ex: `1_melhor_dia_semana.sql`) no seu cliente SQL preferido (ex: DBeaver) conectado ao banco `localhost:5432`.

## Principais Decisões Técnicas e Modelagem

- **Fórmula de Engajamento**: Definida como `(likes + comments + shares) / reach`. Optei pelo reach (alcance) como denominador em vez de impressões ou visualizações, pois ele representa usuários únicos, padronizando melhor a comparação de efetividade entre diferentes formatos e redes. Também incluí um tratamento de `CASE WHEN` para evitar erros lógicos de divisão por zero.

- **Harmonização de Plataformas**: Como o TikTok não fornece `media_type`, criei uma regra fixando-o como `'VIDEO'`, permitindo a comparação com os formatos diversos do Instagram (IMAGE, CAROUSEL, VIDEO).

- **Tratamento de Timestamps**: A data do TikTok (`create_time`) vem em formato numérico (Unix Epoch). Tratei isso na camada Staging utilizando `to_timestamp()` do PostgreSQL para converter para data.

- **Deduplicação de Dados**: Durante a execução do `dbt test`, identifiquei posts duplicados na tabela de performance consolidada. Apliquei uma Window Function (`ROW_NUMBER`) na camada de Mart para garantir a unicidade do `post_id`, mantendo a métrica de negócio limpa.

- **Filtro de Período**: O limite de análise (01/03/2025 a 31/03/2026) foi aplicado diretamente na materialização da tabela Mart, garantindo que as tabelas finais já entreguem o escopo isolado aos analistas, melhorando a performance de consulta nas ferramentas de BI.

## Limitações, Premissas e Melhorias Futuras

- **Melhoria - Orquestração**: Em um ambiente produtivo, substituiríamos a execução manual por orquestração com Apache Airflow, unindo o trigger do script Python ao `dbt run` no mesmo fluxo.

- **Premissa - Carga de Dados**: O modelo Python utiliza `if_exists='replace'` para facilitar o reset do banco no ambiente de teste. Em produção, adotaríamos uma carga incremental (append ou upsert) dependendo do tamanho das bases.

- **Segurança e Variáveis de Ambiente**: Por se tratar de um ambiente de teste local e visando a facilidade de execução pelo avaliador, as credenciais do banco de dados foram mantidas no código. Em um cenário produtivo, utilizaria variáveis de ambiente (arquivo `.env`) ou um gerenciador de segredos (como AWS Secrets Manager ou HashiCorp Vault) para garantir a segurança das informações sensíveis.

## Modelagem de dados

A arquitetura lógica adota o padrão Medallion (simplificado). Abaixo, o Diagrama de Relacionamento e fluxo das transformações:

```mermaid
erDiagram
    %% Fontes Raw
    RAW_INSTAGRAM_MEDIA ||--o{ STG_INSTAGRAM_POSTS : extrai
    RAW_INSTAGRAM_INSIGHTS ||--o{ STG_INSTAGRAM_POSTS : enriquece
    RAW_TIKTOK_POSTS ||--o{ STG_TIKTOK_POSTS : extrai
    RAW_INSTAGRAM_COMMENTS ||--o{ MART_COMMENTS_SENTIMENT : consolida
    RAW_TIKTOK_COMMENTS ||--o{ MART_COMMENTS_SENTIMENT : consolida

    %% Camada Staging
    STG_INSTAGRAM_POSTS ||--o{ MART_POSTS_PERFORMANCE : unifica
    STG_TIKTOK_POSTS ||--o{ MART_POSTS_PERFORMANCE : unifica

    %% Camada Mart (Finais)
    MART_POSTS_PERFORMANCE {
        string account_name
        string platform
        string post_id PK
        date post_date
        string content_format
        float engagement_rate "Fórmula: (likes+comments+shares)/reach"
    }

    MART_COMMENTS_SENTIMENT {
        string platform
        string post_id FK
        string sentiment "positivo, neutro, negativo"
    }