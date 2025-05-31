from PIL import Image
import os

path = "C:/Users/QoZnoS/Desktop/S2FM/libs/textures/2048px"

with Image.open(os.path.join(path, "Captureship_shape.png")) as img2:
    img = Image.open(os.path.join(path, "assets.png"))
    img.paste(img2, [1292,227])
    img.save(os.path.join(path, "test.png"))
