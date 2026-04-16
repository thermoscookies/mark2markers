# mark2markers
Davinci Resolve Plugin to import XbotGo .mark files into Davinci Resolve as timing markers
The script now supports Chameleon clicks file as well as the Falcon .mark file. The script will autodetct which one you select bases on the start time listed in the file.

* Place the .lua file in the following location:
  
  Windows: ````C:\ProgramData\Blackmagic Design\DaVinci Resolve\Fusion\Scripts\Utility````
  
  Mac: ````~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Fusion/Scripts/Utility/````
* Restart Davinci Resolve
* Open your timeline and go to: Workspace → Scripts → Utility → mark2markers
* Select your .mark file
* Your mark points should now be listed in DaVinci Resolve

Notes:
* The script will set the start of the timing mark 15 seconds prior to the button press, this is to account for delayed reaction of pressing the button
* The timing markers will be a duration of 15 seconds long, this is so that when you have all your marks set you can convert all markers to individual clips in one go. You would of course adjust the length of each marker to match what you want first.
* You can change either of these settings in the file
  ````
  -- Marker settings
  START_OFFSET_SECONDS = 15
  MARKER_DURATION_SECONDS = 15
  ````
