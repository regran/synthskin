
import processing.serial.*;
import cc.arduino.*;

Arduino arduino;
pMap pm; 
barGraph bg;
Button bStart;
Button bStop;
Button bRestart;
Button bSave;


public boolean start;
public boolean ss;

//values

public final int tim = 10; 
final int xlen=6; //0 to 16 pins
final int ylen=6; //0 to (16-xlen) pins
public final float thresh=0.85; //fraction of initial pressure at which threshhold is reached
float mapscale;  //coefficient for scaling of pressure map based on screen size
float mapx; //x coordinate of left edge of pressure map
float mapy; //y coordinate of top edge of pressure map
float graphx; //graph width
float graphy; //graph height
public float margin; //distance of graph from edge of screen
public float buttonsx; //x coordinate of left edge of button
public float buttonsy; //y coordinate of top edge of top button
float buttonsw; //width of buttons
float buttonsh; //height of buttons
int day;





//a pillow is 20 inches by 26 inches


class Line{ //gridline
  private Arduino arduino; //arduino
  private int pin; //analog input pin
  private float intpress; //initial pressure value
  private boolean state; //currently been pressed or not
  private float press; //current pressure of line
  private float norm;
  public Line(Arduino a, int p){ //arduino, arduino pin connected to sensors
    arduino = a; //a arduino
    pin=p;
    state=false; //initially unpressed
    a.pinMode(p, Arduino.INPUT);
    intpress=updatePress(); //get initial unpressed pressure

  }
  
  float updatePress(){
    while((press=arduino.analogRead(pin))==0){ //gets voltage value coming through pressure sensor, more pressure -> less voltage
      delay(1); //sometimes the arduino gets confused
    }
    norm=press/intpress;
    println("aaa");
    return press;
  }

  float getNorm(){
    return norm;
  }
  
  boolean getState(){
    return state;
  }
  
  boolean isMove(){ //updates state and notes whether state changed or stayed the same
    if(norm<thresh){ 
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

class Point{ //a point in the grid
  private Line x; //sensor line corresponding to x coordinate
  private Line y; //sensor line corresponding to y
  int xval; //x coordinate of point
  int yval; //y coordinate
  float c; //yellowness
  boolean state; //whether point is being pressed
  boolean move;

  public Point(Line xl, Line yl, int xv, int yv){ //x line, y line, value of x coordinate, value of y coordinate
    x=xl;
    y=yl;
    xval=xv;
    yval=yv;
    state=false;
    move = false;
    c=0; //his face all red
  }
  
  boolean isPress(){
    return (x.getState() && y.getState()); //if point is pressed if corresponding x and y coordinates are pressed
  }
  
  boolean isMove(){
    return (move = (x.isMove() || y.isMove())); //if one line changed in state the point changed in state
  }
  
  boolean getMove(){
    return move;
  }
  
  public void drawP(float xcoord, float ycoord, float scale){
    noStroke();
    x.updatePress();
    y.updatePress();
    if(start) c=(x.getNorm()+y.getNorm()-1.5)*255*2`; //averages normalized pressure of x and y coordinate
    else c=0;
    fill(255, c, 0); //Make color range from red to yellow depending on amount of pressure
    if(isMove()){
      
      rect(xcoord+(xval+.1)*scale, ycoord+(yval+.1)*scale, scale*.8, scale*.8);
    }
    else{

      ellipseMode(CORNER);
      ellipse(xcoord+(xval+.1)*scale, ycoord+(yval+.1)*scale, scale*.8, scale*.8);
    }
    //textSize(scale*.8/3);
    //textAlign(LEFT, TOP);
    //text(Float.toString(x.getNorm()+y.getNorm()),xcoord+(xval+.1)*scale, ycoord+(yval+.1)*scale);
   
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
  Line[] xs;
  Line[] ys;
  public pMap(float xcoord, float ycoord, float s, Arduino arduino, int xd, int yd){
    
    a=arduino;
    xlen=xd;
    ylen=yd;
    x=xcoord;
    y=ycoord;
    scale=s; 
    map=new Point[xlen][ylen];
    xs=new Line[xlen];
    ys=new Line[ylen];
    for(int i=0; i<xlen; i++){
      xs[i] = new Line(a, i);
      for(int j=0; j<ylen;j++){
        ys[j]=new Line(a, j+xlen);
        map[i][j]=new Point(xs[i],ys[j],i,j);
      }
    }
  }
  public int drawM(){ //returns changes in movement
   int movs=0;
   noFill();
   stroke(100);
   rect(x, y, ylen*scale, xlen*scale);
   int i=0;
   int j=0;
   for(Point[] ps:map){
     print(i);
     i++;
    for(Point p:ps){
      println(j);
      j++;
       if(p.getMove()) movs++;
       p.drawP(x, y, scale);
    }
   }
  return movs;
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
  private String xlab;
  private String ylab;
  private String title;
  private float m; //margin for graph position
  public barGraph(String xl, String yl, String t, float wid, float hei, float mar){
    xlab=xl;
    ylab=yl;
    title=t;
    w=wid;
    h=hei;
    m=mar;
    movovtim=new ArrayList<Float>();
    binsize=1;
    baryscale=h*5/6;
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
    fill(200,200,200);
    textSize(m/3);            //x axis label
    textAlign(CENTER, TOP);
    text(xlab,m+w/2,m*5/4+h);
    translate(m*3/4, m+h/2);
    rotate(-HALF_PI);
    translate(-m*3/4, -(m+h/2));
    textAlign(CENTER, BOTTOM);
    text(ylab, m*3/4, m+h/2);
    translate(m*3/4, m+h/2);
    rotate(HALF_PI);
    textAlign(CENTER,TOP);
    textSize(h/15);
    translate(-m*3/4, -(m+h/2));
    text(title, m+w/2, m+h/60);
    
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
      baryscale=(h*5/6)/maxval;
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

void periodic(){
  int timer=0;
  while(start){
    timer++;
    if(timer%6000==0) ss=true;
    delay(1);
  }
}



void setup(){
  arduino = new Arduino(this, Arduino.list()[0], 57600);
  fill(0,0,0);
  fullScreen();
  margin=height*0.1;
  graphx=width*0.75;
  graphy=height*0.8;
  bg=new barGraph("Time", "Amount of Movement", "Movement Throughout Sleep", graphx,graphy,margin); 

  
  
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
  ss=false;
  
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
  delay(tim);
  if(ss) save("screenshots/" + Integer.toString(year())+ "/" + Integer.toString(month()) + "/" + Integer.toString(day) + "/" + Integer.toString(hour())+ "_" +Integer.toString(minute())+ ".png");
  ss=false;
  



}

void mouseClicked(){
  if (bStart.inB(mouseX, mouseY)){
    start=true;
    thread("periodic");
  }
  if (bStop.inB(mouseX, mouseY)) start=false;
  if (bRestart.inB(mouseX,mouseY)){
    bg.clear();
    pm=new pMap(mapx, mapy, mapscale, arduino, xlen, ylen);
    start=false;
  }
  if (bSave.inB(mouseX, mouseY)) save(Integer.toString(month()) + Integer.toString(day()) + Integer.toString(year())+Integer.toString(minute())+ ".png");
}