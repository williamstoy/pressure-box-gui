#define LINE_BUF_SIZE 128   //Maximum input string length
#define ARG_BUF_SIZE 64     //Maximum argument string length
#define MAX_NUM_ARGS 8      //Maximum number of arguments


/* TODO: CLEAN THIS UP BY PUTTING VALVE HANDLES INTO AN ARRAY */


#include <AFMotor.h>
AF_DCMotor valve1(1, MOTOR12_1KHZ); // create motor #1, 1KHz pwm
AF_DCMotor valve2(2, MOTOR12_1KHZ); // create motor #2, 1KHz pwm
AF_DCMotor valve3(3, MOTOR34_1KHZ); // create motor #3, 1KHz pwm
AF_DCMotor valve4(4, MOTOR34_1KHZ); // create motor #4, 1KHz pwm
 
int LEDpin = 13;
int blink_cycles = 10;      //How many times the LED will blink
bool error_flag = false;
 
char line[LINE_BUF_SIZE];
char args[MAX_NUM_ARGS][ARG_BUF_SIZE];
 
//Function declarations
int cmd_toggle();
int cmd_pressure();
int cmd_atm();
 
//List of functions pointers corresponding to each command
int (*commands_func[])(){
    &cmd_breakin,
    &cmd_pressure,
    &cmd_atm
};
 
//List of command names
const char *commands_str[] = {
    "breakin",
    "pressure",
    "atm"
};
 
int num_commands = sizeof(commands_str) / sizeof(char *);
 
void setup() {
    Serial.begin(115200);

    valve1.setSpeed(255);
    valve2.setSpeed(255);
    valve3.setSpeed(255);
    valve4.setSpeed(255);

    valve1.run(RELEASE);
    valve2.run(RELEASE);
    valve3.run(RELEASE);
    valve4.run(RELEASE);
 
    cli_init();
}
 
void loop() {
    my_cli();
}


void cli_init(){
    Serial.println("Welcome to this simple Pressure Box Control command line interface (CLI).");
}
 
 
void my_cli(){
    //Serial.print("> ");
 
    read_line();
    if(!error_flag){
        parse_line();
    }
    if(!error_flag){
        execute();
    }
 
    memset(line, 0, LINE_BUF_SIZE);
    memset(args, 0, sizeof(args[0][0]) * MAX_NUM_ARGS * ARG_BUF_SIZE);
 
    error_flag = false;
}


void read_line(){
    String line_string;
 
    while(!Serial.available());
 
    if(Serial.available()){
        line_string = Serial.readStringUntil('\n');
        if(line_string.length() < LINE_BUF_SIZE){
          line_string.toCharArray(line, LINE_BUF_SIZE);
          //Serial.println(line_string);
        }
        else{
          Serial.println("Input string too long.");
          error_flag = true;
        }
    }
}
 
void parse_line(){
    char *argument;
    int counter = 0;
 
    argument = strtok(line, " ");
 
    while((argument != NULL)){
        if(counter < MAX_NUM_ARGS){
            if(strlen(argument) < ARG_BUF_SIZE){
                strcpy(args[counter],argument);
                argument = strtok(NULL, " ");
                counter++;
            }
            else{
                Serial.println("Input string too long.");
                error_flag = true;
                break;
            }
        }
        else{
            break;
        }
    }
}
 
int execute(){  
    for(int i=0; i<num_commands; i++){
        if(strcmp(args[0], commands_str[i]) == 0){
            return(*commands_func[i])();
        }
    }
 
    Serial.println("Invalid command.");
    return 0;
}

int cmd_pressure(){
    if(strcmp(args[1], "1") == 0){
        Serial.println("Switching Channel 1 to Pressure");
        valve1.run(FORWARD);
    }
    else if(strcmp(args[1], "2") == 0){
        Serial.println("Switching Channel 2 to Pressure");
        valve2.run(FORWARD);
    }
    else if(strcmp(args[1], "3") == 0){
        Serial.println("Switching Channel 3 to Pressure");
        valve3.run(FORWARD);
    }
    else if(strcmp(args[1], "4") == 0){
        Serial.println("Switching Channel 4 to Pressure");
        valve4.run(FORWARD);
    }
    else{
        Serial.println("Invalid command.");
        return 1;
    }

    return 0;
}

int cmd_breakin() {
  String argument_2 = args[2];
  int break_in_time = argument_2.toInt();
  
  if(break_in_time == 0){
    Serial.println("Error: Could not read msec break in time");
    return 1;
  }

  if(strcmp(args[1], "1") == 0){
      Serial.println("Breaking in on Channel 1");
      valve1.run(FORWARD);
      delay(break_in_time);
      valve1.run(RELEASE);
  }
  else if(strcmp(args[1], "2") == 0){
      Serial.println("Breaking in on Channel 2");
      valve2.run(FORWARD);
      delay(break_in_time);
      valve2.run(RELEASE);
  }
  else if(strcmp(args[1], "3") == 0){
      Serial.println("Breaking in on Channel 3");
      valve3.run(FORWARD);
      delay(break_in_time);
      valve3.run(RELEASE);
  }
  else if(strcmp(args[1], "4") == 0){
      Serial.println("Breaking in on Channel 4");
      valve4.run(FORWARD);
      delay(break_in_time);
      valve4.run(RELEASE);
  }
  else{
      Serial.println("Invalid command.");
      return 1;
  }
  
  return 0;
}

int cmd_atm(){
    if(strcmp(args[1], "1") == 0){
        Serial.println("Switching Channel 1 to Atmosphere");
        valve1.run(RELEASE);
    }
    else if(strcmp(args[1], "2") == 0){
        Serial.println("Switching Channel 2 to Atmosphere");
        valve2.run(RELEASE);
    }
    else if(strcmp(args[1], "3") == 0){
        Serial.println("Switching Channel 3 to Atmosphere");
        valve3.run(RELEASE);
    }
    else if(strcmp(args[1], "4") == 0){
        Serial.println("Switching Channel 4 to Atmosphere");
        valve4.run(RELEASE);
    }
    else{
        Serial.println("Invalid command.");
        return 1;
    }

    return 0;
}

