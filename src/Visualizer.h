/*
 * Visualizer.h
 *
 *  Definition of functions used to control LEDs
 */

#ifndef VISUALIZER_H_
#define VISUALIZER_H_


// Shows a signle led in a given quadrant
int showLED(out port p, chanend fromVisualiser);

// Visualizer of collector progress
void visualiser(chanend fromCollector,
		chanend toQuadrant0, chanend toQuadrant1,
		chanend toQuadrant2, chanend toQuadrant3);


#endif /* VISUALIZER_H_ */
