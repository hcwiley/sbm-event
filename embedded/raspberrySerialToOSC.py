from OSC import OSCClient, OSCMessage
import serial

ser = serial.Serial("/dev/ttyACM0", 9600)
client = OSCClient()
client.connect( ("192.168.2.2", 3333) )

while 1:
  active = ser.readline()
  msg = OSCMessage( "/active" )
  #print("|%s|\n" % active)
  msg.append(active)
  client.send( msg )
