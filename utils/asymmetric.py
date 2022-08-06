from datetime import datetime
from Crypto.PublicKey import RSA  
from Crypto.Cipher import PKCS1_OAEP
import hashlib
import base64
import binascii
import os
from Crypto.Util import Counter
from Crypto import Random

################################### METHODS ###################################

#returns a SHA256 hash of a string
def generate_hash(s):
    return hashlib.sha256(s.encode('utf-8')).hexdigest()

#returns delimitted string
def delimit_as_string(*args):
    delimitter = "_"
    return delimitter.join([x for x in args])

#generates a private and public RSA key-pair
def generate_RSA(bits=1024):
	key = RSA.generate(bits, e=65537) 
	private_key = key.exportKey('PEM')
	public_key = key.publickey().exportKey('PEM')
	return private_key, public_key

#encrypts a message with a public key
def encrypt_PBK(message, public_key):
    message = message.encode('utf-8')
    rsa_public_key = RSA.importKey(public_key)
    rsa_public_key = PKCS1_OAEP.new(rsa_public_key)
    encrypted_text = rsa_public_key.encrypt(message)
    return base64.b64encode(encrypted_text)

#decrypts a message with a key (private_key can be public_key)
def decrypt_PVK(encoded_encrypted_msg, private_key):
    rsa_private_key = RSA.importKey(private_key)
    rsa_private_key = PKCS1_OAEP.new(rsa_private_key)
    decrypted_text = rsa_private_key.decrypt(base64.b64decode(encoded_encrypted_msg))
    return decrypted_text.decode("utf-8")

def test_RSA():
    key_pair = generate_RSA()
    PVK, PBK = key_pair[0], key_pair[1]
    print("PVK:", PVK)
    print()
    print("PBK:", PBK)
    print()
    message = "testing RSA"
    print("message to be encrypted with public key:", message)
    print()
    cipher = encrypt_PBK(message, PBK)
    print("cipher:", cipher)
    decrypted = decrypt_PVK(cipher, PVK)
    print()
    print("cipher decrypted with private key:", decrypted)
   
if __name__=="__main__":
    test_RSA()



