# Echo client program
import socket
from time import sleep

HOST = '127.0.0.1'    # The remote host
PORT = 6000              # The same port as used by the server
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((HOST, PORT))
s.send('Hello, world')
data = s.recv(1024)
sleep(2)
s.close()
print 'Received', repr(data)
