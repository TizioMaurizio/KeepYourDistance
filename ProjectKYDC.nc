#include "ProjectKYD.h"
#include "Timer.h"
#include "printf.h"

module ProjectKYDC {

  uses {
  /****** INTERFACES *****/
	interface Boot; 
	
    interface SplitControl; //to turn on the radio
	interface AMSend;
	interface Receive;
	interface Packet;
	
	interface Timer<TMilli> as NodeTimer; //timer for current node

  }

} implementation {

  struct Node{
  	uint8_t rec_id;
  	uint8_t counter;
  	struct Node *next;
  };
  
  message_t packet;
  struct Node* head = NULL;
  uint8_t rec_counter;

  void sendReq();
  void insertNode(struct Node** h, uint8_t id, uint8_t count);
  int searchCounter(struct Node** h, uint8_t id);
  void updateCounter(struct Node** h, uint8_t id, uint8_t count);
  
  
  //***************** Send request function ********************//
  void sendReq() {
	my_msg_t* mess = (my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
	if(mess == NULL){
		return ;
	}
	mess->id = TOS_NODE_ID;
	
	if(call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(my_msg_t)) == SUCCESS){
		dbg("radio", "Id sent.\n");
	}
 }        

  //Insert the Node at the head of the list
  void insertNode(struct Node** h, uint8_t id, uint8_t count){
  	struct Node* elem = (struct Node*) malloc(sizeof(struct Node));
  	elem->rec_id = id;
  	elem->counter = count;
  	elem->next = (*h);
  	(*h) = elem;
  }
  
  //Find the counter of sent messages from a specific mote, given the id
  int searchCounter(struct Node** h, uint8_t id)
  {
  	struct Node *temp = *h;
  	while(temp!=NULL && temp->rec_id!=id){
  		temp = temp->next;
  	}
  	if(temp!=NULL)
  		return temp->counter;
  	else
  		return -1;
  }
  
  //Update the counter
  void updateCounter(struct Node** h, uint8_t id, uint8_t count){
  	struct Node *temp = *h;
  	while(temp!=NULL && temp->rec_id!=id){
  		temp = temp->next;
  	}
  	if(temp!=NULL)
  		temp->counter = count;
  	else
  		dbg("radio", "error, no mote id associated to the counter\n");
  }

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted on mote %d.\n", TOS_NODE_ID);
	call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
    if(err == SUCCESS){
    	dbg("radio", "Radio ON, timer starts\n");
		call NodeTimer.startPeriodic(500);
		
    }else{
    	dbg("radio", "Radio error, trying to turning on again...\n");
    	call SplitControl.start();
    }
  }
  
  event void SplitControl.stopDone(error_t err){}

  //***************** MilliTimer interface ********************//
  event void NodeTimer.fired() {
  	dbg("timer", "Timer fired, send a request\n");
 	dbg("radio", "Send request\n");
 	sendReq();
  
  }
  

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
	if(&packet == buf){
		dbg("radio", "Packet sent at time %s!\n", sim_time_string());
	}else{
		dbgerror("radio", "Radio error %s!\n", err);
	}
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	if(len != sizeof(my_msg_t)){
		dbgerror("radio", "Packet malformed\n");
		return buf;
	}else{
		my_msg_t* mess = (my_msg_t*)payload;
		dbg("radio", "Received a message at time %s!\n", sim_time_string());
		dbg_clear("packet", "\t\tID: %u\n", mess->id);
		rec_counter = searchCounter(&head, mess->id);
		
		if(rec_counter == -1){
			//add node to list
			insertNode(&head, mess->id, 1);
		}
		else if(rec_counter == 9){
			rec_counter++;
			printf("S Mote: %ld\n , R Mote: %ld\n", mess->id, TOS_NODE_ID);
  			printfflush();
  			rec_counter = 0;
  			updateCounter(&head, mess->id, rec_counter);
		}else{
			rec_counter++;
			updateCounter(&head, mess->id, rec_counter);
		}
		
		
		return buf;
	}

  }
  
}

