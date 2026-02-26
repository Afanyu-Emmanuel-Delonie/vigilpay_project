import os
import ssl
from wsgiref.simple_server import make_server
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.core.handlers.wsgi import WSGIHandler

context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain('localhost+1.pem', 'localhost+1-key.pem')

app = WSGIHandler()
server = make_server('127.0.0.1', 8443, app)
server.socket = context.wrap_socket(server.socket, server_side=True)
print("Serving HTTPS on https://127.0.0.1:8443")
server.serve_forever()