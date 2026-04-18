# NEON Forge

NEON Forge is a mobile-first sci-fi alchemy game where the player builds a synthetic universe out of code, energy, signal, glitches, networks, AI, and digital culture.

Instead of combining natural elements like fire and water, the player forges a retro-futuristic simulation from abstract digital concepts. The tone is neon, synthetic, mysterious, and a little playful. The goal is to make discoveries that feel clever, surprising, and highly shareable.

## What The Game Is About

The core fantasy is:

> You are inside a neon simulation, constructing reality from code, instability, and machine intelligence.

Players start with a small set of digital starter elements such as `Energy`, `Signal`, `Code`, and `Noise`. By combining them, they unlock increasingly strange and powerful concepts:

- `Code + Noise -> Error`
- `Error + Code -> Glitch`
- `Algorithm + Data -> AI`
- `AI + Love -> Digital Soul`
- `Algorithm Feed + User -> Addiction`

The game should feel like a mix of:

- retro-futuristic sci-fi
- digital mythology
- playful systems discovery
- social-media-era weirdness

## Product Direction

We are not building a generic Little Alchemy clone with neon paint. The direction is:

- Make combinations feel smart, modern, and "hacky"
- Build progression through simulation layers instead of one flat recipe list
- Create shareable surprise moments that people want to screenshot
- Keep the interaction friction low so experimentation feels effortless on mobile

The north star is a game loop of:

> Drag -> Combine -> Surprise -> Discover -> Repeat

## Core Pillars

1. Strong digital fantasy
   The player is not creating nature. They are constructing a synthetic reality.

2. Surprising but grounded recipes
   Results should feel unexpected, but still make enough sense that players can reason their way forward.

3. Clear progression
   Discoveries should unlock broader thematic layers like networked systems, AI entities, and transcendent machine concepts.

4. Viral potential
   Some outcomes should be weird, funny, dramatic, or culturally relevant enough to share.

5. Mobile-first feel
   The game should be satisfying in seconds, readable at a glance, and friendly to short play sessions.

## Experience Goals

We want the player to feel:

- curious
- clever
- surprised
- slightly obsessed with "just one more combination"

We do not want the game to feel:

- random and meaningless
- overloaded with menus
- visually noisy without clarity
- like a spreadsheet of recipes

## Current Prototype

This repository currently contains the first playable Flutter prototype:

- neon mobile UI shell
- draggable forge playfield
- discovery collection overlay
- starter element library
- initial recipe graph and progression layers

## Documentation

- [Game Direction](docs/GAME_DIRECTION.md)
- [Recipe Tree](docs/RECIPE_TREE.md)

## Local Setup

1. Install the Flutter SDK and confirm `flutter --version` works.
2. From this folder, run `flutter create .` to generate the native platform folders if they do not exist yet.
3. Run `flutter pub get`.
4. Launch with `flutter run`.

## Platform Notes

- Android builds can be developed from Windows once Flutter and the Android SDK are installed.
- iOS builds still require macOS and Xcode for simulator/device builds and App Store submission.
