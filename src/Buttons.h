/*
 * Buttons.h
 *
 * Button listener
 */

#ifndef BUTTONS_H_
#define BUTTONS_H_

//numbers that function pinsneq returns that correspond to buttons
#define buttonA 14
#define buttonB 13
#define buttonC 11
#define buttonD 7

// Button listener that communicates with distributor in order to
// Start, pause and terminate bluring
void buttonListener(in port b, out port spkr, chanend toDistributor);

#endif /* BUTTONS_H_ */
