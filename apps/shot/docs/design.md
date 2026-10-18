# Common Shot: design

The spec a change to Shot's capture flow is checked against. Shot does one thing: a shot goes straight to the clipboard, sized for a prompt, with the text instead under ⌥. Every moment below should feel built into macOS, and better than macOS where macOS is weak. "Pure" means restraint: nothing here is a feature for its own sake, and a choice that adds a key, a setting or a pixel of chrome has to pay for it.

## The benchmark

| | Strong at | Weak at, for this job |
| --- | --- | --- |
| **macOS ⇧⌘4** | Zero chrome. The system crosshair, a size readout by the pointer, Space toggles window mode (camera cursor, the window tinted blue, shadow included, ⌥ to leave it out), Space during a drag moves the selection, ⇧ locks an axis, ⌥ resizes from the centre. The shutter sound follows "Play user interface sound effects". Retina shots keep their density, and the display's colour profile is embedded. | Nothing freezes, so a menu or hover state is gone by the time you aim. It saves a file by default (⌃ for the clipboard). No loupe. A window shot carries a wide margin of transparent shadow unless you hold ⌥. |
| **macOS ⇧⌘5** | A toolbar in system material, a selection that stays adjustable with handles, a timer, remembered settings. The floating thumbnail slides in from the right, swipes away, drags out, and opens Markup on a click. | Two steps to a shot. The file is written only when the thumbnail leaves, so a fast drag-out or paste waits for it. |
| **CleanShot X** | Freeze the screen, crosshair and magnifier, window shots with or without shadow and a backdrop, a Quick Access overlay with copy, save, annotate, pin and drag, OCR, scrolling capture, configurable sounds. | Breadth: dozens of options and an overlay of buttons, most of which a paste-into-a-prompt flow never needs. |
| **Shottr** | Speed and precision: a sharp pixel loupe, arrow keys by the pixel, a ruler, a colour picker, OCR. | Precision tooling shows all the time, and the look is its own rather than the system's. |
| **Xnapper** | Presentation: automatic padding, backgrounds and balance, auto-redaction. | Not a capture tool so much as a framing one; nothing about speed or the clipboard. |

Shot's edge over all of them is the job itself: frozen first, on the clipboard the moment you let go, sized and priced for a prompt, and text by holding a key. The design keeps that edge and borrows only what serves it.

## The moments

Each moment: what is world-class, what Shot does today, and the decision.

**1. Shortcut to overlay.** World-class is instant: the frame you pressed on is the frame you aim at, and the overlay is up before the hand has left the keys. Shot today fetches the shareable content, captures each display in turn, then builds a window per display. Decision: shareable content kept warm and refreshed when the displays change; every display captured at once; the overlay windows built ahead and reused, so showing them is setting a layer's contents. Measured and logged; the target is under 50 ms for one display.

**2. Idle crosshair.** The system crosshair, not a drawn one. The screen dims a little, which is how you know it is frozen. A loupe beside the pointer shows true device pixels on a faint grid with the centre pixel ringed; it never shows the colour value, which a prompt doesn't need. A quiet hint names the keys at the bottom of the pointer's display, in system material, and gets out of the way when the pointer comes near. No coordinate readout: macOS shows one, and it is noise here.

**3. Hovering windows.** Shot spotlights the window under the pointer (everything else dimmed) rather than tinting it as macOS does, because you see the window exactly as it will be copied. The outline is one device pixel in the accent colour. The pill shows the window's size in pixels, like a drag's. The window is captured in the background as soon as it is hovered, so a click copies at once. Shadow: off, because transparent margins cost tokens and look broken in a chat; hold ⇧ while clicking to keep it (⌥ is text).

**4. Starting a drag.** A press that moves more than 4 pt is a drag; less is a click on the window. The hint gives way to the pill at the selection's corner.

**5. Resizing and moving.** The selection follows the pointer. Hold Space to move it as a whole, as macOS does. The pill sits below the bottom-right corner, flips inside or above it near a screen edge, and never sits under the notch.

**6. Precision.** Arrow keys move the pointer by one device pixel, ⇧-arrows by ten, before or during a drag, and the loupe follows. Edges snap to window edges within 4 pt, which is how a crop lands exactly on a window's content; an arrow nudge is never snapped. No ⌥ from the centre (⌥ is text) and no ⇧ axis lock: arrows and snapping cover the cases those serve, with fewer keys to learn.

**7. Multiple displays and mixed scale.** Each display has its own overlay at its own scale. The selection is snapped to that display's device pixels, so what is outlined is exactly what is copied, on a 2× panel, a 1× monitor, or a scaled mode whose ratio isn't whole. Edges are one device pixel wide on each. A drag stays on the display it began on, as with macOS. The loupe and pill flip to stay on the pointer's display.

**8. Commit and feedback.** Letting go closes the overlay in the same frame, and a prompt-sized shot is on the clipboard within about 100 ms. The system's own screen-capture sound plays as a UI sound, so "Play user interface sound effects", the alert volume and the sound-effects device all apply, and Shot's own switch can turn it off. The picked area shrinks into the corner where the preview lands, a quarter of a second, and with Reduce Motion it simply appears. VoiceOver hears what was copied.

**9. The preview.** Like the system's thumbnail: it slides in from the screen's right edge, a two-finger swipe or a flick to the right sends it away, a drag drops the PNG as a file, and hover keeps it. Unlike the system's, the clipboard and the file are ready before it appears, so nothing waits for it to leave. A click dismisses it: opening an editor would serve saving, not pasting. It shows the size and the token cost, and says Ctrl+V when the shot came from a terminal. System material, so Reduce Transparency and Increase Contrast apply.

**10. History.** The menu shows the recent shots as thumbnails with their size and cost; a click copies one again. "Take Screenshot" shows the shortcut where macOS shows key equivalents, rather than a disabled line.

**11. Cancel.** Escape, a right-click, or the shortcut again: gone in the same frame, focus back to the app you were in, no sound.

**12. Errors and permission.** First use asks through macOS. After that, one alert explains and offers the way out. A window that closes before its capture falls back to its pixels in the frozen frame, which are what you saw, rather than an error.

**13. ⌥ text.** Holding ⌥ turns the accent orange and the pill to "Text", so the mode is visible before you commit. The same gestures read the text with Vision on the Mac.

## Rules that hold everywhere

- System controls, system cursor, system text styles, system materials, the user's accent colour. A Common UI token only where macOS has nothing.
- Reduce Motion: no slides, no flight; things appear. Reduce Transparency: materials go solid. Increase Contrast: stronger dimming and an outline on every floating piece.
- Every PNG is sRGB, converted deliberately. Prompts and most web pipelines read pixel values and ignore an embedded profile, so a display-profile PNG reads with shifted colours; sRGB is what they assume.
- Nothing drawn in the overlay is blurry: every layer renders at its display's scale.
- Logic (geometry, snapping, nudging, placement, scale) lives in ShotKit with tests. The overlay and the preview can be rendered offscreen in every state, light and dark, so a change is reviewed from pictures rather than by taking over a screen.

## Not doing

Annotation, Markup, a timer, scrolling capture, recording, pinning to the screen, cloud upload, backgrounds and padding, a colour picker, a ruler, a persistent selection with handles, a capture toolbar. Each is good in some tool; none moves a shot to a prompt faster.
