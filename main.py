from datetime import datetime
from enum import Enum
from typing import Annotated, Literal, Optional
from fastapi import Depends, FastAPI
from pydantic import BaseModel
from sqlmodel import Field, Session, SQLModel, Relationship, create_engine, select, true


class AccountType(str, Enum):
    CHECKING = "checking"
    SAVINGS = "savings"

class Account(SQLModel, table=True):
    id: str | None = Field(default=None, primary_key=True)
    account_name: str = Field(index=True)
    account_type: AccountType = Field()


class Transaction(SQLModel, table=True):
    id: str | None = Field(default=None, primary_key=True)
    date: datetime = Field(default=datetime.now(), index=True)
    amount_dollars: int = Field()
    amount_cents: int = Field()
    account_id: int = Field(foreign_key="account.id")


sqlite_file_name = "database.db"
sqlite_url = f"sqlite:///{sqlite_file_name}"

connect_args = {"check_same_thread": False}
engine = create_engine(sqlite_url, connect_args=connect_args)

def get_session():
    with Session(engine) as session:
        yield session

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

SessionDep = Annotated[Session, Depends(get_session)]

app = FastAPI()

@app.on_event("startup")
def on_startup():
    create_db_and_tables()

@app.get("/")
async def root():
    return {"message" : "Hello World"}

@app.get("/transactions/")
async def get_all_transactions(session: SessionDep):
    transactions = session.exec(select(Transaction).offset(0).limit(100)).all()
    return transactions

@app.post("/transactions/")
async def create_transaction(transaction: Transaction, session: SessionDep) -> Transaction:
    session.add(transaction)
    session.commit()
    session.refresh(transaction)
    return transaction


