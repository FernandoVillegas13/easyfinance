from strands import tool
from schema.spending import SpendingInput
from services.database.database_service import IDataService


class Tools:

    def __init__(self, database_service: IDataService):
        self._database_service = database_service
        self._user_id: str = ""

    def get_log_tools(self) -> list:
        return [self.add_new_spending]

    def get_chat_tools(self, user_id: str) -> list:
        self._user_id = user_id
        return [self.add_new_spending, self.query_spendings]

    @tool
    def add_new_spending(self, element: SpendingInput) -> str:
        """
        Add a new financial expense to the database.

        Args:
            element: Spending details including category, subcategory, description,
                     amount, currency, quantity, payment_method, is_recurring and date.
        """
        created_id = self._database_service.create_element(element)
        return f"Expense logged successfully with id: {created_id}"

    @tool
    def query_spendings(self, sql: str) -> list[dict]:
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
        return self._database_service.query_spendings(self._user_id, sql)
