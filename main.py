from contextlib import asynccontextmanager
from typing import Annotated
from fastapi import Depends, FastAPI
from sqlmodel import Session, SQLModel, create_engine, select
from models import Transaction

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

@asynccontextmanager
async def lifespan(app: FastAPI):
    create_db_and_tables()
    yield
    engine.dispose()

app = FastAPI(lifespan=lifespan)

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


