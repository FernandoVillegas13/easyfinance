from abc import ABC, abstractmethod
from typing import Any, Dict, List, Literal
from schema.spending import SpendingInput


class IDataService(ABC):

    @abstractmethod
    def create_element(self, element: SpendingInput) -> str:
        pass
