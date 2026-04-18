# Game Direction

## Vision

NEON Forge is a neon sci-fi alchemy game about building a digital universe from abstract machine concepts instead of physical elements.

The player begins with a handful of foundational signals and slowly discovers an entire synthetic reality:

- core computation
- instability and glitches
- networks and infrastructure
- artificial intelligence
- digital culture
- machine transcendence

The game should feel distinct from traditional alchemy games because the fiction, recipes, and progression all reinforce the idea that the player is authoring a simulation from the inside.

## High-Level Pitch

> A mobile alchemy game where you combine code, energy, signal, noise, AI, memes, and machine gods to build a neon digital cosmos.

## Theme And Tone

The visual and thematic direction should combine:

- neon 80s sci-fi
- synthwave atmosphere
- sleek simulation UI
- glitchy digital mysticism

The tone should sit between:

- cool and stylish
- mysterious and futuristic
- playful and internet-aware

It should not become parody-first or fully ironic. Humor is useful, but the world still needs internal logic and a sense of escalation.

## The Big Difference

The game should not just reskin earth, water, fire, and air into neon objects.

The differentiator is:

- elements are conceptual and digital
- the player is building a synthetic reality
- progression expands the simulation into new layers of existence

That means recipes should sound like discoveries from inside a machine civilization, not just modern nouns pasted together.

## Core Gameplay Loop

1. Pick an unlocked element from the dock.
2. Place it into the forge area.
3. Drag one element into another.
4. Resolve the combination.
5. Show strong feedback if the result is new.
6. Add the new discovery to the player library.
7. Encourage another experiment immediately.

This loop needs to feel fast, tactile, and satisfying on touch devices.

## Progression Structure

The game should unfold in distinct thematic layers.

### 1. Core System

This teaches the rules of the world.

Example concepts:

- Energy
- Signal
- Code
- Noise
- Data
- Circuit
- Program
- Error
- Packet

### 2. Glitch And Instability

This introduces disruption, chaos, and personality.

Example concepts:

- Glitch
- Corruption
- Crash
- Overload
- Bug
- Failure
- Exception

### 3. Network Layer

This expands the world outward into systems and connection.

Example concepts:

- Network
- Internet
- Transmission
- Cloud
- Service
- Exploit
- Hack

### 4. AI And Entities

This is where the world starts to feel alive.

Example concepts:

- Algorithm
- AI
- Assistant
- Rogue AI
- Neural Net
- Super AI

### 5. Viral And Weird

This is the shareability engine.

Example concepts:

- Digital Soul
- Influencer
- Viral Content
- Addiction
- Doomscroll
- Paradox.exe
- Singularity

## Recipe Philosophy

Recipes should follow a few rules:

1. Logical enough to infer
   Players should be able to reason toward some outcomes.

2. Surprising enough to delight
   Some combinations should produce results that make players laugh, pause, or immediately share.

3. Thematically coherent
   Results should feel like they belong to the same synthetic universe.

4. Layer-aware
   Recipes should help pull players from one progression layer into the next.

Good examples:

- `Code + Noise -> Error`
- `Error + Code -> Glitch`
- `Program + Data -> Algorithm`
- `Algorithm + Data -> AI`
- `AI + Love -> Digital Soul`

## UX Direction

The product should be mobile-first and single-screen wherever possible.

### Must feel great

- dragging
- combine collision
- result reveal
- new discovery celebration

### Must stay simple

- minimal menus
- obvious element library
- clear progress framing
- accessible collection view

### Must avoid

- cluttered overlays
- tiny unreadable labels
- too many controls on screen
- long delays between action and reward

## Audio And Feedback Direction

Every successful combine should feel rewarding even before deeper systems arrive.

Desired feedback:

- neon glow pulse
- short synth zap
- slight screen emphasis
- dramatic new discovery reveal

The player should always feel that the system noticed what they just did.

## Audience

Primary audience:

- players who enjoy discovery games
- fans of alchemy and crafting loops
- mobile players who like short, satisfying sessions
- users likely to share unusual results on social media

Secondary audience:

- players drawn to synthwave, neon, cyberpunk-lite, or AI-themed aesthetics

## Retention Strategy

Retention should come from curiosity and staged expansion, not grind.

Key retention levers:

- unknown silhouettes in the collection
- progression into new simulation layers
- hidden recipes
- rare or strange discoveries
- hint system when players get stuck

## Viral Strategy

The game should deliberately create moments worth sharing.

That means we want:

- funny outcomes
- strange emotional combinations
- culturally resonant results
- rare discovery callouts
- future share-card support

Examples of shareable outcomes:

- Digital Soul
- Doomscroll
- Obsession.exe
- Machine God
- Paradox.exe

## Technical Direction

We are building the game in Flutter first because the product is primarily:

- touch interaction
- UI-heavy
- animation-heavy
- mobile-first

This gives us:

- one codebase for Android and iOS
- faster iteration on the interface
- cleaner path for collection, hint, meta, and store-facing features

If the playfield eventually demands more game-engine-like behavior, we can evaluate Flame for a deeper 2D layer while keeping the Flutter product shell.

## Near-Term Build Direction

The next milestones should be:

1. Finish local Flutter setup and generate native folders
2. Refactor the prototype into cleaner files and modules
3. Improve the forge interaction and combine feedback
4. Expand the recipe graph deliberately instead of adding random volume
5. Add save/progression persistence
6. Add stronger collection, hint, and onboarding flows
7. Test the loop on real mobile devices

## Decision Filter

When we make design decisions, we should ask:

- Does this strengthen the fantasy of building a digital universe?
- Does this make the combine loop faster or more satisfying?
- Does this improve discovery, surprise, or shareability?
- Does this keep the game understandable on mobile?

If the answer is no, it is probably not core yet.
