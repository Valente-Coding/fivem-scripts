VEHICLE IMAGES FOLDER
=====================

This folder should contain vehicle images in JPG format.

NAMING CONVENTION:
- File name must match the vehicle model name from config.lua
- Format: {model}.jpg
- Example: If config has model = "rhapsody", image should be "rhapsody.jpg"

RECOMMENDED SPECIFICATIONS:
- Format: JPG
- Aspect Ratio: 16:9 or 4:3 (landscape)
- Resolution: 800x450px or similar
- File Size: < 200KB each (compressed for performance)

EXAMPLES:
- rhapsody.jpg
- prairie.jpg
- brioso2.jpg
- panto.jpg
- weevil.jpg
- blista.jpg
- dilettante.jpg
- issi2.jpg
- club.jpg
- brioso.jpg
- issi3.jpg
- kanjo.jpg

ERROR HANDLING:
- If an image is missing, the UI will show "No Image Available" placeholder
- The UI will not break if images are missing

NOTES:
- Images are displayed at 220px height in the UI
- Use object-fit: cover so any aspect ratio works
- Smaller file sizes improve UI load times
