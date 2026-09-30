# Nine Lamps — visual direction (first pass)

## North star

A premium, atmospheric 2.5D runner about devotion across nine nights. The player is the devotee. The divine feminine is present through the world's response to worship, never as an on-screen figure. The same route transforms from near darkness to dawn as nine lamps are gathered.

The first concept image, `docs/visuals/nine-lamps-world-concept-v1.png`, shows the architectural richness and warm lamp language. It represents a **late-game destination**, not Night 1 and not a production-ready game background.

## Visual grammar

- **Readable runner:** Three lanes must remain obvious at phone size. Obstacles, safe ground, and lamp pickups take priority over ornament.
- **Light as progress:** Every acquired lamp adds a persistent layer of illumination to the environment. The world grows more legible, not merely brighter.
- **Felt presence:** Wind changes direction, fabric settles, petals drift, bells sound, and unlit lamps kindle at key moments. No goddess body, face, or silhouette appears.
- **Material depth:** Carved stone, fired clay, woven cloth, shallow water, brass, and smoke provide richness. Use layered parallax, controlled highlights, and grounded shadows to achieve depth with restrained effects.
- **Original sacred space:** Draw from Indian architectural and devotional vocabulary without reproducing Isha's Linga Bhairavi imagery, shrine design, logos, or a specific living temple.
- **Player identity:** The devotee is intentionally anonymous. Costume and animation should be expressive while leaving room for the player to project themselves into the role.

## Nine-night transformation

| Nights | Quality | Palette and place | Motion and challenge |
| --- | --- | --- | --- |
| 1–3 | Tamas | Indigo-black, charcoal stone, ember pinpoints; low visibility with a reliably readable path | Heavy air, slow dust, obscured but fairly telegraphed obstacles |
| 4–6 | Rajas | Vermilion, copper, gold; banners, firelight, more visible architecture | Faster rhythms, moving hazards, distracting rewards |
| 7–9 | Sattva | Moonlit ivory, pale gold, blue-grey; clear geometry and open sky | Precise timing and deceptive calm; Night 9 is the peak |
| Vijayadashami | Release | Dawn light spreads beyond the path | A quiet offering of nine lamps; the world is illuminated |

The gunas are conditions of the journey, not enemies to kill. Sattva is beautiful; the final tension is attachment to it.

## MVP asset set

1. One lane-ground tile set and a few modular stone/earth transitions.
2. Three parallax backdrop families, one per three-night arc, with progressive light variants.
3. One anonymous devotee character with run, lane-shift, jump, slide, stumble, and offering poses.
4. One clay lamp design with unlit, lit, collected, and shrine-placement states; nine lamps share a visual family with modest variation.
5. Three obstacle families, each visually tied to its arc and readable before contact.
6. Shrine threshold and Vijayadashami dawn scene.
7. Small, restrained effects: flame, dust, cloth, petals, and light bloom.
8. HUD: nine-lamp progress, distance/score, pause, and clear end-of-run panels.

## Production rule

Concept paintings set mood and material language. Runtime sprites need separately generated, consistent views and animation frames. Build a playable greybox first to establish camera angle, character scale, lane spacing, obstacle readability, and device performance; then create final sprites and backgrounds against those measurements. Verify every scene at actual phone size, especially Nights 1–3.
