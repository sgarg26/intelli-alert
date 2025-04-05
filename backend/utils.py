from groq import Groq
from dotenv import load_dotenv
load_dotenv()


groq_client = Groq()

def completions(query):
    try:
        chat_completion = groq_client.chat.completions.create(
            messages=[
                {"role": "system", "content": "You are a security systems agent talking to an emergency operator. Someone is in distress and you must provide information to the operator. Keep it short because this is a voice call."},
                {"role": "user", "content": query}
            ],
            model="llama-3.3-70b-versatile",
            stream=False,
        )
        return chat_completion.choices[0].message.content
    except Exception as e:
        print(f"Error calling LLM API: {e}")
        return "I'm sorry, I couldn't process your request."