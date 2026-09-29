import os

from dotenv import load_dotenv
from hindsight_client import Hindsight

load_dotenv()


# =========================================================
# HINDSIGHT CLIENT
# =========================================================

client = Hindsight(
    base_url="https://api.hindsight.vectorize.io",
    api_key=os.getenv("HINDSIGHT_API_KEY")
)


# =========================================================
# CREATE MEMORY BANK
# =========================================================

def create_memory_bank(bank_id: str):
    """
    Create one Hindsight memory bank for one chat.
    """

    try:
        result = client.create_bank(
            bank_id=bank_id,
            name=f"Memory AI - {bank_id}",
        )

        print(f"Memory bank created: {bank_id}")

        return result

    except Exception as e:

        # If the bank already exists, that's okay.
        print(f"Bank creation result: {e}")

        return None


# =========================================================
# RECALL MEMORY
# =========================================================

def recall_memory(
    bank_id: str,
    query: str
):

    result = client.recall(
        bank_id=bank_id,
        query=query,
        max_tokens=2000,
        budget="low"
    )

    return result.results


# =========================================================
# STORE MEMORY
# =========================================================

def store_memory(
    bank_id: str,
    content: str
):

    client.retain(
        bank_id=bank_id,
        content=content,
        context="Conversation with the user"
    )