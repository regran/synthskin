
import processing.serial.*;
import cc.arduino.*;

Arduino arduino;
pMap pm; //number movements at each interval of time
barGraph bg;
Button bStart;
Button bStop;
Button bRestart;
Button bSave;
Point test;

public boolean start;


//constant values

public final int tim = 10; 
final int xlen=5; //1-54 number of digital pins
final int ylen=5; //1-16 number of analog pins
public final float thresh=2.0/3; //fraction of initial pressure at which threshhold is reached
public float mapscale; 
public float mapx; //x coordinate of top left corner of pressure map
public float mapy; //y coordinate of top right corner of pressure map
public float graphx; //graph width
public float graphy; //graph height
public float margin; //distance of graph from edge of screen
public float buttonsx; 
public float buttonsy;
public float buttonsw; //width of buttons
public float buttonsh; //height of buttons






//a pillow is 20 inches by 26 inches


public class Point{
  private Arduino arduino;
  private int x; //x coordinate
  private int y; //y coordinate of point
  private int pin;
  private boolean state;
  private float intpress;
  private float pressthresh;
  private float press;
  private float c; //to remove
  public Point(Arduino a, int xcoord, int ycoord, int ap){
    arduino = a;
    x=xcoord;
    y=ycoord;
    pin=ap;
    state=false;
    arduino.pinMode(pin,Arduino.INPUT);
    intpress=0;
    //get initial unpressed pressure values
    //sometimes it takes a few moments for it to read the voltage at startup and it gives 0s instead
    intpress=getPress();
    print(press);
    println("I'm trying yo");
    pressthresh=intpress*thresh; //pressure threshhold is a fraction of the initial pressure value
  }
  
  float getInit(){
    return intpress;
  }
  
 float getPress(){
   print("aaaaa");
    press = arduino.analogRead(sensePin); //gets voltage value coming through pressure sensor, more pressure -> less voltage
                                                  //degree of pressure represented as ratio between unpressed voltage and current voltage
    while(press==0){
      press=arduino.analogRead(sensePin);
      delay(1);
    }
    return press;
  }
//stopped makingchanges here, for future self
  
