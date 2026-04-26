# dnd3

An RPG sandbox project originally based on [Luanti](https://www.luanti.org/) (formerly Minetest).

## About

**dnd3** brings classic Dungeons & Dragons–style gameplay into a voxel sandbox world.  Players can create characters, choose races and classes, cast spells, and battle monsters — all within a fully moddable Luanti environment.

## Features

- **Character creation** — choose race, class, ability scores (STR / DEX / CON / INT / WIS / CHA)
- **Turn-influenced combat** — initiative rolls, attack rolls, saving throws
- **Magic system** — spell slots, cantrips, and a growing spell compendium
- **Core engine** — shared utilities, registries, and event hooks used by every mod

## Project structure

```
dnd3/
├── game.conf            # Luanti game metadata
├── LICENSE
├── README.md
├── menu/                # Main-menu graphics
└── mods/
    ├── dnd_core/        # Shared utilities, registries, events
    ├── dnd_characters/  # Character creation and stats
    ├── dnd_combat/      # Combat system
    └── dnd_magic/       # Spells and magic system
```

## Getting started

1. Install [Luanti](https://www.luanti.org/downloads/) (≥ 5.8.0).
2. Clone this repository into your Luanti `games/` folder:
   ```bash
   git clone https://github.com/UnderhillForge/dnd3.git ~/.luanti/games/dnd3
   ```
3. Launch Luanti, create a new world, and select **dnd3** as the game.

## Contributing

Pull requests are welcome!  Please open an issue first to discuss major changes.

## License

MIT — see [LICENSE](LICENSE) for details.
