import psycopg2
from psycopg2.extras import RealDictCursor

from schema.spending import SpendingInput
from services.database.database_service import IDataService
from settings.general import settings


class DoDatabaseService(IDataService):

    def __init__(self):
        self._connection = None

    def _get_connection(self):
        if self._connection is None or self._connection.closed:
            self._connection = psycopg2.connect(
                host=settings.db_host,
                port=settings.db_port,
                dbname=settings.db_name,
                user=settings.db_user,
                password=settings.db_password,
            )
        return self._connection

    def create_element(self, element: SpendingInput) -> str:
        conn = self._get_connection()
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(
                    f"""
                    INSERT INTO {settings.db_table} (
                        category, subcategory, description,
                        amount, quantity,
                        payment_method, is_recurring, date
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING id;
                    """,
                    (
                        element.category.value,
                        element.subcategory,
                        element.description,
                        element.amount,
                        element.quantity,
                        element.payment_method.value if element.payment_method else None,
                        element.is_recurring,
                        element.date,
                    ),
                )
                conn.commit()
                row = cursor.fetchone()
                return str(row["id"])
        except Exception:
            conn.close()
            self._connection = None
            raise
