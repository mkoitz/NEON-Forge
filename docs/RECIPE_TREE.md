# Recipe Tree

## Purpose

This document captures the exact starter set and the early tier structure for NEON Forge.

It is important because the game is not just a loose bag of recipes. The combinations should form a readable progression tree where each discovery leads naturally into the next layer of the simulation.

## Starter Elements

The prototype starts with these 10 elements:

- Energy
- Signal
- Code
- Noise
- Light
- Time
- Data
- Circuit
- User
- Void

These are the root nodes of the discovery tree.

## Tier 1: Core System

This is the foundation layer. These recipes should teach the player how the world thinks.

- `Energy + Code -> Program`
- `Code + Noise -> Error`
- `Signal + Noise -> Static`
- `Data + Code -> Database`
- `Circuit + Energy -> System`
- `Light + Signal -> Display`
- `Time + Data -> Log`
- `Void + Energy -> Pulse`
- `User + Code -> Input`
- `Signal + Data -> Packet`

### Tier 1 Outcomes

- Program
- Error
- Static
- Database
- System
- Display
- Log
- Pulse
- Input
- Packet

## Tier 2: Glitch And Instability

This is where the simulation starts to break, mutate, and develop personality.

- `Error + Code -> Glitch`
- `Glitch + Signal -> Corruption`
- `Static + Signal -> Interference`
- `Error + System -> Crash`
- `Pulse + Circuit -> Overload`
- `Glitch + Data -> Corrupted File`
- `Noise + Program -> Bug`
- `Bug + System -> Failure`
- `Log + Error -> Exception`
- `Packet + Noise -> Drop`

### Tier 2 Outcomes

- Glitch
- Corruption
- Interference
- Crash
- Overload
- Corrupted File
- Bug
- Failure
- Exception
- Drop

## Tier 3: Network Layer

This is where the world expands from one machine into connected systems.

- `System + Signal -> Network`
- `Network + Data -> Internet`
- `Packet + Network -> Transmission`
- `Database + Network -> Cloud`
- `User + Network -> Online`
- `Program + Network -> Service`
- `Bug + Network -> Exploit`
- `Exploit + System -> Hack`
- `Hack + Network -> Cyber Attack`
- `Cloud + Data -> Storage`

### Tier 3 Outcomes

- Network
- Internet
- Transmission
- Cloud
- Online
- Service
- Exploit
- Hack
- Cyber Attack
- Storage

## Tier 4: AI And Entities

This is where the system begins to feel alive and self-directed.

- `Program + Data -> Algorithm`
- `Algorithm + Data -> AI`
- `AI + Network -> Distributed AI`
- `AI + User -> Assistant`
- `AI + Bug -> Unstable AI`
- `Unstable AI + Network -> Rogue AI`
- `Rogue AI + System -> Takeover`
- `AI + Cloud -> Neural Net`
- `Neural Net + Data -> Learning`
- `Learning + AI -> Super AI`

### Tier 4 Outcomes

- Algorithm
- AI
- Distributed AI
- Assistant
- Unstable AI
- Rogue AI
- Takeover
- Neural Net
- Learning
- Super AI

## Tier 5: Viral / Weird / Shareable

This is the emotional and social payoff layer. These are the results players should want to screenshot and share.

- `AI + Love -> Digital Soul`
- `User + AI -> Influencer`
- `Influencer + Network -> Viral Content`
- `Viral Content + AI -> Algorithm Feed`
- `Algorithm Feed + User -> Addiction`
- `Addiction + Network -> Doomscroll`
- `Meme + AI -> Meme Generator`
- `Rogue AI + Love -> Obsession.exe`
- `Time + Glitch -> Paradox.exe`
- `Void + AI -> Singularity`

### Tier 5 Outcomes

- Digital Soul
- Influencer
- Viral Content
- Algorithm Feed
- Addiction
- Doomscroll
- Meme Generator
- Obsession.exe
- Paradox.exe
- Singularity

## Secret / Delight Recipes

These are important because they create surprise and help the tree feel deeper than the obvious path.

- `Noise + User -> Meme`
- `Meme + Network -> Trend`
- `Trend + AI -> Autopost Bot`
- `Void + Glitch -> Backdoor`
- `Backdoor + System -> Root Access`

### Secret Outcomes

- Meme
- Trend
- Autopost Bot
- Backdoor
- Root Access

## Support Recipe

The current prototype also includes one support recipe to make the Tier 5 branch reachable inside the game logic:

- `User + Pulse -> Love`

This is a bridge recipe so `Digital Soul` and `Obsession.exe` are actually unlockable from the current tree.

## Tree Shape

The intended shape of the progression is:

1. Start with abstract machine primitives
2. Learn the core logic of the simulation
3. Introduce errors and instability
4. Expand outward into connected systems
5. Create intelligence
6. Reach culturally weird, emotional, and transcendent outcomes

In short:

`Core System -> Glitch -> Network -> AI -> Viral / Weird`

## Design Rule

When adding future recipes, they should do one of three things:

- deepen an existing branch
- bridge one tier into the next
- create a high-value surprise payoff

If a recipe does none of those, it probably does not belong in the main progression tree.
