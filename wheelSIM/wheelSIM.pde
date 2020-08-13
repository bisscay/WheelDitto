/**  References:
 *    https://learn.sparkfun.com/tutorials/connecting-arduino-to-processing/all
 *    https://forum.processing.org/one/topic/draw-a-cone-cylinder-in-p3d.html
 *    https://forum.processing.org/two/discussion/4047/how-to-shoot-points-and-rotate-wheels
 */
import processing.serial.*;

// create object from serial class
Serial myPort;
// wheel's angle
float angleWheel;
// TO DO: All initializations should be done in setup
float positionY = height-113; // define height of plane
// to control the wheel's scale
float scale = 15;
// for generating vertex
float ang = 0;
// alters the ang in vertex
int pts = 120;
// defines the depth of the wheel
float CONE_DEPTH = 200;

/* ToProcessing Params */
// data received from the serial port
String sensorFeed = "";
// for whole shape rotation
float yaw, pitch, roll;
// desired character limit
final byte numChars = 32;
// defines when a new data stream arives
boolean newData = false;
// to hold data recieved from serial port
char[] receivedChars = new char[numChars];
// temporary array for use when parsing
char[] tempChars = new char[numChars];

void setup() {
  // window size
  size(700, 700, P3D);
  // display at 2 frames every second
  frameRate(60);
  // draw sketches without outlines (just fill the shape)
  noStroke();
  // hide cusor 
  //noCursor();
  // display serial port fot clarity/debugging
  //println(Serial.list());
  // identify my mac's serial port
  String portName = Serial.list()[0]; // 0 in linux | 2 on mac
  // define rate of data transfer
  myPort = new Serial(this, portName, 115200);
}

void draw() {
  background(0);
  // center of the scene
  //translate(0,0,0);
  translate(width/2, height/2, -200);
  // x-axis
  line(-500, 0, 0, 500, 0, 0);
  // y-axis
  line(0, -500, 0, 0, 500, 0);
  // z-axis
  line(0, 0, 500, 0, 0, -500);
  // camera orientation
  //camera(0+mouseX,0+mouseY,1500, 0,0,0, 0,0.5,0);
  //camera(0,0,1500, 0,0,0, 0,0.5,0);

  // translate wheel on plane
  stroke(255, 0, 0);
  line(-500, 1400/scale, 0, 500, 1400/scale, 0);
  // color and define strokes for presentation
  stroke(200);
  fill(0, 200, 0);
/*
  // rotate wheel for analysis
  rotateY(yaw);
  rotateX(pitch);
  rotateZ(roll);
*/
  // get feed from serial line
  recvWithStartEndMarkers();
  if (newData == true) {
    //println(receivedChars);
    String sensorFeed = new String(receivedChars);
    println(sensorFeed);
    // split val into yaw, pitch and roll
    String[] splitFeed = sensorFeed.split(",");
    yaw = Float.parseFloat(splitFeed[0]);
    pitch = Float.parseFloat(splitFeed[1]);
    roll = Float.parseFloat(splitFeed[2]);
    // print it out in the console for debugging
    println("Yaw: " +yaw +" Pitch: " +pitch +" Roll: " +roll);
    // modify wheel sim position
    if(yaw > 0)
      angleWheel+=2;
    if(yaw < 0)
      angleWheel-=2;
    
    newData = false;
  }

  // wheel
  wheel(mouseX, positionY);

  // increament angel of rotation when mouseX incerases (degrees)
  if (pmouseX < mouseX) {
    angleWheel+=2;
    // send angle of rotation 
    // Enter data in this style <37.6, 12.09, 24.7>
    myPort.write("<" +angleWheel +", " +(float)pmouseX +", " +(float)mouseX +">");
    // for debugging, delete later
    println("<" +angleWheel +", " +(float)pmouseX +", " +(float)mouseX +">");
    //println("mouseX: " +mouseX);
    //println("Positive Wheel Angle: " +angleWheel +"\n");
  }
  // decreament angle of rotation when mouseX decreases (degrees)
  if (pmouseX > mouseX) {
    angleWheel-=2;
    // send angle of rotation 
    // Enter data in this style <37.6, 12.09, 24.7>
    myPort.write("<" +angleWheel +", " +(float)pmouseX +", " +(float)mouseX +">");
    // for debugging, delete later
    println("<" +angleWheel +", " +(float)pmouseX +", " +(float)mouseX +">");
    //println("mouseX: " +mouseX);
    //println("Negative Wheel Angle: " +angleWheel +"\n");
  }
  /*
  // rotate entire wheel plane
   yaw+=PI/120;
   pitch+=PI/120;
   roll+=PI/120;
   */
}

/** Draw Wheel
 */
