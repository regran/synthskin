import processing.serial.*;
import cc.arduino.*;

Arduino arduino;

int outPin=1;
int inPin=1;


void setup(){
  arduino = new Arduino(this, Arduino.list()[0], 57600);
  for(int i=0; i<5; i++){
    
    arduino.pinMode(i+1, Arduino.OUTPUT);
    arduino.pinMode(i, Arduino.INPUT);
    arduino.digitalWrite(i+1, Arduino.LOW);
  }
}


void getCol(int dp){
  arduino.digitalWrite(dp,Arduino.LOW);
  delay(50);
  arduino.digitalWrite(dp,Arduino.HIGH);
  for(int i=0; i<5; i++){
    println(i);

    println(getDelay(i));
  }
  delay(50);
  arduino.digitalWrite(dp,Arduino.LOW);
  delay(50);
}
  


int getDelay(int ap){

  int count=0;
  while(arduino.analogRead(ap)==0 && count<5000){
    count++;

    delay(1);
  }
  print("press ");
  println(arduino.analogRead(ap));
  print("delay ");

  return count;
}


//int getDelay(int dp, int ap){

//  arduino.digitalWrite(dp,Arduino.LOW);
//  delay(1);
//  int a=arduino.analogRead(ap);
//  arduino.digitalWrite(dp, Arduino.HIGH);
//  int count=0;
//  while(arduino.analogRead(ap)==0){
//    count++;
//    delay(1);
//  }
//    arduino.digitalWrite(dp, Arduino.LOW);
//    delay(1);
//  return count;
//}
void draw(){
  for(int i=0; i<14; i++){
       print(i);
       getDelay(i);
       
    
   }
}
    
  