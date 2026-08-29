from strands import tool
from schema.spending import SpendingInput
from services.database.database_service import IDataService


class Tools:

    def __init__(self, database_service: IDataService):
        self._database_service = database_service

    def get_tools(self) -> list:
        return [self.add_new_spending]

    @tool
    def add_new_spending(self, element: SpendingInput) -> str:
        """
        Add a new financial expense to the database.

        Args:
            element: Spending details including category, amount, quantity, and optional description.
        """

        print("ELEMENT:", str(element) )

        created_id = self._database_service.create_element(element)
        return f"Expense added successfully with id: {created_id}"