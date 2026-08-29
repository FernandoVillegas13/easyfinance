from strands import tool
from schema.spending import SpendingInput
from services.database.database_service import IDataService
from settings.logger import logger


class Tools:

    def __init__(self, database_service: IDataService, user_id: str):
        self._database_service = database_service
        self._user_id = user_id

    def get_log_tools(self) -> list:
        return [self.add_new_spending]

    def get_chat_tools(self) -> list:
        return [self.add_new_spending, self.query_spendings]

    @tool
    def add_new_spending(self, element: SpendingInput) -> str:
        """
        Add a new financial expense to the database.

        Args:
            element: Spending details including category, subcategory, description,
                     amount, currency, quantity, payment_method, is_recurring and date.
        """
        try:
            if isinstance(element, dict):
                element = SpendingInput(**element)

            logger.info(f"[add_new_spending] user={self._user_id} amount={element.amount} {element.currency} category={element.category}")
            created_id = self._database_service.create_element(element, self._user_id)
            logger.info(f"[add_new_spending] saved id={created_id}")
            return f"saved:{created_id}"
        except Exception as e:
            logger.error(f"[add_new_spending] error={e}")
            return f"error:{str(e)}"

    @tool
    def query_spendings(self, sql: str) -> str | list[dict]:
        """
        Run a read-only SQL SELECT query against the user's spending history.
        Results are automatically scoped to the current user — do not add user_id filters.
        Use standard SQL aggregations (SUM, AVG, COUNT, GROUP BY, ORDER BY) for analysis.

        Args:
            sql: A SELECT SQL query against the spendings table.
                 Available columns: id, category, subcategory, description,
                 amount, currency, quantity, payment_method, is_recurring, date.
                 Example: SELECT category, SUM(amount) as total FROM spendings GROUP BY category ORDER BY total DESC
        """
        try:
            logger.info(f"[query_spendings] user={self._user_id} sql={sql!r}")
            result = self._database_service.query_spendings(self._user_id, sql)
            logger.info(f"[query_spendings] rows={len(result) if isinstance(result, list) else 'n/a'}")
            return result
        except Exception as e:
            logger.error(f"[query_spendings] error={e}")
            return f"error:{str(e)}"
