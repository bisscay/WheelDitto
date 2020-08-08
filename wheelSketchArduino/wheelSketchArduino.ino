/**References:
 * https://forum.arduino.cc/index.php?topic=396450.0
 * https://www.youtube.com/watch?v=XCyRXMvVSCw
 * https://www.instructables.com/id/MPU-6050-Tutorial-How-to-Program-MPU-6050-With-Ard/
 */

#include <Servo.h>

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

//============

void setup() {
  Serial.begin(9600);
  // For Debuggin - Delte later -----------
  /*
    Serial.println("This demo expects 3 floating pieces of data");
    Serial.println("Enter data in this style <37.6, 12.09, 24.7> ");
    Serial.println();*/
  // --------------------------------------
  // attach servo on pin 9 to servo object
  // i assume this sets the direction of the pin to output
  myservo.attach(9);
}

//============

void loop() {
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
  }
}

// Check for the boundary markers that define new data i.e < >

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

//============

void parseData() {      // split the recieved data into its parts

  char * strtokIndx; // this is used by strtok() as an index

  strtokIndx = strtok(tempChars, ",");     // get the first part - the string
  xAxis = atof(strtokIndx); // copy it to an xAxis float

  strtokIndx = strtok(NULL, ","); // this continues where the previous call left off
  pMouseX = atof(strtokIndx);     // convert this part to a pMouseX float

  strtokIndx = strtok(NULL, ",");
  mouseX = atof(strtokIndx);     // convert this part to a mouseX float

}

//============

void showParsedData() {
  /*
    Serial.print("X: ");
    Serial.println(xAxis);
    Serial.print("pMouseX: ");
    Serial.println(pMouseX);
    Serial.print("mouseX: ");
    Serial.println(mouseX);*/
}
