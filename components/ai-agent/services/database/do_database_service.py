import psycopg2
from psycopg2.extras import RealDictCursor

from schema.spending import SpendingInput
from services.database.database_service import IDataService
from settings.general import settings


class DoDatabaseService(IDataService):

    def __init__(self):
        self._connection = psycopg2.connect(
            host=settings.db_host,
            port=settings.db_port,
            dbname=settings.db_name,
            user=settings.db_user,
            password=settings.db_password,
        )
        self._connection.autocommit = True

    def create_element(self, element: SpendingInput) -> str:
        query = f"""
            INSERT INTO {settings.db_table} (category, amount, quantity, description)
            VALUES (%s, %s, %s, %s)
            RETURNING id;
        """
        with self._connection.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(
                query,
                (element.category, element.amount, element.quantity, element.description),
            )
            row = cursor.fetchone()
            return str(row["id"])
