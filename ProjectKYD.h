#ifndef RADIO_COUNT_TO_LEDS_H
#define RADIO_COUNT_TO_LEDS_H

//payload of the msg
typedef nx_struct my_msg {
	nx_uint8_t id; //Id of the sensor node
} my_msg_t;


enum{
AM_MY_MSG = 20,
};

#endif
