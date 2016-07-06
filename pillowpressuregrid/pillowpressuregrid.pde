import processing.serial.*;
import cc.arduino.*;

Arduino arduino;
ArrayList movovtim; //number movements at each interval of time
Point[][] graph;

//values
public float thresh=2.0/3; //fraction of initial pressure at which threshhold is reached
int tim = 10; 

class Point{
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
    arduino.digitalWrite(trigPin, Arduino.HIGH);
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
}


//pins
void setup(){
  arduino = new Arduino(this, Arduino.list()[0], 57600);
  movovtim= new ArrayList();
  graph=new Point[16][16];
  for(int i=0; i<256; i++){
    graph[i/16][i%16]=new Point(arduino, i/16, i%16);
  }
  
  size(600,600);
  background(0,0,0);
}

void draw(){
}