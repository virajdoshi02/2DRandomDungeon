<h1 align="center">Random Dungeon Generator</h1>
<h3 align="center">An MST dungeon generator in Godot</h3>

**Concept:**

I was interested by the idea of procedural generation, so I decided to play around by making a procedurally generated dungeon in 2D, similar to the dungeons created in the "Pokemon Mystery Dungeon" games. In the algorithm, I first randomly generate rooms and then pick the largest ones. I then find an MST of that graph and add walkways that join the vertices of each edge, including the rooms that were created in the path of all walkways. 

However, I noticed that dungeons should be confusing and have some cyclic elements, so I found the longest path of the MST, and created an edge that joined both its endpoints, creating a cycle in the graph. I later added limitations to the number of leaves and number of rooms with treasure (the smaller, lighter rooms are treasure rooms, while the bigger ones have enemies). 

<br>

**Images:**

<h1 align="center">

  <img width="1440" alt="Screenshot 2023-08-27 at 9 22 54 AM" src="https://github.com/virajdoshi02/2DRandomDungeon/blob/main/Screenshot%202023-08-28%20at%201.18.56%20PM.png">

<img width="1440" alt="Screenshot 2023-08-27 at 9 22 54 AM" src="https://github.com/virajdoshi02/2DRandomDungeon/blob/main/Screenshot%202023-08-28%20at%201.30.23%20PM.png">


</h1>
