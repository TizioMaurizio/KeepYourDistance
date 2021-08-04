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
  
  void init_ID(){
  	uint8_t i = 0;
  	while(i<20){
  		rec_id[i] = 0;
  		i++;
  	}
  }
  
  message_t packet;
  uint8_t index;

  void setIndex(uint8_t id){
  	uint8_t i = 0;
  	while(rec_id[i]!= 0 || rec_id[i]!=id)
  		i++;
  	
  	index = i;
  }
        
 
  event void Boot.booted() {
	call AMControl.start();
  }

  //***************** SplitControl interface ********************//
  event void AMControl.startDone(error_t err){
    if(err == SUCCESS){
    	printf("success\n");
    	printfflush();
		call MilliTimer.startPeriodic(500);
		printf("mote started: %d\n", TOS_NODE_ID);
		
    }else{
    	call AMControl.start();
    }
  }
  
  event void AMControl.stopDone(error_t err){}

  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {

 	my_msg_t* mess = (my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
	if(mess == NULL){
		return ;
	}
	mess->id = TOS_NODE_ID;
	printf("message by: %d\n", TOS_NODE_ID);
	
	if(call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(my_msg_t)) == SUCCESS){
		//printf("sent id\n");
    	//printfflush();
	}
  }
  

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
	/*if(&packet == buf){
		printf("packet sent\n");
    	printfflush();
	}else{
		printf("error, packet not sent\n");
    	printfflush();
	}*/
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf, void* payload, uint8_t len) {
	if(len != sizeof(my_msg_t)){
		printf("packet malformed\n");
    	printfflush();
		return buf;
	}else{
		my_msg_t* mess = (my_msg_t*)payload;
		printf("message received\n");
		printf("received id: %d\n", mess->id);
    	printfflush();
		setIndex(mess->id);
		
		if(rec_id[index] == 0){
			//doesn't exist an index corresponding to that mote id
			//index is the first free position
			rec_id[index] = mess->id;
			rec_counter[index] = 1;
			
		}
		else{
			//already exist the index for that mote 
			if(rec_counter[index] == 9){
				rec_counter[index]++;
				printf("S Mote: %d\n , R Mote: %d\n", mess->id, TOS_NODE_ID);
	  			printfflush();
	  			rec_counter[index] = 0;
			}else{
				rec_counter[index]++;
			}
		}
		
		return buf;
	}

  }
  
}

