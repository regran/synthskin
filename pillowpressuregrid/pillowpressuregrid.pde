import processing.serial.*;
import cc.arduino.*;

Arduino arduino;
ArrayList movovtim; //number movements at each interval of time
Point[][] graph;

//constant values
public final float thresh=2.0/3; //fraction of initial pressure at which threshhold is reached
public final int pillowscale=16; 


public final int tim = 10; 
public final int xlen=16; //1-54
public final int ylen=16; //1-16


public class Point{
  private Arduino arduino;
  private int trigPin; //digital output pin sending signal
  private int sensePin; //analog input pin
  private boolean state;
  private float intpress;
  private float pressthresh;
  public Point(Arduino a, int dp, int ap){
    arduino = a;
    trigPin =dp;
    sensePin=ap;
    state=false;
    arduino.pinMode(trigPin, Arduino.OUTPUT);
    arduino.pinMode(sensePin,Arduino.INPUT);
    arduino.digitalWrite(trigPin, Arduino.LOW);
    intpress=0;
    //get initial unpressed pressure values
    //sometimes it takes a few moments for it to read the voltage at startup and it gives 0s instead
    while(intpress==0){
      intpress=getPress();
    }
    pressthresh=intpress*thresh; //pressure threshhold is a fraction of the initial pressure value
  }
  
 float getPress(){
    arduino.digitalWrite(trigPin, Arduino.HIGH); //send signal to sensor
    delay(1);
    float press = intpress/arduino.analogRead(sensePin)*100; //gets voltage value coming through pressure sensor, more pressure -> less voltage
                                                  //degree of pressure represented as ratio between unpressed voltage and current voltage
    arduino.digitalWrite(trigPin, Arduino.LOW);
    delay(1); //dont break the arduino pls
    return press;
  }
  
  boolean isMove(){
    if(getPress()<pressthresh){
      if(!state){
        state=true;
        return true;
      }
      return false;
    }
    else if(state){
      state=false;
      return true;
    }
    return false;
  }
  
  //draw circle or rectangle depending on isMove()
  //draw color ranging from yellow to red depending on getPress()
  void drawP(){
    fill(255, getPress()/intpress*255-255%(getPress()/intpress*255), 0) ; //Make color range from red to yellow depending on amount of pressure
    if(isMove()){
      rectMode(CENTER);
      rect(trigPin*scale, sensePin*scale, (scale-10)/2, (scale-10)/2); 
    }
    else{
      ellipse(trigPin*scale, sensePin*scale, (scale-10)/2, (scale-10)/2);
    }
   
  }
}



void setup(){
  arduino = new Arduino(this, Arduino.list()[0], 57600);
  graph=new Point[xlen][ylen];
  for(int i=0; i<256; i++){
    graph[i/xlen][i%xlen]=new Point(arduino, i/xlen, i%ylen);
  }
  
  size(3456, 1024);
  background(0,0,0);
}

void draw(){
  long movs=0;
  for(Point[] ps:graph){
    for(Point p:ps){
       if(p.isMove()) movs++;
       p.drawP();
    }
  }
  movovtim.add(movs);    
  delay(tim);
}