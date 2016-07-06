import processing.serial.*;
import cc.arduino.*;
import processing.sound.*;


Arduino arduino;
Finger pinky;
Finger ring;
Finger mid;
Finger pointer;
Finger thum;


class Finger{
  private Arduino arduino; 
  private int pin; //value of pin
  private boolean state; //whether finger is currently being pressed
  private float intpress; //initial pressure
  private float pressthresh; //pressure threshhold
  SoundFile sound; //sound that finger tapping plays
  public Finger(Arduino a, int p, SoundFile file){ //constructor
      arduino=a;
      pin=p;
      sound=file;
      state=false;
      arduino.pinMode(pin, Arduino.INPUT);
      intpress=0;
      //get initial unpressed pressure values
      //sometimes it takes a few moments for it to read the voltage at startup and it gives 0s instead
      while(intpress==0){
        intpress=getPress();
      }
      pressthresh=intpress*2/3; //pressure threshhold is a fraction of the initial pressure value
  }
  
  float getThresh(){
    return pressthresh; 
  }
  
  float getPress(){
    return arduino.analogRead(pin); //gets voltage value coming through pressure sensor, more pressure -> less voltage
  }
  
  int isTap(){
    if(getPress()<pressthresh){ //plays a sound when a finger is tapped and not if a finger is held
      if(!state){
        sound.play();
        state=true;
      }
      return 255;
    }
    state=false;
    return 0; //returns R value for color of circle fill
  }
}


//pins
int pinkyPin = 3; //connected to pressure sensor
int ringPin=0;
int midPin=1;
int pointerPin=2;
int thumPin=4;
int ledPin=13; //yknow, the usual

void setup() {
  arduino=new Arduino(this, Arduino.list()[0], 57600);
  //initiate fingers
  pinky=new Finger(arduino, pinkyPin, new SoundFile(this, "crash-acoustic.wav"));
  ring=new Finger(arduino, ringPin, new SoundFile(this, "tom-acoustic01.wav"));
  mid=new Finger(arduino, midPin, new SoundFile(this, "hihat-dist02.wav"));
  pointer=new Finger(arduino, pointerPin, new SoundFile(this, "snare-acoustic01.wav"));
  thum=new Finger(arduino, thumPin, new SoundFile(this, "kick-classic.wav"));
  
  size(600,600);
  background(35,230,253);
}


void drawHand(){
  //draws a hand shape
  fill(78,217,179);
  beginShape();
  vertex(300,10);
  vertex(320,20);
  vertex(325,40);
  vertex(327,60);
  vertex(327,80);
  vertex(320,100);
  vertex(320,140);
  vertex(318,160);
  vertex(312,200);
  vertex(307,240);
  vertex(307,272);
  vertex(320,280);
  vertex(337,240);
  vertex(356,200);
  vertex(380,160);
  vertex(400,120);
  vertex(429,80);
  vertex(440,78);
  vertex(450,80);
  vertex(458,99);
  vertex(452,120);
  vertex(431,180);
  vertex(418,220);
  vertex(388,280);
  vertex(371,320);
  vertex(363,374);
  vertex(375,410);
  vertex(400,430);
  vertex(440,425);
  vertex(480,408);
  vertex(500,400);
  vertex(540,397);
  vertex(578,400);
  vertex(590,418);
  vertex(564,440);
  vertex(539,460);
  vertex(500,476);
  vertex(460,487);
  vertex(430,495);
  vertex(400,508);
  vertex(360,534);
  vertex(300,560);
  vertex(260,575);
  vertex(240,575);
  vertex(200,560);
  vertex(180,540);
  vertex(160,520);
  vertex(133,480);
  vertex(124,400);
  vertex(110,320);
  vertex(79,264);
  vertex(29,158);
  vertex(38,127);
  vertex(66,129);
  vertex(84,136);
  vertex(135,246);
  vertex(160,280);
  vertex(170,282);
  vertex(157,220);
  vertex(149,160);
  vertex(149,100);
  vertex(150,50);
  vertex(165,45);
  vertex(180,49);
  vertex(190,60);
  vertex(200,100);
  vertex(208,160);
  vertex(220,200);
  vertex(225,240);
  vertex(230,255);
  vertex(239,255);
  vertex(242,240);
  vertex(248,200);
  vertex(252,160);
  vertex(268,100);
  vertex(276,40);
  vertex(290,20);
  vertex(300,10);
  endShape();
  
  
  //Pinky
  rotate(PI/-6);
  fill(pinky.isTap(),0,0); //changes circle fill depending on whether pressure is applied
  ellipse(-28,179,41,62);
  rotate (-(PI/-6));
  
  
  //Ring
  rotate(PI/-20);
  fill(ring.isTap(),0,0);
  ellipse(157,117,41,62);
  rotate (-(PI/-20));
  
  //Middle
  rotate(PI/82);
  fill(mid.isTap(),0,0);
  ellipse(302,48,41,62);
  rotate (-(PI/82));
  
  //Pointer
  rotate(PI/8);
  fill(pointer.isTap(),0,0);
  ellipse(442,-45,41,62);
  rotate (-(PI/8));
  
  //Thumb
  rotate(PI/3);
  fill(thum.isTap(),0,0);
  ellipse(637,-245,41,62);
  rotate(-(PI/3));
  
  
}


void draw() {
  float pinkypress, ringpress, midpress, pointerpress, thumpress; //measures voltage allowed through pressure sensor
                //resistance of sensor decreases with pressure, voltage increases
  
  drawHand();
  
  //testing
  pinkypress = pinky.getPress();
  ringpress=ring.getPress();
  midpress = mid.getPress();
  pointerpress=pointer.getPress();
  thumpress=thum.getPress();
  println(pinkypress + " "  + pinky.getThresh() + " " + ringpress + " " + ring.getThresh() + " " + midpress + " " + mid.getThresh() + " " + pointerpress + " " + pointer.getThresh() + " " + thumpress + " " + thum.getThresh());
  
  //check each finger for tapping
  pinky.isTap();
  ring.isTap();
  mid.isTap();
  pointer.isTap();
  thum.isTap();

  delay(10);
}