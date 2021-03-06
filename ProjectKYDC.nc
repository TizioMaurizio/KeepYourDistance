#include "ProjectKYD.h"
#include "Timer.h"
#include "printf.h"

module ProjectKYDC @safe() {

  uses {

	interface Boot; 
	
    interface SplitControl as AMControl; //to turn on the radio
	interface AMSend;
	interface Receive;
	interface Packet;
	
	interface Timer<TMilli> as MilliTimer; //timer for current node

  }

} implementation {

  uint8_t rec_id[20];
  uint8_t rec_counter[20];
  bool locked;
  
  
  message_t packet;
  uint8_t index;

  void setIndex(uint8_t id){
  	uint8_t i = 0;
  	while(i<20 && (rec_id[i]!= 0 && rec_id[i]!=id))
  		i++;
  	
  	index = i;
  }
     
 
  event void Boot.booted() {
	dbg("boot","Application booted on mote %d.\n", TOS_NODE_ID);
	call AMControl.start();
  }

  //***************** SplitControl interface ********************//
  event void AMControl.startDone(error_t err){
    if(err == SUCCESS){
    	dbg("radio", "Timer started on mote %d\n", TOS_NODE_ID);
		call MilliTimer.startPeriodic(500);		
    }else{
    	dbg("radio", "Radio error, trying to turning on again...\n");
    	call AMControl.start();
    }
  }
  
  event void AMControl.stopDone(error_t err){}

  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired(){
  	dbg("timer", "Timer fired on mote %d, send a request\n", TOS_NODE_ID);
    if (locked) {
      return;
    }
    else {
      ((my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t)))->id = TOS_NODE_ID;

	  if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(my_msg_t)) == SUCCESS) {
		locked = TRUE;
		dbg("radio", "Mote %d Request sent.\n", TOS_NODE_ID);
      }
    }  
	
  }
  

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
	if (&packet == buf) {
	  dbg("radio", "Packet sent at time %s from mote %d\n", sim_time_string(), TOS_NODE_ID);
      locked = FALSE;
    }
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf, void* payload, uint8_t len) {
	if(len != sizeof(my_msg_t)){
		dbgerror("radio", "Packet received by %d malformed\n", TOS_NODE_ID);
		return buf;
	}else{
		my_msg_t* mess = (my_msg_t*)payload;
		
		setIndex(mess->id);
		
		if(rec_id[index] == 0){
			//doesn't exist an index corresponding to that mote id
			//index is the first free position
			
			rec_id[index] = mess->id;
			rec_counter[index] = 1;
			dbg("radio", "Received first packet from %d, counter %d\n", rec_id[index], rec_counter[index]);
		}
		else{
			//already exist the index for that mote 
			if(rec_counter[index] == 9){
				rec_counter[index]++;
				//TOS_NODE_ID
				printf("\n");
				//printf("{\"value1\":\"%d\",\"value2\":\"%d\"}", (int)TOS_NODE_ID, (int)mess->id);
				printf("{\"value1\":\"%d\",", (int)TOS_NODE_ID);
				printf("\"value2\":\"%d\"}", (int)mess->id);
				printf("\n");
	  			printfflush();
	  			rec_counter[index] = 0;
	  			dbg("radio", "Received last packet from %d. Motes %d and %d are too close\n", rec_id[index], TOS_NODE_ID, rec_id[index]);
			}else{
				rec_counter[index]++;
				dbg("radio", "Received a packet from %d, counter %d\n", rec_id[index], rec_counter[index]);
			}
		}
		
		return buf;
	}

  }
  
}

