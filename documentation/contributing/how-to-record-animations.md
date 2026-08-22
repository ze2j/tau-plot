# How to record animations

1. Godot Settings:
 - Display > Window > Viewport: 600x400 for plots with custom minimum size set to 600x400 inside a CenterContainer. Otherwise the default 1920x1080 is fine.
 - Editor > Movie writer > Move File: <some/local/path>/render.png

2. Editor Top right corner: Enable Movie Writer Mode

3. Run the scene (F6)

4. Close the scene

5. From terminal, inside the folder containing renderXXXXXXXX.png images:
```
ffmpeg \
    -framerate 60 -i render%08d.png \
    -vf "fps=30,scale=638:-1:flags=lanczos" \
    -c:v libwebp_anim -lossless 0 -quality 95 -compression_level 6 \
    -loop 0 animation.webp
```
Which produces `animation.webp` at 30 fps, 638px wide with unchanged aspect ratio.
