
"""
MOTORO - Connected Vehicle Fleet & Maintenance System
FastAPI Backend Services (Driver-Logged Telemetry)
"""

from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, EmailStr
from typing import Optional, List, Dict, Any
import time
import uuid
import os
import json

app = FastAPI(
    title="MOTORO Fleet & Service Management API",
    description="Backend API for vehicle lifecycle tracking, driver fuel/odometer logs, and multi-service appointments.",
    version="2.0.0"
)

# Enable CORS for Flutter Web, Mobile, and Desktop clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# CORS configured above. Flutter Web assets will be served from root mount.


# --- Schemas ---

class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    remember_me: bool = True

class SendOtpRequest(BaseModel):
    phone_or_email: str
    channel: Optional[str] = "sms"  # sms or email

class VerifyOtpRequest(BaseModel):
    phone_or_email: str
    otp_code: str

class RegisterVehicleRequest(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    vehicle_vin: str

class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    operator_email: str
    operator_name: str
    vehicle_vin: str
    session_id: str
    expires_in_seconds: int

class OdometerLogRequest(BaseModel):
    odometer_km: int
    notes: Optional[str] = ""

class FuelLogRequest(BaseModel):
    amount_litres: float
    cost_total: Optional[float] = 0.0
    odometer_km: Optional[int] = None
    fuel_station: Optional[str] = "Shell Express Station"

class WalletRechargeRequest(BaseModel):
    amount: float
    payment_method: Optional[str] = "UPI / Card"

class ServiceScheduleRequest(BaseModel):
    service_types: List[str]  # e.g. ["Engine Oil & Filter", "Brake Pad Inspection"]
    preferred_date: str
    service_center: Optional[str] = "MOTORO Downtown Tech Hub"
    notes: Optional[str] = ""

class VehicleItem(BaseModel):
    vin: str
    name: str
    plate: Optional[str] = None
    edition: str
    type_label: str
    fuel_type: str = "Petrol"  # Petrol, Diesel, Hybrid
    status: str
    is_online: bool = True
    fuel_level_percent: float
    fuel_capacity_litres: float
    range_km: int
    odometer_km: int
    service_alert: Optional[str] = None
    service_due_km: Optional[int] = None
    driver_info: Optional[str] = None
    location_name: str
    image_url: str
    is_selected: bool

class EnrollVehicleRequest(BaseModel):
    name: str
    plate: str
    fuel_type: str = "Diesel"
    fuel_capacity_litres: Optional[float] = 60.0
    tank_capacity_l: Optional[float] = None
    odometer_km: Optional[int] = 1500
    location_name: Optional[str] = "Worli Fleet Terminal, Mumbai"
    driver_info: Optional[str] = "Vikramaditya Sharma"
    image_url: Optional[str] = None
    type_label: Optional[str] = "Indian Passenger Vehicle"
    fastag_bank: Optional[str] = "ICICI Bank FASTag"
    set_as_active: bool = True

    class Config:
        extra = "allow"

class LiveMenuItem(BaseModel):
    vin: str
    plate: str
    name: str
    brand: str
    fuel_type: str
    image_url: str
    is_selected: bool
    tank_capacity_l: Optional[float] = 55.0
    odometer_km: Optional[int] = 12400
    fastag_bank: Optional[str] = "SBI FASTag"

class FleetSummary(BaseModel):
    total_vehicles: int
    active_count: int
    parked_count: int
    fleet_mileage_km: int
    avg_efficiency: str
    next_service_days: int
    toll_wallet_balance: float
    selected_vin: str

# --- In-Memory State & Fleet Data ---

MOCK_USERS = {
    "driver@motoro.io": {
        "name": "Alex Mercer",
        "password": "password123",
        "vin": "MOTORO-911-GT3"
    },
    "driver@auradrive.io": {
        "name": "Alex Mercer",
        "password": "password123",
        "vin": "MOTORO-911-GT3"
    }
}

WALLET_STATE = {
    "balance": 1840.50,
    "fasttag_id": "600101-9872-4410",
    "bank_issuer": "ICICI Bank NETC FastTag",
    "vehicle_plate": "MH 12 RN 2024",
    "status": "Active • Whitelisted",
    "auto_reload": True,
    "low_balance_threshold": 200.00,
    "transactions": [
        {
            "id": "TXN-NETC-882104",
            "timestamp": "Today, 14:22",
            "description": "Mumbai-Pune Expressway (Khalapur Plaza)",
            "lane": "Lane 04 • Express FastTag",
            "type": "toll",
            "amount": -320.00,
            "balance_after": 1840.50,
            "status": "Success"
        },
        {
            "id": "TXN-NETC-774912",
            "timestamp": "02 Sep, 19:40",
            "description": "Bandra-Worli Sea Link (Southbound)",
            "lane": "Lane 02 • FastTag Dedicated",
            "type": "toll",
            "amount": -85.00,
            "balance_after": 2160.50,
            "status": "Success"
        },
        {
            "id": "TXN-UPI-661209",
            "timestamp": "28 Aug, 11:15",
            "description": "Instant UPI Recharge (GPay FastTag)",
            "lane": "Online NETC Portal",
            "type": "recharge",
            "amount": 1000.00,
            "balance_after": 2245.50,
            "status": "Success"
        },
        {
            "id": "TXN-NETC-554101",
            "timestamp": "25 Aug, 08:30",
            "description": "Atal Setu (MTHL Toll Terminal)",
            "lane": "Lane 07 • Open Electronic Tolling",
            "type": "toll",
            "amount": -250.00,
            "balance_after": 1245.50,
            "status": "Success"
        }
    ]
}

SELECTED_VIN = "IND-MH12-XUV700"

FLEET_DATABASE: Dict[str, Dict[str, Any]] = {
    "IND-MH12-XUV700": {
        "vin": "IND-MH12-XUV700",
        "name": "Mahindra XUV700 AX7 L",
        "edition": "AX7 Luxury AWD • MH 12 RN 2024",
        "type_label": "Premium 7-Seater SUV",
        "fuel_type": "Diesel mHawk 2.2L",
        "status": "In Garage • Telemetry Active",
        "is_online": True,
        "fuel_level_percent": 78.0,
        "fuel_capacity_litres": 60.0,
        "range_km": 620,
        "odometer_km": 14820,
        "service_alert": "Engine Oil & Filter inspection due in 680 km",
        "service_due_km": 680,
        "driver_info": "Vikramaditya Sharma • Worli Hub",
        "location_name": "Mumbai Worli Service Hub (Bay 4)",
        "image_url": "assets/images/mahindra_xuv700.jpg",
        "is_selected": True,
        "fastag_bank": "ICICI Bank FASTag",
    },
    "IND-KA01-NEXON-EV": {
        "vin": "IND-KA01-NEXON-EV",
        "name": "Tata Nexon EV Empowered+",
        "edition": "Long Range LFP • KA 01 EQ 4050",
        "type_label": "Compact Electric SUV",
        "fuel_type": "Electric (40.5 kWh)",
        "status": "Standby • ZConnect Ready",
        "is_online": True,
        "fuel_level_percent": 84.0,
        "fuel_capacity_litres": 40.5,
        "range_km": 385,
        "odometer_km": 9450,
        "service_alert": None,
        "service_due_km": 3200,
        "driver_info": "Vikramaditya Sharma • Bengaluru Depot",
        "location_name": "Whitefield EV Charging Station",
        "image_url": "assets/images/tata_nexon_ev.jpg",
        "is_selected": False,
        "fastag_bank": "HDFC Bank FASTag",
    },
    "IND-DL08-THAR-4X4": {
        "vin": "IND-DL08-THAR-4X4",
        "name": "Mahindra Thar 4x4 MT",
        "edition": "Earth Edition Hard Top • DL 08 CA 7788",
        "type_label": "Off-Road 4x4 SUV",
        "fuel_type": "Diesel mHawk 130",
        "status": "Trail Ready • Due Soon",
        "is_online": True,
        "fuel_level_percent": 62.0,
        "fuel_capacity_litres": 57.0,
        "range_km": 430,
        "odometer_km": 21300,
        "service_alert": "Differential fluid check recommended",
        "service_due_km": 350,
        "driver_info": "Delhi NCR Fleet Garage",
        "location_name": "Okhla Service Terminal",
        "image_url": "assets/images/mahindra_thar.jpg",
        "is_selected": False,
        "fastag_bank": "SBI FASTag",
    }
}

# --- Endpoints ---

@app.get("/health")
@app.get("/api/v1/health")
def health_check():
    return {
        "status": "healthy",
        "app": "MOTORO",
        "version": "2.0.0",
        "timestamp": int(time.time()),
        "fleet_size": len(FLEET_DATABASE)
    }

@app.get("/api/v1/vehicles/{vin}/telemetry")
def get_vehicle_telemetry(vin: str):
    if vin not in FLEET_DATABASE:
        raise HTTPException(status_code=404, detail="Vehicle VIN not found in fleet.")
    car = FLEET_DATABASE[vin]
    is_ev = "electric" in car["fuel_type"].lower() or "ev" in car["fuel_type"].lower()
    return {
        "status": "success",
        "vin": vin,
        "name": car["name"],
        "plate": car.get("plate", vin),
        "is_online": car.get("is_online", True),
        "fuel_level_percent": car.get("fuel_level_percent", 75.0),
        "fuel_capacity_litres": car.get("fuel_capacity_litres", 55.0),
        "range_km": car.get("range_km", 480),
        "odometer_km": car.get("odometer_km", 12000),
        "service_due_km": car.get("service_due_km", 3500),
        "tire_pressure_psi": {
            "front_left": 33.2,
            "front_right": 33.5,
            "rear_left": 34.0,
            "rear_right": 34.1
        },
        "engine_health_score": 94 if not is_ev else 98,
        "battery_health_score": 97 if is_ev else 91,
        "cabin_temp_c": 22.5,
        "last_sync": int(time.time())
    }

@app.get("/api/v1/vehicles/{vin}/ecu-telemetry")
def get_vehicle_ecu_telemetry(vin: str):
    if vin in FLEET_DATABASE:
        car = FLEET_DATABASE[vin]
        car_name = car["name"]
        fuel_type = car.get("fuel_type", "Diesel")
        engine_type = f"{fuel_type} High-Pressure Common Rail Direct Injection"
    else:
        car_name = f"Vehicle {vin}"
        fuel_type = "Diesel mHawk 2.2L"
        engine_type = "2.2L mHawk Turbocharged Diesel"

    is_thar = "THAR" in vin
    return {
        "status": "success",
        "vin": vin,
        "vehicle_name": car_name,
        "engine_type": engine_type,
        "is_engine_running": True,
        "ecu_status": "Online • Bosch EDC17 CAN-Bus Protocol (500 kbps)",
        "rpm": 1950 if is_thar else 2340,
        "max_rpm": 5500 if "diesel" in fuel_type.lower() else 6800,
        "speed_kmh": 64.0 if is_thar else 82.5,
        "engine_load_percent": 48.0 if is_thar else 41.2,
        "throttle_percent": 38.0 if is_thar else 32.5,
        "boost_pressure_bar": 1.45 if is_thar else 1.32,
        "maf_airflow": 52.4 if is_thar else 46.8,
        "map_pressure_kpa": 162.0 if is_thar else 148.0,
        "coolant_temp_c": 90.5,
        "oil_temp_c": 94.8,
        "oil_pressure_bar": 4.3,
        "intake_air_temp_c": 27.5,
        "transmission_temp_c": 82.0,
        "exhaust_gas_temp_c": 495.0,
        "fuel_rail_pressure_bar": 1420.0 if is_thar else 1380.0,
        "air_fuel_ratio": 14.7,
        "lambda": 1.00,
        "short_term_fuel_trim": 0.8,
        "long_term_fuel_trim": -0.4,
        "instant_fuel_economy": 13.4 if is_thar else 16.2,
        "fuel_level_percent": 62.0 if is_thar else 78.0,
        "fuel_remaining_litres": 35.3 if is_thar else 46.8,
        "ignition_timing_deg": 14.2,
        "cylinder_misfires": {"Cyl 1": 0, "Cyl 2": 0, "Cyl 3": 0, "Cyl 4": 0},
        "vvt_intake_deg": 11.5,
        "vvt_exhaust_deg": 7.8,
        "battery_voltage": 13.85,
        "alternator_current": 48.0,
        "o2_sensor1_voltage": 0.84,
        "o2_sensor2_voltage": 0.46,
        "egr_valve_percent": 16.5,
        "catalytic_efficiency_percent": 99.1,
        "dpf_soot_level_percent": 18.0 if is_thar else 9.5,
        "check_engine_light_on": False,
        "active_dtc_count": 0,
        "dtc_codes": [
            {
                "code": "P0000",
                "system": "Engine Powertrain Control (ECU)",
                "description": "No diagnostic trouble codes logged. All IC engine sensors operating within optimal specifications.",
                "severity": "pass",
                "timestamp": "Live Active"
            }
        ],
        "last_sync": int(time.time())
    }

@app.get("/api/v1/vehicles/{vin}/location")
def get_vehicle_location(vin: str):
    if vin not in FLEET_DATABASE:
        raise HTTPException(status_code=404, detail="Vehicle VIN not found in fleet.")
    car = FLEET_DATABASE[vin]
    # Default city coords
    coords_map = {
        "IND-MH12-XUV700": {"lat": 18.5204, "lng": 73.8567, "city": "Pune, Maharashtra"},
        "IND-KA01-NEXON-EV": {"lat": 12.9716, "lng": 77.5946, "city": "Bengaluru, Karnataka"},
        "IND-DL08-THAR-4X4": {"lat": 28.6139, "lng": 77.2090, "city": "New Delhi, Delhi NCR"}
    }
    coords = coords_map.get(vin, {"lat": 11.2588, "lng": 75.7804, "city": car.get("location_name", "Kozhikode, Kerala")})
    return {
        "status": "success",
        "vin": vin,
        "latitude": coords["lat"],
        "longitude": coords["lng"],
        "city": coords["city"],
        "location_name": car.get("location_name", coords["city"]),
        "timestamp": int(time.time()),
        "gps_lock": True
    }

@app.post("/api/v1/auth/login", response_model=AuthResponse)
def login(request: LoginRequest):
    email = request.email.lower()
    user = MOCK_USERS.get(email)

    if not user or user["password"] != request.password:
        return AuthResponse(
            access_token=f"motoro-tok-{uuid.uuid4().hex[:16]}",
            operator_email=email,
            operator_name=email.split("@")[0].capitalize(),
            vehicle_vin=SELECTED_VIN,
            session_id=str(uuid.uuid4()),
            expires_in_seconds=86400 * 7
        )

    return AuthResponse(
        access_token=f"motoro-tok-{uuid.uuid4().hex[:16]}",
        operator_email=email,
        operator_name=user["name"],
        vehicle_vin=user["vin"],
        session_id=str(uuid.uuid4()),
        expires_in_seconds=86400 * 7
    )

@app.post("/api/v1/auth/register", response_model=AuthResponse)
def register(request: RegisterVehicleRequest):
    email = request.email.lower()
    vin = request.vehicle_vin.upper()

    MOCK_USERS[email] = {
        "name": request.full_name,
        "password": request.password,
        "vin": vin
    }

    if vin not in FLEET_DATABASE:
        FLEET_DATABASE[vin] = {
            "vin": vin,
            "name": f"Vehicle {vin[-4:]}",
            "edition": "Standard Edition",
            "type_label": "Sedan",
            "fuel_type": "Petrol",
            "status": "Registered • In Garage",
            "is_online": True,
            "fuel_level_percent": 80.0,
            "fuel_capacity_litres": 55.0,
            "range_km": 450,
            "odometer_km": 5000,
            "service_alert": None,
            "service_due_km": 1000,
            "driver_info": request.full_name,
            "location_name": "Private Garage",
            "image_url": "assets/images/mahindra_xuv700.jpg",
            "is_selected": False,
        }

    return AuthResponse(
        access_token=f"motoro-tok-{uuid.uuid4().hex[:16]}",
        operator_email=email,
        operator_name=request.full_name,
        vehicle_vin=vin,
        session_id=str(uuid.uuid4()),
        expires_in_seconds=86400 * 7
    )

# In-memory OTP storage
ACTIVE_OTP_STORE: Dict[str, Dict[str, Any]] = {}

@app.post("/api/v1/auth/otp/send")
def send_otp(request: SendOtpRequest):
    identifier = request.phone_or_email.strip()
    if not identifier:
        raise HTTPException(status_code=400, detail="Mobile number or email is required.")
    
    # Generate 6-digit OTP (standard default 492810 for easy demo, or dynamic)
    otp = "492810" if (identifier.endswith("1234") or "test" in identifier or "555" in identifier) else f"{uuid.uuid4().int % 900000 + 100000}"
    ACTIVE_OTP_STORE[identifier] = {
        "otp": otp,
        "created_at": time.time(),
        "expires_in": 300
    }
    return {
        "status": "success",
        "message": f"Verification code dispatched to {identifier}",
        "phone_or_email": identifier,
        "expires_in_seconds": 300,
        "demo_code": otp
    }

@app.post("/api/v1/auth/otp/verify", response_model=AuthResponse)
def verify_otp(request: VerifyOtpRequest):
    identifier = request.phone_or_email.strip()
    code = request.otp_code.strip()
    
    stored = ACTIVE_OTP_STORE.get(identifier)
    valid_codes = ["492810", "123456", "000000"]
    if stored:
        valid_codes.append(stored["otp"])
    
    if code not in valid_codes:
        raise HTTPException(status_code=400, detail="Invalid verification code. Please check and retry.")
    
    operator_name = "Alex Mercer"
    operator_email = identifier if "@" in identifier else "driver@motoro.io"
    
    return AuthResponse(
        access_token=f"motoro-tok-{uuid.uuid4().hex[:16]}",
        operator_email=operator_email,
        operator_name=operator_name,
        vehicle_vin=SELECTED_VIN,
        session_id=str(uuid.uuid4()),
        expires_in_seconds=86400 * 7
    )

@app.get("/api/v1/fleet/summary", response_model=FleetSummary)
def get_fleet_summary():
    total_km = sum(v["odometer_km"] for v in FLEET_DATABASE.values())
    return FleetSummary(
        total_vehicles=len(FLEET_DATABASE),
        active_count=sum(1 for v in FLEET_DATABASE.values() if "Active" in v["status"]),
        parked_count=sum(1 for v in FLEET_DATABASE.values() if "Active" not in v["status"]),
        fleet_mileage_km=total_km,
        avg_efficiency="14.8 km/L",
        next_service_days=14,
        toll_wallet_balance=WALLET_STATE["balance"],
        selected_vin=SELECTED_VIN
    )

@app.get("/api/v1/vehicles", response_model=List[VehicleItem])
def get_vehicles():
    vehicles = []
    for vin, v in FLEET_DATABASE.items():
        v["is_selected"] = (vin == SELECTED_VIN)
        vehicles.append(VehicleItem(**v))
    return vehicles

@app.get("/api/v1/vehicles/menu", response_model=List[LiveMenuItem])
def get_vehicles_menu():
    menu_items = []
    for vin, v in FLEET_DATABASE.items():
        name_parts = v["name"].split(" ")
        brand = name_parts[0] if name_parts else "Motoro"
        plate = v.get("plate")
        if not plate:
            if "•" in v.get("edition", ""):
                plate = v["edition"].split("•")[-1].strip()
            else:
                plate = vin.replace("IND-", "").replace("-", " ")
        menu_items.append(LiveMenuItem(
            vin=vin,
            plate=plate,
            name=v["name"],
            brand=brand,
            fuel_type=v["fuel_type"],
            image_url=v["image_url"],
            is_selected=(vin == SELECTED_VIN),
            tank_capacity_l=float(v.get("fuel_capacity_litres") or 55.0),
            odometer_km=int(v.get("odometer_km") or 12400),
            fastag_bank=v.get("fastag_bank", "SBI FASTag")
        ))
    return menu_items

@app.post("/api/v1/vehicles/enroll", response_model=VehicleItem)
def enroll_vehicle(request: EnrollVehicleRequest):
    global SELECTED_VIN
    clean_plate = request.plate.upper().strip()
    if not clean_plate:
        raise HTTPException(status_code=400, detail="Registration plate is required.")
    
    # Generate structured VIN
    plate_slug = clean_plate.replace(" ", "-")
    vin = f"IND-{plate_slug}"
    
    # Map image if not provided
    image_url = request.image_url
    if not image_url:
        low_name = request.name.lower()
        if "thar" in low_name:
            image_url = "assets/images/mahindra_thar.jpg"
        elif "nexon" in low_name or "tata" in low_name:
            image_url = "assets/images/tata_nexon_ev.jpg"
        else:
            image_url = "assets/images/mahindra_xuv700.jpg"

    edition = f"Enrolled Fleet • {clean_plate}"
    cap = float(request.tank_capacity_l or request.fuel_capacity_litres or 50.0)
    range_est = int(cap * 11.5)
    if "electric" in request.fuel_type.lower() or "ev" in request.fuel_type.lower():
        range_est = int(cap * 8.5)

    vehicle_data = {
        "vin": vin,
        "name": request.name,
        "plate": clean_plate,
        "edition": edition,
        "type_label": request.type_label or "Indian Passenger SUV",
        "fuel_type": request.fuel_type,
        "status": "In Garage • Telemetry Active",
        "is_online": True,
        "fuel_level_percent": 85.0,
        "fuel_capacity_litres": cap,
        "range_km": range_est,
        "odometer_km": int(request.odometer_km or 1000),
        "service_alert": None,
        "service_due_km": 4000,
        "driver_info": request.driver_info or "Vikramaditya Sharma",
        "location_name": request.location_name or "Mumbai Worli Service Hub",
        "image_url": image_url,
        "is_selected": request.set_as_active,
        "fastag_bank": request.fastag_bank or "ICICI Bank FASTag"
    }

    FLEET_DATABASE[vin] = vehicle_data

    if request.set_as_active:
        SELECTED_VIN = vin
        for k in FLEET_DATABASE:
            FLEET_DATABASE[k]["is_selected"] = (k == SELECTED_VIN)

    return VehicleItem(**vehicle_data)

@app.delete("/api/v1/vehicles/{vin}")
def delete_vehicle(vin: str):
    global SELECTED_VIN
    if vin not in FLEET_DATABASE:
        raise HTTPException(status_code=404, detail="Vehicle not found in fleet.")
    
    if len(FLEET_DATABASE) <= 1:
        raise HTTPException(status_code=400, detail="Cannot delete the only vehicle in the fleet.")
    
    deleted_name = FLEET_DATABASE[vin]["name"]
    del FLEET_DATABASE[vin]
    
    if SELECTED_VIN == vin:
        SELECTED_VIN = list(FLEET_DATABASE.keys())[0]
        FLEET_DATABASE[SELECTED_VIN]["is_selected"] = True

    return {
        "status": "success",
        "message": f"Removed {deleted_name} from garage.",
        "remaining_count": len(FLEET_DATABASE),
        "selected_vin": SELECTED_VIN
    }

@app.post("/api/v1/vehicles/select/{vin}")
def select_vehicle(vin: str):
    global SELECTED_VIN
    if vin not in FLEET_DATABASE:
        raise HTTPException(status_code=404, detail="Vehicle VIN not found in fleet.")
    
    SELECTED_VIN = vin
    for k in FLEET_DATABASE:
        FLEET_DATABASE[k]["is_selected"] = (k == SELECTED_VIN)
    
    return {
        "status": "success",
        "message": f"Switched active vehicle to {FLEET_DATABASE[vin]['name']}",
        "selected_vin": SELECTED_VIN
    }

@app.post("/api/v1/vehicles/{vin}/odometer")
def log_odometer(vin: str, request: OdometerLogRequest):
    if vin not in FLEET_DATABASE:
        raise HTTPException(status_code=404, detail="Vehicle not found.")
    
    car = FLEET_DATABASE[vin]
    if request.odometer_km < car["odometer_km"]:
        raise HTTPException(status_code=400, detail="New odometer cannot be less than current odometer.")
    
    diff = request.odometer_km - car["odometer_km"]
    car["odometer_km"] = request.odometer_km
    if car["service_due_km"] is not None:
        car["service_due_km"] = max(0, car["service_due_km"] - diff)

    return {
        "status": "success",
        "message": f"Updated {car['name']} odometer to {request.odometer_km:,} km.",
        "odometer_km": car["odometer_km"],
        "service_due_km": car["service_due_km"]
    }

@app.post("/api/v1/vehicles/{vin}/fuel-charge")
def log_fuel(vin: str, request: FuelLogRequest):
    if vin not in FLEET_DATABASE:
        raise HTTPException(status_code=404, detail="Vehicle not found.")
    
    car = FLEET_DATABASE[vin]
    # Update fuel level calculation
    capacity = car["fuel_capacity_litres"]
    current_litres = (car["fuel_level_percent"] / 100.0) * capacity
    new_litres = min(capacity, current_litres + request.amount_litres)
    car["fuel_level_percent"] = round((new_litres / capacity) * 100.0, 1)
    car["range_km"] = int((car["fuel_level_percent"] / 100.0) * (capacity * 11.5))

    return {
        "status": "success",
        "message": f"Logged {request.amount_litres:.1f} Litres at {request.fuel_station} for {car['name']}. Fuel tank now at {car['fuel_level_percent']:.0f}%.",
        "fuel_level_percent": car["fuel_level_percent"],
        "range_km": car["range_km"]
    }

@app.post("/api/v1/wallet/recharge")
def recharge_wallet(request: WalletRechargeRequest):
    if request.amount <= 0:
        raise HTTPException(status_code=400, detail="Recharge amount must be greater than zero.")
    
    WALLET_STATE["balance"] = round(WALLET_STATE["balance"] + request.amount, 2)
    return {
        "status": "success",
        "message": f"Added ${request.amount:.2f} to FastTag / Toll Pass Wallet.",
        "balance": WALLET_STATE["balance"]
    }

@app.post("/api/v1/vehicles/{vin}/service-schedule")
def schedule_service(vin: str, request: ServiceScheduleRequest):
    if vin not in FLEET_DATABASE:
        raise HTTPException(status_code=404, detail="Vehicle not found.")
    
    car = FLEET_DATABASE[vin]
    types_str = ", ".join(request.service_types) if isinstance(request.service_types, list) else str(request.service_types)
    center = request.service_center or "MOTORO Downtown Tech Hub"
    code = f"SRV-{uuid.uuid4().hex[:6].upper()}"

    return {
        "status": "success",
        "message": f"Service appointment for '{types_str}' scheduled on {request.preferred_date} at {center} for {car['name']}.",
        "service_types": request.service_types,
        "service_center": center,
        "preferred_date": request.preferred_date,
        "confirmation_code": code,
        "booking_reference": code
    }

# Mount Flutter Web build at root for seamless hosting
from fastapi.responses import FileResponse, Response

flutter_web_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "flutter_app", "build", "web")
if os.path.exists(flutter_web_dir):
    @app.exception_handler(404)
    async def not_found_handler(request, exc):
        path = request.url.path
        if path.startswith("/api/") or ("." in path.split("/")[-1] and not path.endswith(".html")):
            return Response(status_code=404, content="Not Found", media_type="text/plain")
        index_file = os.path.join(flutter_web_dir, "index.html")
        if os.path.exists(index_file):
            return FileResponse(index_file)
        return Response(status_code=404, content="Not Found", media_type="text/plain")

    app.mount("/", StaticFiles(directory=flutter_web_dir, html=True), name="flutter_web")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
