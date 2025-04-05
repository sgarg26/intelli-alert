from pydantic import BaseModel
from typing import List, Optional

class EmergencyContact(BaseModel):
    id: str
    name: str
    relationship: str
    phoneNumber: str

class MedicalInfo(BaseModel):
    conditions: List[str]
    allergies: List[str]
    medications: List[str]
    bloodType: str
    organDonor: bool

class EmergencyPreferences(BaseModel):
    preferredHospital: str
    doctorName: str
    doctorPhone: str
    specialInstructions: str

class LocationInfo(BaseModel):
    homeAddress: str
    workAddress: str
    otherFrequentLocations: List[str]

class UserEmergencyProfile(BaseModel):
    fullName: str
    dateOfBirth: int
    phoneNumber: str
    emergencyContacts: List[EmergencyContact]
    medicalInfo: MedicalInfo
    emergencyPreferences: EmergencyPreferences
    locationInfo: LocationInfo


# Request models
class CallRequest(BaseModel):
    to: str
    initialMessage: Optional[str] = "Hello, this is an automated call."