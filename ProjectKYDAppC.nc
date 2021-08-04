#define NEW_PRINTF_SEMANTICS
#include "printf.h"
#include "ProjectKYD.h"


configuration ProjectKYDAppC {}

implementation {


/****** COMPONENTS *****/
  components MainC, ProjectKYDC as App;
  components new TimerMilliC() as node_t;
  components ActiveMessageC;
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);
  components PrintfC;

/****** INTERFACES *****/
  //Boot interface
  App.Boot -> MainC.Boot;
  
  //Timer interface
  App.NodeTimer -> node_t;
  
  App.SplitControl -> ActiveMessageC;
  App.AMSend -> AMSenderC;
  App.Packet -> AMSenderC;
  App.Receive -> AMReceiverC;
}

