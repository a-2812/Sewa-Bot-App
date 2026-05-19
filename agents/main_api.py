import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import orchestrator
from session_logger import get_session

app = FastAPI(title="SewaBot Agents API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None


class BookRequest(BaseModel):
    session_id: str
    provider_id: str
    slot: str


@app.get("/")
def health():
    return {"status": "ok", "service": "SewaBot Agents API", "version": "1.0.0"}


@app.post("/chat")
async def chat(req: ChatRequest):
    return orchestrator.run_chat(req.message, req.session_id)


@app.post("/book")
async def book(req: BookRequest):
    return orchestrator.run_book(req.session_id, req.provider_id, req.slot)


@app.get("/bookings/{booking_id}")
async def get_booking(booking_id: str):
    # Retrieve booking details from local storage or Firebase
    booking = orchestrator.get_booking(booking_id)
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return booking


@app.get("/providers")
async def get_providers(service: str = None, location: str = None, limit: int = 10):
    # Basic provider search endpoint
    return orchestrator.get_providers(service, location, limit)


@app.get("/agent-logs/{session_id}")
async def get_agent_logs(session_id: str):
    session = get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session log not found")
    return session.export()


if __name__ == "__main__":
    uvicorn.run("main_api:app", host="0.0.0.0", port=8001, reload=True)
