import os
import logging
import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.exc import SQLAlchemyError

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

DB_USER = 'retize_user'
DB_PASSWORD = 'retize_pass'
DB_HOST = 'localhost'
DB_PORT = '5432'
DB_NAME = 'retize_db'

ARQUIVOS_PARA_TABELAS = {
    'instagram_media.csv': 'raw_instagram_media',
    'instagram_media_insights.csv': 'raw_instagram_media_insights',
    'instagram_comments.csv': 'raw_instagram_comments',
    'tiktok_posts.csv': 'raw_tiktok_posts',
    'tiktok_comments.csv': 'raw_tiktok_comments'
}

def get_engine():
    """Cria e retorna a conexão com o banco de dados."""
    conexao_str = f'postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}'
    return create_engine(conexao_str)

def carregar_dados():
    engine = get_engine()
    
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    for arquivo, tabela in ARQUIVOS_PARA_TABELAS.items():
        caminho_csv = os.path.join(base_dir, arquivo)
        
        logging.info(f"Processando arquivo: {arquivo}")
        
        if not os.path.exists(caminho_csv):
            logging.error(f"Arquivo não encontrado: {caminho_csv}")
            continue
            
        try:
            df = pd.read_csv(caminho_csv)
            
            df.to_sql(tabela, engine, if_exists='replace', index=False)
            
            logging.info(f"Tabela '{tabela}' carregada com sucesso. ({len(df)} registros)")
            
        except pd.errors.EmptyDataError:
            logging.warning(f"O arquivo {arquivo} está vazio e foi ignorado.")
        except SQLAlchemyError as e:
            logging.error(f"Falha ao inserir dados de {arquivo} no banco: {e}")
        except Exception as e:
            logging.error(f"Erro inesperado ao processar {arquivo}: {e}", exc_info=True)

if __name__ == "__main__":
    logging.info("Iniciando processo de ingestão de dados...")
    carregar_dados()
    logging.info("Processo de ingestão finalizado.")