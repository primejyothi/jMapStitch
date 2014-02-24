jmaps.sh
===============
jmaps.sh combine the map tile images downloaded by JOSM (Java OpenStreetMap Editor) into single large image file.

JOSM downloads the OSM tiles to a folder pointed by imagery.tms.tilecache_path (Edit->Preferences,Expert Mode, Advance Preferences, imagery.tms.tilecache_path). Use the "Show Tile Info" from the pop up menu in JOSM to identify the name of the tile file. The tiles are usually named as zz/xxxxx/yyyyy and the corresponding tile files can be found in the tile cache folder with the name zz_xxxxx_yyyyy.png 

#### Running jmaps.sh
jmaps.sh [-d] [-h] -t tileDirectory -l topLeftImage -r lowerRightImage -o outputFile
```
         -d : Enable debug messages
         -h : Display this help message
         -t : Directory containing tile images
         -l : Name of the top left tile image file
         -r : Name of the lower right tile image file
         -o : Name of the output file
```	
