from abc import ABC, abstractmethod
from schema.spending import SpendingInput


class IDataService(ABC):

    @abstractmethod
    def create_element(self, element: SpendingInput) -> str:
        pass

    @abstractmethod
    def query_spendings(self, user_id: str, sql: str) -> list[dict]:
        pass
