/**  References: //<>//
 *    Chrisir (2014) ‘How to shoot points and rotate wheels’ available: https://forum.processing.org/two/discussion/4047/how-to-shoot-points-and-rotate-wheels [accessed: 18/08/2020, 15:19]
 *    b_e_n (2013) ‘Connecting Arduino to Processing’ available: https://learn.sparkfun.com/tutorials/connecting-arduino-to-processing/all  [accessed: 18/08/2020, 15:23]
 *    apex_nd (2020) ‘Draw a cone/cylinder in P3D’ available: https://forum.processing.org/one/topic/draw-a-cone-cylinder-in-p3d.html [accessed: 18/08/2020, 15:29]
 */
import processing.serial.*;

// create object from serial class
Serial myPort;
// wheel's angle
float angleWheel;
// TO DO: All initializations should be done in setup
float positionY = height-113; // define height of plane
// define wheel's translation
float positionX;
// to control the wheel's scale
float scale = 15;
// for generating vertex
float ang = 0;
// alters the ang in vertex
int pts = 120;
// defines the depth of the wheel
float CONE_DEPTH = 200;

float x, y, z;

/* ToProcessing Params */
// data received from the serial port
String sensorFeed = "";
// for whole shape rotation
float yaw, pitch, roll, pYaw;
// desired character limit
final byte numChars = 32;
// defines when a new data stream arives
boolean newData = false;
// to hold data recieved from serial port
char[] receivedChars = new char[numChars];
// temporary array for use when parsing
char[] tempChars = new char[numChars];
//
int sensorTranslation = 0;

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

  if (mousePressed && (mouseButton == RIGHT)) {
    // rotate wheel for analysis
    rotateY(x);
    rotateX(y);
    rotateZ(z);
  }

  // get feed from serial line
  recvWithStartEndMarkers();
  if (newData == true) {
    //println(receivedChars);
    String sensorFeed = new String(receivedChars);
    println(sensorFeed);
    // split val into yaw, pitch and roll
    String[] splitFeed = sensorFeed.split(",");
    // assign current yaw
    yaw = Float.parseFloat(splitFeed[0]);
    //pitch = Float.parseFloat(splitFeed[1]);
    //roll = Float.parseFloat(splitFeed[2]);
    // print it out in the console for debugging
    println("Yaw: " +yaw +" Pitch: " +pitch +" Roll: " +roll);

    newData = false;
  }

  // wheel
  wheel(positionX, positionY);

  // if the mouse is held down, wheel x-translation control goes to mouse
  if (mousePressed && (mouseButton == LEFT)) {
    // increament angel of rotation when mouseX incerases (degrees)
    if (pmouseX < mouseX) {
      //wheel(mouseX, positionY);
      positionX = mouseX;
      angleWheel+=1;
      // send angle of rotation 
      // Enter data in this style <37.6, 12.09, 24.7>
      myPort.write("<" +angleWheel +", " +(float)pmouseX +", " +(float)mouseX +">");
      // for debugging, delete later
      //println("<" +angleWheel +", " +(float)pmouseX +", " +(float)mouseX +">");
      println("mouseX: " +mouseX);
      //println("Positive Wheel Angle: " +angleWheel +"\n");
    }/* // No need for this seeing that control has beeen transfered to mouse
    // else keep wheel at mouse constant point if sensor stops moving
    else if ((pmouseX == mouseX) && !(yaw == pYaw)) {
      //wheel(mouseX, positionY);
      positionX = mouseX;
    }*/
    // else decreament angle of rotation when mouseX decreases (degrees)
    else if (pmouseX > mouseX) {
      //wheel(mouseX, positionY);
      positionX = mouseX;
      angleWheel-=1;
      // send angle of rotation 
      // Enter data in this style <37.6, 12.09, 24.7>
      myPort.write("<" +angleWheel +", " +(float)pmouseX +", " +(float)mouseX +">");
      // for debugging, delete later
      //println("<" +angleWheel +", " +(float)pmouseX +", " +(float)mouseX +">");
      println("-mouseX: " +mouseX);
      //println("Negative Wheel Angle: " +angleWheel +"\n");
    }
  }
  // else control goes to the sensor
  else {
    // modify wheel sim position
    if ((yaw > pYaw) && (mouseX == pmouseX)) { // 1.2 was the sensor reference point at this test stage
      angleWheel+=5;
      //wheel(yaw*100, positionY);
      positionX = yaw*100;
    }
    if ((yaw == pYaw) && !(mouseX == pmouseX)) {
      //angleWheel-=2;
      //wheel(yaw*100, positionY);
      positionX = yaw*100;
    }
    if ((yaw < pYaw) && (mouseX == pmouseX)) {
      angleWheel-=5;
      //wheel(yaw*100, positionY);
      positionX = yaw * 100;
    }
    // store current yaw before new yaw is assigned
    pYaw = yaw;
  }

  // rotate entire wheel plane for analysis
  x+=PI/120;
  y+=PI/120;
  z+=PI/120;
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
