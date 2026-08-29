from abc import ABC, abstractmethod

from schema.spending import SpendingInput


class IDataService(ABC):

    @abstractmethod
    def create_element(self, element: SpendingInput, user_id: str) -> str:
        pass

    @abstractmethod
    def query_spendings(self, user_id: str, sql: str) -> list[dict]:
        pass

    @abstractmethod
    def list_spendings(self, user_id: str, limit: int) -> list[dict]:
        pass
