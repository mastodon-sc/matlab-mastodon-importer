# A MATLAB importer for Mastodon files.

This repository contains several MATLAB functions used to import Mastodon files (https://github.com/fiji/TrackMate3).

The import procedure is based on directly deserializing the binary files using MATLAB low-level API, and therefore has no dependency. 
However, it is tyightly coupled to the Mastodon file format, and any changes made to it will likely break the importer.

## Import the full track graph and the spot ellipsoids.

![After importing top view](images/ScreenShot1.png?raw=true "Title")

![After importing side view](images/ScreenShot2.png?raw=true "Title")


## Import the tags.

![Nodes table with tags](images/ScreenShot3.png?raw=true "Title")

![Coloring by tags](images/ScreenShot4.png?raw=true "Title")

