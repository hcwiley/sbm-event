int reeds[] = { 8, 9 };
int activeReed = -1;
int lastActive = -1;
int numReeds = sizeof(reeds) / sizeof(int);

void setup(){
  Serial.begin(9600);
//  Serial.println("hello world");
   for(int i = 0; i < numReeds; i++){
    pinMode(reeds[i], INPUT);
    digitalWrite(reeds[i], HIGH);
  }
}

void loop(){
  if( activeReed >= 0 && activeReed != lastActive ){
    lastActive = activeReed;
//    Serial.print("last reed: ");
    Serial.print(lastActive);
  }
  activeReed = -1;
  for(int i = 0; i < numReeds; i++){
    int val = digitalRead(reeds[i]);
    if (val == 0)
      activeReed = i;
//    Serial.print("reed ");
//    Serial.print(i);
//    Serial.print(" = ");
//    Serial.println(val);
  }
    
  delay(500);
}
