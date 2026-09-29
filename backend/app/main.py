from fastapi import FastAPI
from pydantic import BaseModel

from langchain_ollama import ChatOllama
from langchain_core.messages import SystemMessage, HumanMessage

from fastapi.middleware.cors import CORSMiddleware

from app.hindsight_service import (
    create_memory_bank,
    recall_memory,
    store_memory
)


# =========================================================
# FASTAPI
# =========================================================

app = FastAPI(
    title="Memory AI",
    description="AI assistant with persistent Hindsight memory"
)


# =========================================================
# CORS
# =========================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# =========================================================
# LLM
# =========================================================

llm = ChatOllama(
    model="qwen3:1.7b"
)


# =========================================================
# REQUEST MODELS
# =========================================================

class CreateChatRequest(BaseModel):
    chat_id: str


class ChatRequest(BaseModel):
    chat_id: str
    message: str


# =========================================================
# HOME
# =========================================================

@app.get("/")
def home():

    return {
        "message": "Memory AI backend is running"
    }


# =========================================================
# HEALTH
# =========================================================

@app.get("/health")
def health():

    return {
        "status": "healthy"
    }


# =========================================================
# CREATE CHAT / MEMORY BANK
# =========================================================

@app.post("/chat/create")
def create_chat(request: CreateChatRequest):

    print("\n" + "=" * 60)

    print("CREATING CHAT:")
    print(request.chat_id)

    create_memory_bank(
        request.chat_id
    )

    return {
        "success": True,
        "chat_id": request.chat_id
    }


# =========================================================
# CHAT
# =========================================================

@app.post("/chat")
def chat(request: ChatRequest):

    chat_id = request.chat_id
    user_message = request.message.strip()

    print("\n" + "=" * 60)

    print("CHAT ID:")
    print(chat_id)

    print("\nUSER:")
    print(user_message)


    # =====================================================
    # 1. RECALL MEMORY FROM THIS CHAT'S BANK
    # =====================================================

    print("\nMEMORY:")
    print("Searching Hindsight...")

    memories = recall_memory(
        bank_id=chat_id,
        query=user_message
    )


    # =====================================================
    # 2. SHOW RETRIEVED MEMORIES
    # =====================================================

    if memories:

        print("\nRetrieved memories:")

        for memory in memories:

            print(
                "-",
                memory.text
            )

    else:

        print("No memories found.")


    # =====================================================
    # 3. CONVERT MEMORIES TO TEXT
    # =====================================================

    if memories:

        memory_text = "\n".join(
            f"- {memory.text}"
            for memory in memories
        )

    else:

        memory_text = "No memories were retrieved."


    # =====================================================
    # 4. SYSTEM MESSAGE
    # =====================================================

    system_message = SystemMessage(
        content="""
You are Memory AI, a helpful AI assistant with
persistent long-term memory.

You will receive memories retrieved from the
current conversation's memory bank.

IMPORTANT MEMORY RULE:

Use a retrieved memory ONLY when it is directly
relevant to the user's current message.

If a retrieved memory is unrelated to the
current message, completely ignore it.

Do NOT mention a memory simply because it was
provided to you.

Do NOT force personal information into your answer.

For simple conversation, greetings, casual
conversation, general knowledge questions, or
questions that do not require personal memory,
answer naturally without using unrelated memories.

When a memory is relevant, use it naturally
to provide a more personalized and accurate
answer.

Never claim to remember something unless that
information exists in the retrieved memories.

Always prioritize the user's current message
over the retrieved memories.
"""
    )


    # =====================================================
    # 5. USER MESSAGE
    # =====================================================

    human_message = HumanMessage(
        content=f"""
Retrieved memories from this conversation:

{memory_text}

--------------------------------------------------

Current user message:

{user_message}

--------------------------------------------------

Answer the current user message naturally.

Use retrieved memories only if they are relevant
to this specific message.
"""
    )


    # =====================================================
    # 6. ASK QWEN
    # =====================================================

    response = llm.invoke(
        [
            system_message,
            human_message
        ]
    )


    # =====================================================
    # 7. GET ANSWER
    # =====================================================

    answer = response.content.strip()


    print("\nAI:")
    print(answer)


    # =====================================================
    # 8. STORE IN THIS CHAT'S MEMORY BANK
    # =====================================================

    store_memory(
        bank_id=chat_id,
        content=(
            f"User: {user_message}\n"
            f"Assistant: {answer}"
        )
    )


    # =====================================================
    # 9. RETURN TO FLUTTER
    # =====================================================

    return {
        "response": answer
    }