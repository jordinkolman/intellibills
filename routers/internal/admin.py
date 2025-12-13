from plaid.model.link_token_create_request import LinkTokenCreateRequest
from plaid.model.link_token_create_request_user import LinkTokenCreateRequestUser
from plaid.model.products import Products
from plaid.model.country_code import CountryCode
from fastapi import APIRouter

app = APIRouter(
        prefix="/admin",
        tags=["admin", "auth"]
        )

@app.post("/create_link_token")
async def create_link_token():
    user = {"id": 1}
    client_user_id = user["id"]

    request = LinkTokenCreateRequest(
            products = [Products("auth")],
            client_name = "Indibills Personal Finance",
            country_codes = [CountryCode("US")],
            user = LinkTokenCreateRequestUser(client_user_id = client_user_id)
            )




