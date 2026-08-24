from pydantic import BaseModel, Field
from typing import Optional

class SpendingInput(BaseModel):
    
    category: str = Field(
        description="Category of the expense")

    amount: float = Field(
        description="Unit price or total amount of the expense")

    quantity: int = Field(
        default=1,
        gt=0,
        description="Number of units purchased"
    )

    description: Optional[str] = Field(
        default=None,
        description="Optional description of the expense"
    )