void wheel(float positionX, float positionY) {
  // save current position of coordinate system
  pushMatrix();
  // move coordinat system based on the mouses's X position and fixed at the defined Y
  translate(positionX, positionY);
  // rotate coordinate in radians
  rotate(radians(angleWheel));
  // draw wheels outer frame/tyre
  drawCone(1500/scale, (0/scale), 0, CONE_DEPTH/scale);
  // rim support top cap
  drawTopCap(500/scale, (0/scale), 0, CONE_DEPTH/scale);
  // rim support enclosing
  drawCone(500/scale, (0/scale), 0, CONE_DEPTH/scale);
  // left cone
  drawCone(100/scale, (-250/scale), 0, CONE_DEPTH/scale+10);
  // middle cone
  drawCone(100/scale, (0/scale), 0, CONE_DEPTH/scale+10);
  // right cone
  drawCone(100/scale, (250/scale), 0, CONE_DEPTH/scale+10);
  // rim bottom cap
  drawBottomCap(500/scale, (0/scale), 0, CONE_DEPTH/scale);

  // draw wheels spokes after other features due to spoke rotations
  drawSpoke(90/scale, (0/scale), 0, -1460/scale);
  // rotate 45 degrees
  rotate(radians(45));
  // draw spoke again
  drawSpoke(90/scale, (0/scale), 0, -1460/scale);
  // draw spoke in opposite direction
  drawSpoke(90/scale, (0/scale), 0, 1460/scale);
  // rotate 90 degrees
  rotate(radians(90));
  // draw spoke again
  drawSpoke(90/scale, (0/scale), 0, 1460/scale);
  // draw in opposite direction
  drawSpoke(90/scale, (0/scale), 0, -1460/scale);
  //restore coordinate system to initial position before translation
  popMatrix();
}

/** Draw cone's top cap
 */
void drawTopCap(float radius, float coneX, float coneY, float depth) {
  //fill(0,0,0);
  beginShape(POLYGON);
  for (int i=0; i<=pts; ++i) {
    float px = cos(radians(ang))*radius;
    float py = sin(radians(ang))*radius;
    vertex(coneX+px, coneY+py, depth);
    ang+=360/pts;
  }
  endShape();
} 

/** Draw cone's bottom cap
 */
void drawBottomCap(float radius, float coneX, float coneY, float depth) {
  //fill(0,0,0);
  beginShape(POLYGON);
  for (int i=0; i<=pts; ++i) {
    float px = cos(radians(ang))*radius;
    float py = sin(radians(ang))*radius;
    vertex(coneX+px, coneY+py, -depth);
    ang+=360/pts;
  }
  endShape();
} 

/** Draw cones based on position and diameter
 */
void drawCone(float radius, float coneX, float coneY, float coneZ) {
  //body
  beginShape(QUAD_STRIP);
  for (int i=0; i<=pts; i++) {
    float  px = cos(radians(ang))*radius;
    float  py = sin(radians(ang))*radius;
    vertex(coneX+px, coneY+py, coneZ);
    vertex(coneX+px, coneY+py, -coneZ);
    ang+=360/pts;
  }
  endShape();
}

/** Draw hollow spokes
 */
void drawSpoke(float radius, float spokeX, float spokeY, float depth) {
  //translate(-1800,0,0);
  beginShape(QUAD_STRIP);
  for (int i=0; i<=pts; i++) {
    float  px = cos(radians(ang))*radius;
    float  py = sin(radians(ang))*radius;
    //vertex(1200+(px-px/2), py-py/2, 900);
    // face z plane (extrudes depth on z plane of cones)
    vertex((py/2)+spokeX, 0+depth, (px/2)+spokeY);
    //vertex(1200+px, py, -900);
    // py -> adjust x direction | 400 -> adjust y dirextion 
    vertex(py+spokeX, 0, px+spokeY);
    ang+=360/pts;
  }
  endShape();
}

/**
 *  Recieve data based on markers
 */
void recvWithStartEndMarkers() {
  // ensure currently red data is not preempted by incoming data
  boolean recvInProgress = false;
  // recieve data from first index
  byte ndx = 0;
  // define start marker
  char startMarker = '[';
  // define end marker
  char endMarker = ']';
  // variable to represent each character
  char rc;

  // while there is no new data but values exist on the serial line,
  // read the available values
  while (myPort.available() > 0 && newData == false) {
    rc = myPort.readChar();
    // if values are being read,
    if (recvInProgress == true) {
      //  and your are not at the end marker,
      if (rc != endMarker) {
        // store the read values to the first recieved-index,
        receivedChars[ndx] = rc;
        // then move to the next index
        ++ndx;
        // make sure the received character is bound by the desired char limit
        if (ndx >= numChars) {
          ndx = numChars -1;
        }
      } else { // when the end-of marker is noticed
        // terminate the string
        //receivedChars[ndx] = '\0';
        // notify that receiving has elapsed
        recvInProgress = false;
        // reset index for next data to be recieved
        ndx = 0;
        // notify that recieved data is available
        newData = true;
      }
    } else if (rc == startMarker) {
      // define the start of recieving data once a start-marker is noticed
      recvInProgress = true;
    }
  }
} // eof recvWithStartEndMarkers
