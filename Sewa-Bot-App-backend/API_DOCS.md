# SewaBot API Documentation

Welcome to the SewaBot backend API documentation. This reference guide outlines all available endpoints to help mobile and web developers seamlessly integrate with the SewaBot service orchestrator.

## Base URL
```text
http://localhost:8000
```
*(In production, replace with your live domain, e.g., `https://api.sewabot.pk`)*

## Authentication
Currently, the SewaBot API is **unauthenticated** and open for development. No API keys or Bearer tokens are required in the headers for any of the endpoints. Future iterations will introduce OAuth2/JWT token-based authentication.

## Rate Limiting & Timeouts
To ensure system stability, the following constraints are actively enforced:
- **Rate Limit**: All endpoints are strictly limited to **10 requests per minute per IP address**. Exceeding this will result in a `429 Too Many Requests` response.
- **Timeout**: Requests that take longer than **5 seconds** to process will automatically abort and return a `504 Gateway Timeout`.

---

## Global Error Code Table

| Status Code | Error Title | Description |
|---|---|---|
| `400` | Bad Request | The request was malformed or missing required logic parameters. |
| `404` | Not Found | The requested resource (provider, booking, endpoint) does not exist. |
| `409` | Conflict | The resource state conflicts with the request (e.g., booking an unavailable provider). |
| `422` | Unprocessable Entity | Validation error on the request body or path parameters (e.g., incorrect ID format). |
| `429` | Too Many Requests | Rate limit exceeded (10 requests/minute per IP). |
| `500` | Internal Server Error | An unexpected server crash occurred. |
| `503` | Service Unavailable | Database (Firestore) connection failure or external service down. |
| `504` | Gateway Timeout | The request processing took longer than 5 seconds. |

---

## 1. System

### `GET /`
Check the system health and API version.

**Example cURL:**
```bash
curl -X GET "http://localhost:8000/" -H "accept: application/json"
```

**Response (200 OK):**
```json
{
  "status": "ok",
  "timestamp": "2026-05-19T04:58:41+00:00",
  "version": "2.0.0"
}
```

---

### `GET /admin`
Returns the HTML dashboard for administrative overview.

**Example cURL:**
```bash
curl -X GET "http://localhost:8000/admin"
```

*(Returns a compiled HTML response)*

---

## 2. Providers

### `GET /providers`
Return the full provider catalogue with optional filters.

**Query Parameters:**
- `service` (string, optional): Filter by service category (e.g., 'Plumber', 'AC Technician').
- `city` (string, optional): Filter by city.
- `verified_only` (boolean, optional): Return only verified providers.

**Example cURL:**
```bash
curl -X GET "http://localhost:8000/providers?service=Plumber&verified_only=true" -H "accept: application/json"
```

**Response (200 OK):**
```json
{
  "total": 1,
  "providers": [
    {
      "id": "p001",
      "name": "Ahmed Raza",
      "service": "Plumber",
      "price_pkr": 1500,
      "verified": true,
      "available": true,
      "location": {
        "lat": 33.6844, 
        "lng": 73.0479, 
        "city": "Islamabad"
      }
    }
  ]
}
```

---

### `POST /search`
Find providers within a specific radius of the user offering the requested service. Sorted by nearest first.

**Example cURL:**
```bash
curl -X POST "http://localhost:8000/search" \
     -H "accept: application/json" \
     -H "Content-Type: application/json" \
     -d '{
           "service_type": "Plumber",
           "user_lat": 33.6844,
           "user_lon": 73.0479,
           "location": "Islamabad",
           "radius_km": 50.0
         }'
```

**Response (200 OK):**
```json
{
  "total": 1,
  "search_params": {
    "service_type": "Plumber",
    "user_lat": 33.6844,
    "user_lon": 73.0479,
    "location": "Islamabad",
    "radius_km": 50.0
  },
  "providers": [
    {
      "id": "p001",
      "name": "Ahmed Raza",
      "service": "Plumber",
      "distance_km": 2.5
    }
  ]
}
```

---

### `POST /rank`
Rank a list of providers using SewaBot's weighted scoring model (Distance 40%, Rating 35%, Availability 15%, Verified 10%).

**Example cURL:**
```bash
curl -X POST "http://localhost:8000/rank" \
     -H "accept: application/json" \
     -H "Content-Type: application/json" \
     -d '{
           "providers_list": [
             {
               "id": "p001",
               "name": "Ahmed Raza",
               "rating": 4.8,
               "available": true,
               "verified": true,
               "location": { "lat": 33.6844, "lng": 73.0479 }
             }
           ],
           "user_lat": 33.6844,
           "user_lon": 73.0479
         }'
```

