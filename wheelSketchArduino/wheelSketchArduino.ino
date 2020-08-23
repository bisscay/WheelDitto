/**References:
 * Robin2 (2016) ‘Serial Input Basics - Updated’ available: https://forum.arduino.cc/index.php?topic=396450.0 [accessed: 18/08/2020, 15:40]
 * DroneBot Workshop (2019) ‘Build a Digital Level with MPU-6050 AND Arduino’ available: https://dronebotworkshop.com/mpu-6050-level/ [accessed: 16/08/2020, 11:48].
 * DroneBot Workshop (2018) ‘Using Servo Motors with the Arduino’ available: https://dronebotworkshop.com/servo-motors-with-arduino/ [accessed: 17/08/2020, 10:06].
 */
// wheelSketchArduino.pde
// Sketch for MPU6050 IMU and Servo motor linked to  wheel simulation in processing
// Author: Bissallah Ekele Jr.
// Date:   15/08/2020

#include <Servo.h>
#include <Wire.h>
#include <MPU6050.h>

// create servo object to control a servo
Servo myservo;

// defines position of wheel
int pos;

// desired character limit
const byte numChars = 32;
// to hold data recieved from serial port
char receivedChars[numChars];
// temporary array for use when parsing
char tempChars[numChars];

// variables to hold the parsed data
//char messageFromPC[numChars] = {0};
//int integerFromPC = 0;
float xAxis = 0.0;  // only x axis defines translational motion
float pMouseX = 0.0;
float mouseX = 0.0;

boolean newData = false;

/* FromAdruino Params */

MPU6050 mpu;

// Timers
unsigned long timer = 0;
float timeStep = 0.01;

// Pitch, Roll and Yaw values
float pitch = 0;
float roll = 0;
float yaw = 0;

void setup() {
  // initialize serial communications at a 115200 baud rate
  Serial.begin(115200);
  // attach servo on pin 9 to servo object
  // i assume this sets the direction of the pin to output
  myservo.attach(9);

  // initialize MPU6050
  // output error for debugging if sensor is missing
  while(!mpu.begin(MPU6050_SCALE_2000DPS, MPU6050_RANGE_2G))
  {
    Serial.println("Could not find a valid MPU6050 sensor, check wiring!");
    delay(500); 
  }
  // Calibrate gyroscope, the calibration must be at rest
  mpu.calibrateGyro();
  // Set threshold sensitivity. Default 3
  mpu.setThreshold(3);
  // Check settings for debugging
  //checkSettings();
}// eof setup

void loop() {
  // Acceleration Readings
  // read normalized values
  Vector normAccel = mpu.readNormalizeAccel();
  
  /*// Uncomment this if you want to use gyroscope readings
  // For Gyroscope Readings
  timer = millis();
  // Read normalized values
  Vector normGyro = mpu.readNormalizeGyro();
  
  // Calculate Pitch, Roll and Yaw
  pitch = pitch + normGyro.YAxis * timeStep;
  roll = roll + normGyro.XAxis * timeStep;
  yaw = yaw + normGyro.ZAxis * timeStep;

  // Ouput raw
  Serial.print("[");
  Serial.print(pitch);
  Serial.print(",");
  Serial.print(roll);
  Serial.print(",");
  Serial.print(yaw);
  Serial.print("]");
  
  // wait to full timeStep period so we don't drive ourselves crazy
  delay((timeStep*1000) - (millis() - timer));
*/
  
  recvWithStartEndMarkers();
  if (newData == true) {
    strcpy(tempChars, receivedChars);
    // this temporary copy is necessary to protect the original data
    //   because strtok() used in parseData() replaces the commas with \0
    parseData();
    // map ang in processing to pos in arduino
    // tell servo to go to position in variable 'xAxis'
    // the above was not implemented,
    // rather a positive ang caused a positive rotation
    // a -ve angle cause -ve effects
    // and no rotation caused no effect
    // i didtn get the rotation to be based on the desired angle
    // (TO DO) map|scale 0 - 90 to the range of positive increaments of the xAxis
    // TO DO: Create check guards to prevent -ve angles
    // Note: use writeMicroseconds instead of write for better control
    if (pMouseX > mouseX) {
      // rotate counter clock wise at 90- degrees (1.0 ms);
      for (pos = 0; pos < 90; pos += 1) {
        myservo.write(pos);
        //delay(15);
      }
      myservo.write(90);
    } else if (pMouseX < mouseX) {
      // rotate clock wise at 90+ degress (2.0 ms)
      for (pos = 90; pos <= 180; pos += 1) {
        myservo.write(pos);
        //delay(15);
      }
      myservo.write(90);
    } else if (pMouseX == mouseX) {
      // Stop at 90 degrees (1.5 ms)
      for (pos = 0; pos <= 20; pos += 1) {
        myservo.write(90);
        delay(15);
      }
    }
    //showParsedData();

    newData = false;
  } else {
    // Output values with x-axis as reference plane
    // TO DO: No need sending x & z values
    Serial.print("[");
    Serial.print(normAccel.YAxis);/*
    Serial.print(",");
    Serial.print(normAccel.YAxis);
    Serial.print(",");
    Serial.print(normAccel.ZAxis);*/
    Serial.print("]");
    
    delay(800);
  }
}// eof loop

