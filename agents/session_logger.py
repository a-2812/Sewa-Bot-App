import uuid
from datetime import datetime
import json
import os


class AgentSession:
    def __init__(self, session_id: str = None):
        self.session_id = session_id or f"sess_{datetime.now().strftime('%Y%m%d')}_{uuid.uuid4().hex[:8]}"
        self.logs = []
        self.created_at = datetime.now().isoformat()
        
        # Load existing if available
        self.filepath = os.path.join(os.path.dirname(__file__), "logs", f"{self.session_id}.json")
        if os.path.exists(self.filepath):
            with open(self.filepath, "r", encoding="utf-8") as f:
                data = json.load(f)
                self.logs = data.get("flow", [])
                self.created_at = data.get("created_at", self.created_at)

    def log(self, agent_name: str, input_data, reasoning: str, output_data, status: str = "success", duration_ms: int = 0):
        self.logs.append({
            "step": len(self.logs) + 1,
            "agent": agent_name,
            "timestamp": datetime.now().isoformat(),
            "input": input_data,
            "reasoning": reasoning,
            "output": output_data,
            "status": status,
            "duration_ms": duration_ms
        })

    def export(self) -> dict:
        return {
            "session_id": self.session_id,
            "created_at": self.created_at,
            "total_agents_run": len(self.logs),
            "flow": self.logs,
            "final_status": self.logs[-1]["status"] if self.logs else "empty"
        }

    def save_to_file(self):
        os.makedirs(os.path.dirname(self.filepath), exist_ok=True)
        with open(self.filepath, "w", encoding="utf-8") as f:
            json.dump(self.export(), f, indent=2, ensure_ascii=False)
        return self.filepath


def get_session(session_id: str) -> AgentSession | None:
    filepath = os.path.join(os.path.dirname(__file__), "logs", f"{session_id}.json")
    if os.path.exists(filepath):
        return AgentSession(session_id)
    return None
