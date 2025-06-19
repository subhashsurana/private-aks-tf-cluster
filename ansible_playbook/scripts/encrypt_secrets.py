import sys
import base64
from nacl import encoding, public

if len(sys.argv) != 3:
    print("Usage: python encrypt_secret.py <base64_public_key> <secret_value>")
    sys.exit(1)

public_key_b64 = sys.argv[1]
secret_value = sys.argv[2]

key = public.PublicKey(public_key_b64.encode("utf-8"), encoding.Base64Encoder())
sealed_box = public.SealedBox(key)
encrypted = sealed_box.encrypt(secret_value.encode("utf-8"))
print(base64.b64encode(encrypted).decode("utf-8"))
