# Active Context: RobinRunner

## Current Work Focus
Prepared `v0.1.0` release archives (`export/RobinRunner-v0.1.0-Linux.zip`, `export/RobinRunner-v0.1.0-Windows.zip`) and isolated all WebGL2 performance optimizations strictly behind `OS.has_feature("web")` so Desktop builds keep full visual quality.

## Recent Changes
- **Web-only optimization isolation**: Gated chunk decor caching, biome/scenery shadow disabling, reduced prop counts, 2-octave sky clouds (`stylized_sky.gdshader` `low_quality`), and simplified trail shader (`forest_trail.gdshader` `low_quality`) strictly behind `OS.has_feature("web")`; Desktop retains full quality.
- **GitHub Pages (`gh-pages`)**: Created orphan `gh-pages` branch with the HTML5 export (`index.html`, `.nojekyll`, `.wasm`, `.pck`, `.js`, icons) and added the live Web test link to `README.md`.
- **Release `v0.1.0`**: Packaged Linux and Windows desktop exports into `export/RobinRunner-v0.1.0-*.zip` and tagged `v0.1.0` on `main`.

## Next Steps
1. Push `main`, `gh-pages`, and tag `v0.1.0` when requested (`git push --all && git push --tags`).
2. User publishes Release `v0.1.0` on GitHub by uploading the two `.zip` archives from `export/`.
