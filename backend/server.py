from fastapi import FastAPI
from twilio.rest import Client
from dotenv import load_dotenv
import datetime
from typing import Dict, List, Any
from twilio.rest import Client
from twilio.twiml.voice_response import VoiceResponse, Gather
import os

load_dotenv()
# local imports 
from models import CallRequest, MedicalInfo, EmergencyContact, EmergencyPreferences, LocationInfo, UserEmergencyProfile
from utils import completions
from fastapi import FastAPI, Request, WebSocket, WebSocketDisconnect, Response, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware


app = FastAPI()
account_sid = os.environ.get("TWILIO_ACCOUNT_SID")
auth_token = os.environ.get("TWILIO_AUTH_TOKEN")
client = Client(account_sid, auth_token)

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

BASE_URL = "api.intellialert.xyz"

# Twilio credentials
account_sid = os.environ.get('TWILIO_ACCOUNT_SID')
auth_token = os.environ.get('TWILIO_AUTH_TOKEN')
twilio_phone_number = os.environ.get('TWILIO_PHONE_NUMBER')
client = Client(account_sid, auth_token)

@app.get("/test")
def root():
    return {"hello": "world"}
#@app.put("/user_update")
#def user_update(user: User):
#    return {"hello": user.name}

@app.put("/users/update_profile/{user_id}")
async def update_profile(user_id: str, profile: UserEmergencyProfile):
    # Get the current datetime as a formatted string
    #timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    #log_entry = f"[{timestamp}] New log entry added {profile.fullName}.\n"

    # Open the file in append mode and write the entry
    #with open("log.txt", "a") as log_file:
        #log_file.write(log_entry)
    return {"message": user_id, "profile": profile.fullName}

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: Dict[str, Any]):
        for connection in self.active_connections:
            await connection.send_json(message)


manager = ConnectionManager()

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            print(f"Received message: {data}")
    except WebSocketDisconnect:
        manager.disconnect(websocket)

# Endpoint to initiate an outbound call
@app.get("/make-call")
async def make_call(background_tasks: BackgroundTasks):
    try:
        # Create TwiML for initial call
        response = VoiceResponse()
        response.say("This is an automated call.")
        gather = Gather(input='speech', action=f'{BASE_URL}/call-events', timeout=3, speech_timeout='auto')
        gather.say("How can I help you today?")
        response.append(gather)

        # Make the call
        call = client.calls.create(
            to="+17039440112",
            from_=twilio_phone_number,
            twiml=str(response),
            status_callback=f'{BASE_URL}/call-status',
            status_callback_method='POST',
            status_callback_event=['initiated', 'ringing', 'answered', 'completed']
        )

        # Broadcast call initiation via WebSocket
        background_tasks.add_task(
            manager.broadcast,
            {
                'type': 'callInitiated',
                'callSid': call.sid
            }
        )

        return {"success": True, "callSid": call.sid}

    except Exception as e:
        print(f"Error making call: {e}")
        return {"success": False, "error": str(e)}


# Endpoint to handle call events and gather speech
@app.post("/call-events")
async def call_events(request: Request, background_tasks: BackgroundTasks):
    print(f"Received request: {request}")
    form_data = await request.form()
    print(f"Form data received: {form_data}")
    call_sid = form_data.get('CallSid')
    call_status = form_data.get('CallStatus')
    speech_result = form_data.get('SpeechResult')
    print(form_data)
    print(f"Call {call_sid} status: {call_status}, speech: {speech_result}")

    # Broadcast to WebSocket clients
    background_tasks.add_task(
        manager.broadcast,
        {
            'type': 'callEvent',
            'callSid': call_sid,
            'callStatus': call_status,
            'speechResult': speech_result
        }
    )

    # Generate response with LLM if we have speech input
    llm_response = "I'm sorry, I couldn't understand that."
    if speech_result:
        llm_response = completions(speech_result)

    # Build TwiML response
    response = VoiceResponse()
    response.say(llm_response)

    # Gather more speech
    gather = Gather(input='speech', action='/call-events', timeout=3, speech_timeout='auto')
    gather.say("Is there anything else you'd like to know?")
    response.append(gather)

    return Response(content=str(response), media_type="text/xml")

@app.post("/call-status")
async def call_status(request: Request, background_tasks: BackgroundTasks):
    try:
        form_data = await request.form()
        call_sid = form_data.get('CallSid')
        call_status = form_data.get('CallStatus')

        print(f"Call {call_sid} status update: {call_status}")

        # Broadcast to WebSocket clients
        background_tasks.add_task(
            manager.broadcast,
            {
                'type': 'statusUpdate',
                'callSid': call_sid,
                'callStatus': call_status
            }
        )

        return {"received": True}
    except Exception as e:
        print(f"Error processing call status: {e}")
        return {"received": False, "error": str(e)}

if __name__ == "__main__":
    import uvicorn

    uvicorn.run("server:app", host="0.0.0.0", port=int(os.environ.get("PORT", 8000)), reload=False)
