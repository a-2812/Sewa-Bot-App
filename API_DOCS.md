# SewaBot API Documentation

This document outlines all the endpoints available in the SewaBot backend for the mobile app developer.

---

## 1. System Health

### `GET /` (Health Check)
Check the system health and API version.

**Request Body:**
None

**Response Example:**
```json
{
  "status": "ok",
  "timestamp": "2026-05-19T04:58:41+00:00",
  "version": "2.0.0"
}
```

---

## 2. Providers

### `GET /providers` (List All Providers)
Return the full provider catalogue with optional filters.

**Query Parameters:**
- `service` (string, optional): Filter by service category (e.g., 'Plumber', 'AC Technician').
- `city` (string, optional): Filter by city.
- `verified_only` (boolean, optional): Return only verified providers.

**Request Body:**
None

**Response Example:**
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

### `POST /search` (Search Providers by Service + Location)
Find providers within a specific radius of the user offering the requested service.

**Request Body:**
```json
{
  "service_type": "Plumber",
  "user_lat": 33.6844,
  "user_lon": 73.0479,
  "location": "Islamabad",
  "radius_km": 50.0
}
```

**Response Example:**
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

**Common Error Codes:**
- `404 Not Found`: No providers found for the given service.
- `422 Unprocessable Entity`: Validation error in request body.

### `POST /rank` (Rank Providers by Composite Score)
Rank a list of providers using SewaBot's weighted scoring model.

**Request Body:**
```json
{
  "providers_list": [
    {
      "id": "p001",
      "name": "Ahmed Raza",
      "rating": 4.8,
      "available": true,
      "verified": true,
      "location": {
        "lat": 33.6844, 
        "lng": 73.0479
      }
    }
  ],
  "user_lat": 33.6844,
  "user_lon": 73.0479
}
```

**Response Example:**
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

**Common Error Codes:**
- `422 Unprocessable Entity`: `providers_list` cannot be empty.

---

## 3. Bookings

### `POST /book` (Create a Booking)
Create a new service booking.

**Request Body:**
```json
{
  "provider_id": "p008",
  "user_name": "Ali Khan",
  "user_phone": "+92-300-1234567",
  "service_type": "Plumber",
  "time_slot": "2026-05-20T10:00:00Z",
  "location": "House 12, Street 5, F-8, Islamabad",
  "notes": "Please come early"
}
```

**Response Example:**
```json
{
  "booking_id": "BK-1A2B3C4D5E",
  "status": "confirmed",
  "message": "Booking confirmed with Ahmed Raza. They will contact you at +92-300-1234567.",
  "created_at": "2026-05-19T04:58:41+00:00",
  "receipt": "--- SewaBot Booking Receipt ---\nBooking ID: BK-1A2B3C4D5E\n..."
}
```

**Common Error Codes:**
- `404 Not Found`: Provider does not exist.
- `409 Conflict`: Provider is currently unavailable.
- `422 Unprocessable Entity`: Validation error in request body.

### `GET /bookings/{booking_id}` (Get Booking Details)
Retrieve full details for a single booking by its ID.

**Path Parameters:**
- `booking_id` (string): The ID of the booking to retrieve.

**Request Body:**
None

**Response Example:**
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

**Common Error Codes:**
- `404 Not Found`: Booking not found.

### `GET /bookings` (List All Bookings)
Return all persisted bookings, optionally filtered by status.

**Query Parameters:**
- `status` (string, optional): Filter by status (e.g., 'confirmed', 'cancelled').

**Request Body:**
None

**Response Example:**
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

### `POST /notify` (Simulate WhatsApp Notification)
Simulate sending a WhatsApp notification to a provider or customer.

**Request Body:**
```json
{
  "recipient_phone": "+92-300-1234567",
  "message": "Your booking is confirmed!"
}
```

**Response Example:**
```json
{
  "status": "sent",
  "message_id": "MSG-A1B2C3D4",
  "timestamp": "2026-05-19T04:58:41+00:00"
}
```

**Common Error Codes:**
- `422 Unprocessable Entity`: Validation error in request body.

---

## 5. Agents

### `GET /agent-logs` (Get Agent Reasoning Traces)
Retrieve the most recent agent reasoning traces.

**Query Parameters:**
- `limit` (integer, optional): Maximum number of recent logs to return (default: 50).

**Request Body:**
None

**Response Example:**
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