/**recvWithStartEndMarkers()
 * Check for the boundary markers that define new data i.e < >
 * 
 * return void
 */
void recvWithStartEndMarkers() {
  // ensure that currently read data is not prompted if a new data arrives faster that read is comlpeted
  static boolean recvInProgress = false;
  // initialize reciept of data to start from first index
  static byte ndx = 0;
  // define start marker
  char startMarker = '<';
  // define end marker
  char endMarker = '>';
  // at a point represents each read character
  char rc;

  // while there is no new data but values exist on the serial line, read the available values
  while (Serial.available() > 0 && newData == false) {
    rc = Serial.read();
    // if values are being read, and your are not at the end marker,
    // store the read value to the first recieved-index, then move to the next index
    if (recvInProgress == true) {
      if (rc != endMarker) {
        receivedChars[ndx] = rc;
        ndx++;
        // make sure the received character is bound by the desired character limit
        if (ndx >= numChars) {
          ndx = numChars - 1;
        }
      } // when the end-of marker is noticed, terminate string by appending \0
      else {
        receivedChars[ndx] = '\0'; // terminate the string
        // notify that recieving has elapsed
        recvInProgress = false;
        // reset index for next data to be recieved
        ndx = 0;
        // notify that recieved data is available
        newData = true;
      }
    }
    // defines the start of recieving data once a start-marker is noticed
    else if (rc == startMarker) {
      recvInProgress = true;
    }
  }
} // eof recvWithStartEndMarkers

/**parseData()
 * split the recieved data into its parts
 * 
 * return void
 */
void parseData() {     
  // used by strtok() as an index
  char * strtokIndx; 
  // get the first part - the string
  strtokIndx = strtok(tempChars, ",");     
  // copy it to an xAxis float
  xAxis = atof(strtokIndx); 
  // continue where the previous call left off
  strtokIndx = strtok(NULL, ","); 
  // convert this part to a pMouseX float
  pMouseX = atof(strtokIndx);     

  strtokIndx = strtok(NULL, ",");
  // convert this part to a mouseX float
  mouseX = atof(strtokIndx);     

}// eof parseData

/**checkSettings()
 * Check settings for debugging
 * 
 * return void
 */
void checkSettings()
{
  Serial.println();
  
  Serial.print(" * Sleep Mode:        ");
  Serial.println(mpu.getSleepEnabled() ? "Enabled" : "Disabled");
  
  Serial.print(" * Clock Source:      ");
  switch(mpu.getClockSource())
  {
    case MPU6050_CLOCK_KEEP_RESET:     Serial.println("Stops the clock and keeps the timing generator in reset"); break;
    case MPU6050_CLOCK_EXTERNAL_19MHZ: Serial.println("PLL with external 19.2MHz reference"); break;
    case MPU6050_CLOCK_EXTERNAL_32KHZ: Serial.println("PLL with external 32.768kHz reference"); break;
    case MPU6050_CLOCK_PLL_ZGYRO:      Serial.println("PLL with Z axis gyroscope reference"); break;
    case MPU6050_CLOCK_PLL_YGYRO:      Serial.println("PLL with Y axis gyroscope reference"); break;
    case MPU6050_CLOCK_PLL_XGYRO:      Serial.println("PLL with X axis gyroscope reference"); break;
    case MPU6050_CLOCK_INTERNAL_8MHZ:  Serial.println("Internal 8MHz oscillator"); break;
  }
  
  Serial.print(" * Gyroscope:         ");
  switch(mpu.getScale())
  {
    case MPU6050_SCALE_2000DPS:        Serial.println("2000 dps"); break;
    case MPU6050_SCALE_1000DPS:        Serial.println("1000 dps"); break;
    case MPU6050_SCALE_500DPS:         Serial.println("500 dps"); break;
    case MPU6050_SCALE_250DPS:         Serial.println("250 dps"); break;
  } 
  
  Serial.print(" * Gyroscope offsets: ");
  Serial.print(mpu.getGyroOffsetX());
  Serial.print(" / ");
  Serial.print(mpu.getGyroOffsetY());
  Serial.print(" / ");
  Serial.println(mpu.getGyroOffsetZ());
  
  Serial.println();
}// eof checkSettings
