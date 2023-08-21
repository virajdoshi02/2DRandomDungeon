<h1 align="center">Random Dungeon Generator</h1>
<h3 align="center">An MST dungeon generator in Godot,</h3>

(add image here)

**Concept:**

I was interested by the idea of procedural generation, so I decided to play around by making a procedurally generated dungeon in 2D, similar to the dungeons created in the "Pokemon Mystery Dungeon" games. In the algorithm, I first randomly generate rooms and then pick the largest ones. I then find an MST of that graph and add walkways that join the vertices of each edge, including the rooms that were created in the path of all walkways. 

However, I noticed that dungeons should be confusing and have some cyclic elements, so I found the longest path of the MST, and created an edge that joined both its endpoints, creating a cycle in the graph. I later added limitations to the number of leaves and number of rooms with treasure (the smaller rooms are treasure rooms). Then, I decided that I wanted the dungeon layout to be more horizontal, so I decided to make the rooms spawn within an ellipse, and I limited the slope of the last edge to be horizontal.

<br>

**My Team:**

I created this alone.

<br>

**My Roles in the process:**

Everything was done by me.

<br>

**Challenges:**

* Corridor creation logic:

  * One of the hardest parts was the logic behind creating the corridors, mostly because I had to include the rooms that intersected all the corridors. I took some time to test out what worked well, and ended up settling for a brute force approach.
 
* MSTDungeon class:

  * I had to create an MST Dungeon class using Godot's AStar 2D class in order to properly create this dungeon, which took some time to figure out as well
