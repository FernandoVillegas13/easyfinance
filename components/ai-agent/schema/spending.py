from pydantic import BaseModel, Field
from typing import Optional
from datetime import date
from enum import Enum


class SpendingCategory(str, Enum):
    FOOD = "food"
    TRANSPORT = "transport"
    SHOPPING = "shopping"
    ENTERTAINMENT = "entertainment"
    TECH = "tech"
    HEALTH = "health"
    TRAVEL = "travel"
    EDUCATION = "education"
    OTHER = "other"


class PaymentMethod(str, Enum):
    CASH = "cash"
    DEBIT = "debit"
    CREDIT = "credit"
    TRANSFER = "transfer"


class Currency(str, Enum):
    PEN = "PEN"  # Soles peruanos (default)
    USD = "USD"  # Dólares americanos


class SpendingInput(BaseModel):

    category: SpendingCategory = Field(
        description="General category of the expense"
    )

    subcategory: Optional[str] = Field(
        default=None,
        description="Specific subcategory inferred by the agent, e.g. 'audiovisual', 'delivery', 'sneakers'"
    )

    description: Optional[str] = Field(
        default=None,
        description="Name or short description of the product or service, e.g. 'DJI Osmo Pocket 3'"
    )

    amount: float = Field(
        gt=0,
        description="Total amount of the expense"
    )

    currency: Currency = Field(
        default=Currency.PEN,
        description="Currency of the expense. PEN for soles (default), USD for dollars. Infer from context: if the user says 'dólares', 'dollars' or '$', use USD."
    )

    quantity: int = Field(
        default=1,
        gt=0,
        description="Number of units purchased"
    )

    payment_method: Optional[PaymentMethod] = Field(
        default=None,
        description="Payment method used for the expense"
    )

    is_recurring: bool = Field(
        default=False,
        description="Whether this is a recurring/fixed expense like a subscription or rent"
    )

    date: Optional[date] = Field(
        default=None,
        description="Date of the expense, if different from today"
    )
