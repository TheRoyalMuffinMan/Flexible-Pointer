# Final Project
- Andrew Hoyle (hoyle020)
- Robert Hairston (hairs016)

## Premise
The final project we have present here is an interactive locomotion-based VR experience. This locomotion is performed by a teleportation pointer that can be flexed by the user. Further this pointer can be extended if more length is required to teleport a distance. Our idea for this project is based on the paper from Alex Olwal and Steven Feiner referenced [here](https://uist.acm.org/archive/adjunct/2003/pdf/posters/p17-olwal.pdf) at Columbia University. Some modifications in the pointer that deivate from the one described in the pointer will be explained and further additions our included in our pointer implementation.

## Design

### Flexing Manipulation
In the paper they perform flexing between two controllers utilizing a quadratic Bézier function to produce their respected flexed pointer. Instead in our implementation, the pointer is flexed between the user's controller and the single sentimenal point we mark as *point_two*. Similarly we use a quadratic Bézier function to produce the points between the *point_zero* (controller) and *point_two*. The idea for this approach is that the user has more visible control on the flexing aspect for the pointer and can utilize more drags to get increased accuracy in flexing.

![flexible](images/flexible.png "Flexing The Pointer")

### Extension
Our current implementation supports extension of the pointer in the given direction that it is pointing. This is done by computing a direction vector pushing *point_two* out in that direction. We dynamically supply more points as this expands allowing the user to maintain decent visibility on the length of the pointer.

![extention](images/extention.png "Extending The Pointer")

### Map & Limited Teleportations
In order to best utilize and showcase our pointer, we decided to supply the user with a visible map. This map gives vision to our user and allows for them to circumvent difficult obstacles in less teleports with the flexible pointer.
Further to showcase the utility of the pointer, the user is limited on how many teleports they can perform. This is done to show that the flexibility of the pointer supplies to user with efficient traveling mechinism. 

![Map & Counter](images/mapcounter.png "Map and Teleport Counter")

### Obstacle Course
Our obstacle is specificed geared to be completed optimally with the flexible pointer. This .... robert write this part

![Obstacle Course](images/obstaclecourse.png "Obstacle Course")

## Function Documentation

## Attributions