  boolean isMove(){
    if(press<pressthresh){
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
  public void drawP(float x, float y, float scale){
    noStroke();
    if(start) c=press/intpress*255-255%(press/intpress*255);
    fill(255, c, 0) ; //Make color range from red to yellow depending on amount of pressure
    if(isMove()){
      rect(x+(sensePin)*scale, y+trigPin*scale, (scale-10)/2, (scale-10)/2); 
      
    }
    else{
      ellipseMode(CORNER);
      ellipse(x+(sensePin+.1)*scale, y+(trigPin+.1)*scale, scale*.8, scale*.8);
    }
   
  }
}

public class pMap{
  Point[][] map;
  Arduino a;
  int xlen;
  int ylen;
  float x;
  float y;
  float scale;
  public pMap(float xcoord, float ycoord, float s, Arduino arduino, int xs, int ys){
    a=arduino;
    xlen=xs;
    ylen=ys;
    x=xcoord;
    y=ycoord;
    scale=s; 
    map=new Point[xlen][ylen];
    for(int i=0; i<xlen; i++){
      for(int j=0; j<ylen;j++){
        map[i][j]=new Point(a, i, j);
      }
    }
  }
  public int drawM(){ //returns changes in movement
   int movs=0;
   noFill();
   stroke(100);
   rect(x, y, ylen*scale, xlen*scale);
   if(start) getPress();
   for(Point[] ps:map){
    for(Point p:ps){
       if(p.isMove()) movs++;
       p.drawP(x, y, scale);
    }
   }
  return movs;
  }
  void getPress(){
    for(int i=1; i<=xlen;i++){
      a.digitalWrite(i, Arduino.HIGH); //send signal to sensor
      delay(1);
      for(int j=0; j<ylen; j++){
        print(i);
        print(j);
        println(a.analogRead(j));
        map[i-1][j].updatepress(a.analogRead(j)); //gets voltage value coming through pressure sensor, more pressure -> less voltage
                                                  //degree of pressure represented as ratio between unpressed voltage and current voltage
      }
    a.digitalWrite(i, Arduino.LOW);
    delay(1); //dont break the arduino pls
    }
  }
  
}

public class barGraph{ //actually a histogram
  private ArrayList<Float> movovtim; //number movements at each interval of time
  private int binsize;
  private float barw;
  private float baryscale;
  private int maxbins;
  private float maxval;
  private float w;    //graph width
  private float h;    //graph length
  private float m; //margin for graph position
  public barGraph(float wid, float hei, float mar){
    w=wid;
    h=hei;
    m=mar;
    movovtim=new ArrayList<Float>();
    binsize=1;
    baryscale=h;
    maxbins=(int)w/10;
  }
  
  public void drawG(){
    if(start) movovtim.add(new Float(pm.drawM()));
    //if(start) movovtim.add(new Float(random(256)));
    if(movovtim.size()/binsize>maxbins) binsize=binsize*2;
    barw=w/(movovtim.size()/binsize);
    noFill();
    stroke(100,100,100);
    rect(m,m,w,h);
    int i=0;
    int k=0;
    float mag=0;
    while(i<movovtim.size() && k*barw<w){
      for(int j=0; j<binsize; j++){
        if(i<movovtim.size()) mag+=movovtim.get(i);
        else{
          mag=0;
          barw=0;
        }
        i++;
      }
      if(mag>maxval) maxval=mag;
      baryscale=h/maxval;
      rectMode(CORNER);
      fill(255,255,255);
      stroke(200,200,200);
      rect(m+barw*k, m+graphy, barw, -mag*baryscale);
      mag=0;
      k++;
    }

  }
  
  void clear(){
    movovtim=new ArrayList<Float>();
    binsize=1;
    maxval=1;
    baryscale=h;
  }
  
  
}



public class Button{
  private float xcoord; //x coordinate of top left corner of button
  private float ycoord; //y coordinate of top right corner of 
  private String prompt; //text printed on button
  private float w; //width
  private float h; //height
  private float lin; //border color
  private float in; //fill color
  
  public Button(String p, float x, float y, float wid, float hei){
    prompt=p;
    xcoord=x;
    ycoord=y;
    w=wid;
    h=hei;
    lin=80;
    in=150;
  }
  void drawB(){
    lin=80;
    in=150;
    if(inB(mouseX, mouseY)){
      mouseOver();
      if(mousePressed && mouseButton==LEFT) mousePress();
    }
    stroke(lin,lin,lin);
    fill(in,in,in);
    
    rect(xcoord, ycoord, w, h);
    fill(0,0,0);
    textSize(h/3);
    textAlign(CENTER, CENTER);
    text(prompt,xcoord+w/2,ycoord+h/2);
  }
  
  boolean inB(float x, float y){
    return(x>xcoord && x<xcoord+w && y>ycoord&&y<ycoord+h);
  }
  
  void mouseOver(){
    in=180;
  }
  void mousePress(){
    in=130;
  }
  
  float getBottom(){
    return ycoord+h;
  }
    
  
}



void setup(){
  arduino = new Arduino(this, Arduino.list()[0], 57600);
  fill(0,0,0);
  fullScreen();
  //size(1000,600);
  margin=height*0.1;
  graphx=width*0.75;
  graphy=height*0.8;
  bg=new barGraph(graphx,graphy,margin); 

  
  
  buttonsx=margin+graphx+width*0.025;
  buttonsy=margin;
  buttonsw=width*0.975 - buttonsx;
  buttonsh= height*0.07;
  bStart = new Button("Start", buttonsx, buttonsy, buttonsw, buttonsh);
  bStop=new Button("Stop", buttonsx, bStart.getBottom()+height*0.01, buttonsw, buttonsh);
  bRestart=new Button("Clear", buttonsx, bStop.getBottom()+height*0.01, buttonsw, buttonsh);
  bSave=new Button("Save", buttonsx, bRestart.getBottom()+height*0.01, buttonsw, buttonsh);
  
  mapx=buttonsx;
  mapy = bSave.getBottom() + margin;
  mapscale=(height-mapy-margin)/xlen;
  if((buttonsw/ylen)<mapscale) mapscale=(buttonsw)/ylen;
  pm=new pMap(mapx, mapy, mapscale, arduino, xlen, ylen);
  start=false;
  
  //
  background(0,0,0);
}

void draw(){
  background(0,0,0);
  bStart.drawB();
  bStop.drawB();
  bRestart.drawB();
  bSave.drawB();
  bg.drawG();
  pm.drawM();
  delay(tim);
//test.drawP(mapx,mapy,mapscale);
//println(test.getPress());


}

void mouseClicked(){
  if (bStart.inB(mouseX, mouseY)) start=true;
  if (bStop.inB(mouseX, mouseY)) start=false;
  if (bRestart.inB(mouseX,mouseY)){
    bg.clear();
    start=false;
  }
  if (bSave.inB(mouseX, mouseY)) save(Integer.toString(month()) + Integer.toString(day()) + Integer.toString(year())+Integer.toString(minute())+ ".png");