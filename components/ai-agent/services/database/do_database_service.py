import re
from datetime import datetime
from zoneinfo import ZoneInfo

import psycopg2
from psycopg2.extras import RealDictCursor

from schema.spending import SpendingInput
from services.database.database_service import IDataService
from settings.general import settings
from settings.logger import logger

# SQL keywords that mutate data — never allowed in query_spendings
_FORBIDDEN = re.compile(
    r"\b(INSERT|UPDATE|DELETE|DROP|TRUNCATE|ALTER|CREATE|GRANT|REVOKE|EXECUTE|CALL)\b",
    re.IGNORECASE,
)

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
                options=f"-c search_path={settings.db_schema}",
            )
        return self._connection

    def create_element(self, element: SpendingInput, user_id: str) -> str:
        conn = self._get_connection()

        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(
                    f"""
                    INSERT INTO {settings.db_schema}.{settings.db_table} (
                        user_id,
                        category, subcategory, description,
                        amount, currency, quantity,
                        payment_method, is_recurring, date
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING id;
                    """,
                    (
                        user_id,
                        element.category.value,
                        element.subcategory,
                        element.description,
                        element.amount,
                        element.currency.value,
                        element.quantity,
                        element.payment_method.value if element.payment_method else None,
                        element.is_recurring,
                        element.spending_date or datetime.now(ZoneInfo(settings.app_timezone)).date(),
                    ),
                )
                conn.commit()
                row = cursor.fetchone()
                return str(row["id"])
        except Exception as e:
            logger.error(f"[create_element] user={user_id} error={e}")
            conn.close()
            self._connection = None
            raise

    def query_spendings(self, user_id: str, sql: str) -> list[dict]:
        """
        Execute a read-only SQL query scoped to the given user_id.
        Mutating statements are rejected before execution.
        The table name is replaced by a pre-filtered subquery so the agent
        can write any SELECT freely without ever bypassing the user_id filter.
        """
        if _FORBIDDEN.search(sql):
            raise ValueError("Mutating SQL statements are not allowed in query_spendings.")

        scoped_sql = sql.replace(
            settings.db_table,
            f"(SELECT * FROM {settings.db_schema}.{settings.db_table} WHERE user_id = %s) AS {settings.db_table}",
        )

        conn = self._get_connection()
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(scoped_sql, (user_id,))
                return [dict(row) for row in cursor.fetchall()]
        except Exception:
            conn.close()
            self._connection = None
            raise

    def list_spendings(self, user_id: str, limit: int) -> list[dict]:
        """Return recent spendings for one user using a fixed, parameterized query."""
        conn = self._get_connection()
        try:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(
                    f"""
                    SELECT
                        id::text AS id,
                        category,
                        subcategory,
                        description,
                        amount::float8 AS amount,
                        currency,
                        quantity,
                        payment_method,
                        is_recurring,
                        COALESCE(date, CURRENT_DATE) AS date
                    FROM {settings.db_schema}.{settings.db_table}
                    WHERE user_id = %s
                    ORDER BY date DESC NULLS LAST, id DESC
                    LIMIT %s;
                    """,
                    (user_id, limit),
                )
                return [dict(row) for row in cursor.fetchall()]
        except Exception:
            conn.close()
            self._connection = None
            raise
