import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import orchestrator

app = FastAPI(title="SewaBot Agents API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class IntentRequest(BaseModel):
    message: str


class ProvidersRequest(BaseModel):
    intent: dict


class QuoteRequest(BaseModel):
    intent: dict
    provider: dict


class BookingRequest(BaseModel):
    intent: dict
    provider: dict
    quote: dict


class DisputeRequest(BaseModel):
    booking_id: str
    type: str
    details: str


@app.get("/")
def health():
    return {"status": "ok", "service": "SewaBot Agents API", "version": "1.0.0"}


@app.post("/extractIntent")
async def extract_intent(req: IntentRequest):
    return orchestrator.run_intent(req.message)


@app.post("/getProviders")
async def get_providers(req: ProvidersRequest):
    return orchestrator.run_discovery_and_ranking(req.intent)


@app.post("/getPriceQuote")
async def get_price_quote(req: QuoteRequest):
    return orchestrator.run_quote(req.intent, req.provider)


@app.post("/executeBooking")
async def execute_booking(req: BookingRequest):
    return orchestrator.run_booking(req.intent, req.provider, req.quote)


@app.post("/submitDispute")
async def submit_dispute(req: DisputeRequest):
    return orchestrator.run_dispute(req.booking_id, req.type, req.details)


if __name__ == "__main__":
    uvicorn.run("main_api:app", host="0.0.0.0", port=8001, reload=True)