**Response (200 OK):**
```json
{
  "total": 1,
  "weights": {
    "distance": "40%",
    "rating": "35%",
    "availability": "15%",
    "verified": "10%"
  },
  "providers": [
    {
      "id": "p001",
      "name": "Ahmed Raza",
      "distance_km": 0.0,
      "score": 0.986,
      "score_breakdown": {
        "distance": 0.4,
        "rating": 0.336,
        "availability": 0.15,
        "verified": 0.1
      }
    }
  ]
}
```

---

## 3. Bookings

### `POST /book`
Create a new service booking.

**Example cURL:**
```bash
curl -X POST "http://localhost:8000/book" \
     -H "accept: application/json" \
     -H "Content-Type: application/json" \
     -d '{
           "provider_id": "p008",
           "user_name": "Ali Khan",
           "user_phone": "+92-300-1234567",
           "service_type": "Plumber",
           "time_slot": "2026-05-20T10:00:00Z",
           "location": "House 12, Street 5, F-8, Islamabad",
           "notes": "Please come early"
         }'
```

**Response (201 Created):**
```json
{
  "booking_id": "BK-1A2B3C4D5E",
  "status": "confirmed",
  "message": "Booking confirmed with Ahmed Raza. They will contact you at +92-300-1234567.",
  "created_at": "2026-05-19T04:58:41+00:00",
  "receipt": "--- SewaBot Booking Receipt ---\nBooking ID: BK-1A2B3C4D5E\n..."
}
```

---

### `GET /bookings/{booking_id}`
Retrieve full details for a single booking by its ID. Must follow the format `BK-XXXXXXXXXX` (where X is an uppercase hex character).

**Example cURL:**
```bash
curl -X GET "http://localhost:8000/bookings/BK-1A2B3C4D5E" -H "accept: application/json"
```

**Response (200 OK):**
```json
{
  "booking_id": "BK-1A2B3C4D5E",
  "status": "confirmed",
  "provider": {
    "id": "p008",
    "name": "Ahmed Raza",
    "service": "Plumber",
    "phone": "+92-333-1234567",
    "price_pkr": 1500
  },
  "customer": {
    "name": "Ali Khan",
    "phone": "+92-300-1234567"
  },
  "service_type": "Plumber",
  "time_slot": "2026-05-20T10:00:00Z",
  "location": "House 12, Street 5, F-8, Islamabad"
}
```

---

### `GET /bookings`
Return all persisted bookings, optionally filtered by status.

**Query Parameters:**
- `status` (string, optional): Filter by status (e.g., 'confirmed', 'cancelled').

**Example cURL:**
```bash
curl -X GET "http://localhost:8000/bookings?status=confirmed" -H "accept: application/json"
```

**Response (200 OK):**
```json
{
  "total": 1,
  "bookings": [
    {
      "booking_id": "BK-1A2B3C4D5E",
      "status": "confirmed",
      "service_type": "Plumber",
      "time_slot": "2026-05-20T10:00:00Z"
    }
  ]
}
```

---

## 4. Notifications

### `POST /notify`
Simulate sending a WhatsApp notification to a provider or customer.

**Example cURL:**
```bash
curl -X POST "http://localhost:8000/notify" \
     -H "accept: application/json" \
     -H "Content-Type: application/json" \
     -d '{
           "recipient_phone": "+92-300-1234567",
           "message": "Your booking is confirmed!"
         }'
```

**Response (200 OK):**
```json
{
  "status": "sent",
  "message_id": "MSG-A1B2C3D4",
  "timestamp": "2026-05-19T04:58:41+00:00"
}
```

---

## 5. Agents

### `GET /agent-logs`
Retrieve the most recent agent reasoning traces.

**Query Parameters:**
- `limit` (integer, optional): Maximum number of recent logs to return (default: 50).

**Example cURL:**
```bash
curl -X GET "http://localhost:8000/agent-logs?limit=5" -H "accept: application/json"
```

**Response (200 OK):**
```json
{
  "total": 1,
  "logs": [
    {
      "timestamp": "2026-05-19T04:58:41+00:00",
      "agent_name": "Booking Agent",
      "action": "Select Provider",
      "reasoning": "Provider p008 selected due to high rating and proximity."
    }
  ]
}
```
