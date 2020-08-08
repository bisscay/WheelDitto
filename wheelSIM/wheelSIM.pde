/**  References:
*    https://learn.sparkfun.com/tutorials/connecting-arduino-to-processing/all
*    https://forum.processing.org/one/topic/draw-a-cone-cylinder-in-p3d.html
*    https://forum.processing.org/two/discussion/4047/how-to-shoot-points-and-rotate-wheels
*/
import processing.serial.*;

// import toxiclib library to acces quaternion class ------------- To Be Deleted
//import toxi.geom.*;

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
// for whole shape rotation
// will be an array that holds feed from the sensor to alter animation ------ TO DO !!!!!
float [] sensorFeed = {0,0,0};
// alters the ang in vertex
int pts = 120;
// defines the depth of the wheel
float CONE_DEPTH = 200;

// hold updates for quaternion from sensor
/////
///////////////////////////////////////// test with static values --------- To Be Deleted
/////
float[] q = {0, 0, 0, 0};//new float[4];
// Quaternion initialized to unrotated state
//Quaternion quat = new Quaternion(1, 0, 0, 0);

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
  println(Serial.list());
  // identify my mac's serial port
  String portName = Serial.list()[0]; // 0 in linux | 2 on mac
  // define rate of data transfer
  myPort = new Serial(this, portName, 9600);
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
  
  /** To Be Deleted ------------------------------------------------------------------
  // toxiclibs direct axis angle rotation from quaternion (No gimbal lock)
  // (axis order [1, 3, 2] and inversion [-1, +1, +1] is a consequence of
  // different coordinate system orientation assumptions between procerssing
  // and InvenSense DMP)
  float[] axis = quat.toAxisAngle();
  rotate(axis[0], -axis[1], axis[3], axis[2]);
  // update the axis based on feed from sensor
  // test manual updates
  quat.set(q[0], q[1], q[2], q[3]);
  ------------------------------------------------------------------------------------
  */
  // translate wheel on plane
  stroke(255,0,0);
  line(-500, 1400/scale, 0, 500, 1400/scale, 0);
  // color and define strokes for presentation
  stroke(200);
  fill(0, 200, 0);
  
/*
  // rotate wheel for analysis
  rotateY(sensorFeed[0]);
  rotateX(sensorFeed[1]*2);
  rotateZ(sensorFeed[2]);
*/

// wheel
  wheel(mouseX, positionY);
  
  // increament angel of rotation when mouseX incerases (degrees)
  if(pmouseX < mouseX) {
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
  if(pmouseX > mouseX) {
    angleWheel-=2;
    // send angle of rotation 
    // Enter data in this style <37.6, 12.09, 24.7>
    myPort.write("<" +angleWheel +", " +(float)pmouseX +", " +(float)mouseX +">");
    // for debugging, delete later
    println("<" +angleWheel +", " +(float)pmouseX +", " +(float)mouseX +">");
    //println("mouseX: " +mouseX);
    //println("Negative Wheel Angle: " +angleWheel +"\n");
  }
  
  // rotate entire wheel plane
  sensorFeed[0]+=PI/120;
  sensorFeed[1]+=PI/120;
  sensorFeed[2]+=PI/120;
}

/** Draw Wheel
*/
void wheel(float positionX, float positionY){
  // save current position of coordinate system
  pushMatrix();
  // move coordinat system based on the mouses's X position and fixed at the defined Y
  translate(positionX,positionY);
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
