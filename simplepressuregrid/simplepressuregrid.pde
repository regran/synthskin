
import processing.serial.*;
import cc.arduino.*;

Arduino arduino;
pMap pm; 
barGraph bg;
Button bStart;
Button bStop;
Button bRestart;
Button bSave;
//Point test;

public boolean start;

//values

public final int tim = 10; 
final int xlen=5; //0 to 16 pins
final int ylen=5; //0 to (16-xlen) pins
public final float thresh=0.5; //fraction of initial pressure at which threshhold is reached
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






//a pillow is 20 inches by 26 inches


class Line{
  private Arduino arduino; //arduino
  private int pin; //analog input pin
  private float intpress; //initial pressure value
  private float pressthresh; //threshhold for state change
  private boolean state; //currently been pressed or not
  private float press;
  public Line(Arduino a, int p){
    arduino = a;
    pin=p;
    state=false;
    a.pinMode(p, Arduino.INPUT);
    intpress=getPress();
    pressthresh=intpress*thresh;
  }
  
  float updatePress(){
    while((press=arduino.analogRead(pin))==0){
      delay(1);
    }
    return press;
  }

  float getInit(){
    return intpress;
  }
  
  float getPress(){
    return press;
  }
  
  boolean getState(){
    return state;
  }
  
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
  
  
}

class Point{
  private Line x;
  private Line y;
  int xval;
  int yval;
  float c; //color
  boolean state;

  public Point(Line xl, Line yl, int xv, int yv){
    x=xl;
    y=yl;
    xval=xv;
    yval=yv;
    state=false;
    c=0;
  }
  
  boolean isPress(){
    return (x.getState() && y.getState());
  }
  
  boolean isMove(){
    return (x.isMove() || y.isMove());
  }
  
  public void drawP(float xcoord, float ycoord, float scale){
    noStroke();

    if(start) c=(x.getPress()/x.getInit()+y.getPress()/y.getInit())/2*255;
    else c=0;
    fill(255, c, 0) ; //Make color range from red to yellow depending on amount of pressure
    //if(isMove()){
    //  rect(xcoord+(xval+.1)*scale, ycoord+(trigPin+.1)*scale, scale*.8, scale*.8);
    //}
    //else{
    //  ellipseMode(CORNER);
    //  ellipse(xcoord+(sxval+.1)*scale, ycoord+(yval+.1)*scale, scale*.8, scale*.8);
    //}
    textSize(scale*.8/3);
    textAlign(LEFT, TOP);
    text(Float.toString(x.getPress()+y.getPress()),xcoord+(xval+.1)*scale, ycoord+(yval+.1)*scale);
   
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
        ys[i]=new Line(a, j+xlen);
        map[i][j]=new Point(xs[i],ys[j],i,j);
      }
    }
  }
  public int drawM(){ //returns changes in movement
   int movs=0;
   noFill();
   stroke(100);
   rect(x, y, ylen*scale, xlen*scale);
   for(Point[] ps:map){
    for(Point p:ps){
       if(p.isMove()) movs++;
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
//  pm.drawM(); //called in bg i think?
  delay(tim);
//test.drawP(mapx,mapy,mapscale);
//println(test.getPress());


}

void mouseClicked(){
  if (bStart.inB(mouseX, mouseY)) start=true;
  if (bStop.inB(mouseX, mouseY)) start=false;
  if (bRestart.inB(mouseX,mouseY)){
    bg.clear();
    pm=new pMap(mapx, mapy, mapscale, arduino, xlen, ylen);
    start=false;
  }
  if (bSave.inB(mouseX, mouseY)) save(Integer.toString(month()) + Integer.toString(day()) + Integer.toString(year())+Integer.toString(minute())+ ".png");
}