from datetime import datetime
from enum import Enum
from typing import Optional
from sqlmodel import Field, SQLModel

class AccountType(str, Enum):
    CHECKING = "checking"
    SAVINGS = "savings"

class Account(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    account_name: str = Field(index=True)
    account_type: AccountType = Field()


class Transaction(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    date: str = Field(default=str(datetime.now().date), index=True)
    amount_dollars: int = Field()
    amount_cents: int = Field()
    account_id: int = Field(foreign_key="account.id")
    

