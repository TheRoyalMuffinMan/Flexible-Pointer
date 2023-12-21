# Final Project
- Andrew Hoyle (hoyle020)
- Robert Hairston (hairs016)

## Premise
The final project we have presented here is an interactive, locomotion-based VR experience. This locomotion is performed by a teleportation pointer that can be flexed by the user. Further, this pointer can be extended if more length is required to teleport a distance. Our idea for this project is based on the paper from **Alex Olwal** and **Steven Feiner** referenced [here](https://uist.acm.org/archive/adjunct/2003/pdf/posters/p17-olwal.pdf) at Columbia University. Some modifications in the pointer that deviate from the one described in the pointer will be explained, and further additions will be included in our description.

## Design

### Flexing Manipulation
In the paper, they perform flexing between two controllers, utilizing a quadratic Bézier function to produce their respected flexed pointer. Instead, in our implementation, the pointer is flexed between the user's controller (*point_zero*), the user-manipulated *point_one*, and the sentimental position, which we mark as *point_two*. Similarly, we use a quadratic Bézier function to produce the points between these 3 points, supplying different *t* timestamps to the function. Determining the incrementation between *t* timestamps is computed by a bisection, which we go into greater detail about later. The idea behind this approach is that the user has more visible control over the flexing aspect of the pointer since *point_one* and *point_two* can be more freely controlled. Thus allowing for more drags to increase accuracy in flexing.

![flexible](images/flexible.png "Flexing The Pointer")

### Extension
Our current implementation supports extension of the pointer in the given direction that it is pointing. This is done by computing a direction vector between *p<sub>n</sub>* where [*point_one, p<sub>0</sub>, ..., p<sub>n</sub>, point_two*] and *point_two*. Thus allowing us to easily expand the direction the pointer is being flexed in. We can dynamically supply more spheres as the pointer expands allowing the user to maintain decent visibility on the length of the pointer. Similarly the rate at which pointers appear is determined by bisection.

![extention](images/extention.png "Extending The Pointer")

### Map & Limited Teleportations
In order to best utilize and showcase our pointer, we decided to supply the user with a visible map. This map provides vision and allows them to circumvent difficult obstacles in less time with the flexible pointer. Further, to showcase the utility of the pointer, the user is limited in how many teleports they can perform. This is done to show how the flexibility of the pointer provides the user with an efficient traversing mechanism.

![Map & Counter](images/mapcounter.png "Map and Teleport Counter")

### Obstacle Course
Our obstacle is specificed geared to be completed optimally with the flexible pointer. This .... robert write this part

![Obstacle Course](images/obstaclecourse.png "Obstacle Course")

## Function Documentation

## Attributions