# Tombstone identity

The project owner supplied **Black Tombstone with Transparent X.png** on 2026-10-15 and requested that it replace the earlier waveform identity everywhere, including website favicons and the app icon. This intentional branding difference takes precedence over copying the reference site's icon.

The built-in imagegen tool recolored the supplied mark and made the app tile. Palette targets are forest green `#034F46` and lavender `#F0D7FF`, alongside the site's cream `#FFFFEB`. No Wispr brand mark is used. The existing independent-project disclaimer remains.

| Master | Uses |
|---|---|
| [Tombstone-512.png](../assets/Tombstone-512.png) | Website headers/footer, account/demo identity, macOS menu-bar template |
| [AppIcon-1024.png](../assets/AppIcon-1024.png) | Dock icon source, native sidebar/welcome, site icon, favicon, Apple touch icon |

Both masters retain alpha. The standalone mark's X is transparent; on the app tile the opening shows lavender. macOS renders the menu-bar template in the system's light/dark color so it remains legible. Animated sound bars still represent live recording or demos, not project identity.

Run `bash scripts/build-icons.sh` on macOS after replacing a master. It copies native/site assets and packages 64px favicon and 180px touch-icon versions with `sips`. `scripts/run-dev.sh` calls this before building and uses the existing ten-size iconset conversion for `AppIcon.icns`.

## Final generation prompts

Built-in imagegen edit, using the user-supplied PNG as the edit target:

> Change only the solid fill of the tombstone from black to deep forest green #034F46. Preserve the original tombstone silhouette, proportions, rounded arch, base, and X-shaped transparent cutout. Keep outside the tombstone and the X hole transparent. Flat solid color, crisp antialiased edges; no shadows, texture, text, lettering, border, added objects or redesign. Square output, centered, preserving the input framing.

Built-in imagegen app-icon variant, using the same supplied PNG:

> Preserve the tombstone shape and X opening. Center the tombstone in deep forest green #034F46 on a soft lavender #F0D7FF rounded-square tile. The X hole shows the tile through it. The tile occupies about 82 percent of the square canvas, with a generous macOS-style corner radius. Tombstone occupies about 70 percent of tile height with balanced padding. Outside the tile is transparent. Crisp flat colors; no gradients, shadows, texture, 3D, glow, text, letters or additional symbols.

The selected outputs were visually inspected, then resized for packaging with `sips`. Browser rendering and Dock/menu-bar appearance still require visual checks. The supplied image remains untouched in the owner's Downloads folder.
