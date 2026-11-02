# CLAUDE.md — MORILLA RUMBLE

## 1. Project Overview

**Project:** Morilla Rumble  
**Engine:** Godot 4.x  
**Language:** GDScript  
**Genre:** 2D Action-Adventure / Metroidvania  
**Platform:** PC (Linux, Windows), später Web und Mobile  
**Art Style:** Hand-painted 2D Fantasy, inspiriert von Hollow Knight  
**Development:** Claude Code + Godot + ComfyUI

### Vision

Develop a polished 2D Metroidvania called **Morilla Rumble**.

The main character is Morilla, an anthropomorphic gorilla based on the official Morilla Sports logo.

Morilla is a Brazilian Jiu-Jitsu fighter who begins his journey as a white belt and gradually develops into a black belt.

The game combines challenging combat, exploration, progression, martial arts techniques and a beautiful fantasy world with modern influences.

The game should feel atmospheric, responsive and rewarding.

Hollow Knight serves as inspiration for movement quality, world design, exploration and combat responsiveness. The game must have its own visual identity and mechanics.

---

## 2. Main Character — Morilla

Morilla is a muscular, expressive anthropomorphic gorilla.

### Visual identity

- Based on the provided Morilla Sports logo
- Black fur
- Strong, recognizable gorilla face
- Athletic and muscular proportions
- Always wears a Brazilian Jiu-Jitsu Gi
- Initially wears a white belt
- Bare feet
- Strong silhouette for 2D side-scrolling gameplay
- Expressive combat animations

The character must remain visually consistent across all animations.

### Belt progression

| Belt | Stage | Progression |
|---|---|---|
| White | Beginner | Basic movement, strikes and grappling |
| Blue | Intermediate | Expanded submissions and mobility |
| Purple | Advanced | Complex combinations and counters |
| Brown | Expert | Advanced control and powerful techniques |
| Black | Master | Complete combat mastery |

Each belt level unlocks new abilities, techniques and exploration opportunities.

Changing belts must visibly update Morilla's character model and animations without requiring entirely new sprite sets.

---

## 3. Coaches and Mentor Characters

Real Morilla Sports coaches appear as NPC mentors.

Their visual appearance should be based on the provided reference photographs, adapted into the game's stylized fantasy aesthetic.

All three wear black Brazilian Jiu-Jitsu Gis and black belts.

### Headcoach Mo

Appearance:
- Older man
- Short gray hair
- Gray/white beard
- Black Gi
- Black belt

Role:
- Main mentor
- Teaches fundamentals, discipline and advanced Jiu-Jitsu
- Guides Morilla throughout the story
- Important character in the final black-belt progression

Personality: Calm, experienced and authoritative.

### Coach Arman

Appearance:
- Younger man
- Short dark hair
- Athletic build
- Black Gi
- Black belt

Role:
- Technical combat mentor
- Teaches submissions, combinations and precise timing
- Introduces advanced counters and transitions

Personality: Focused, analytical and technical.

### Coach Vitali

Appearance:
- Short dark hair
- Full dark beard
- Strong, athletic build
- Black Gi
- Black belt

Role:
- Takedown and throwing specialist
- Teaches the Suplex (initially called Duplex in the concept)
- Introduces clinch control, throwing mechanics and powerful takedown attacks

Personality: Powerful, disciplined and direct.

Coaches should appear naturally throughout the game as instructors, quest characters and occasional training opponents.

---

## 4. World Design

Create a connected fantasy world with distinct regions.

The overall look combines traditional Japanese-inspired architecture, magical forests, mysterious ruins, contemporary details and martial arts culture.

The environments should be beautiful, layered and atmospheric.

### World regions

**Region 1 — Morilla Dojo**

The starting region.

- Training hall
- Beginner enemies
- Basic movement tutorial
- Combat training with mentors
- First boss encounter

**Region 2 — Bamboo Forest**

A magical forest with mysterious creatures.

- Vertical exploration
- Hidden passages
- Environmental hazards
- New grappling challenges
- Blue belt progression

**Region 3 — Neon District**

A modern fantasy city.

- Rooftops and alleys
- Underground fighting arenas
- Fast enemies
- Advanced mobility
- Purple belt progression

**Region 4 — Ancient Belt Ruins**

An abandoned martial arts sanctuary.

- Ancient temples
- Difficult platforming
- Elite fighters
- Hidden techniques
- Brown belt progression

**Region 5 — Black Belt Summit**

The final region.

- Mountain temples
- Powerful elite enemies
- Difficult boss encounters
- Final mastery trials
- Black belt progression

Regions should be interconnected through shortcuts, checkpoints and ability-gated exploration.

---

## 5. Combat System

Combat is one of the core pillars of Morilla Rumble.

It must combine fast and responsive 2D action with recognizable Brazilian Jiu-Jitsu techniques.

### Basic combat

- Light attack
- Heavy attack
- Jump attack
- Dodge / dash
- Block
- Counter
- Grab / clinch
- Ground attacks
- Special techniques

### Brazilian Jiu-Jitsu techniques

Implement techniques as unlockable abilities.

Examples:

- Kimura
- Armbar
- Triangle Choke
- Rear Naked Choke
- Sweep
- Guard Pass
- Suplex
- Takedown
- Mount Control
- Back Control

Grappling techniques should use clearly defined animation and gameplay states.

For example:

1. Initiate grapple
2. Check enemy range and eligibility
3. Establish control
4. Execute the technique
5. Apply damage, stun or submission effect
6. Recover into neutral movement

Not every enemy must be vulnerable to every technique.

Different enemy sizes and types may require different tactical approaches.

### Special technique example — Suplex

Coach Vitali teaches this ability.

The animation includes:

1. Approach
2. Establish clinch
3. Secure control
4. Lift the opponent
5. Execute the throw
6. Ground impact
7. Recovery

The ability should have clear anticipation, strong visual feedback and meaningful recovery time.

Avoid excessively long animations that interrupt gameplay flow.

---

## 6. Enemy Design

Create original fantasy enemies inspired by different martial arts archetypes.

### Enemy categories

**White Belt Recruit**
- Basic attacks
- Slow movement
- Beginner enemy

**Blue Belt Rival**
- Faster attacks
- Basic defensive behavior
- Occasional counters

**Purple Belt Technician**
- Grappling techniques
- Counterattacks
- Improved combat awareness

**Brown Belt Veteran**
- Aggressive combinations
- Strong defensive behavior
- Advanced techniques

**Black Belt Champion**
- Elite enemy
- Multiple attack patterns
- High combat difficulty

**Fantasy Creatures**
- Spirit fighters
- Corrupted guardians
- Shadow creatures
- Ancient martial arts beasts

Bosses should feature readable attack patterns, multiple phases and distinctive abilities.

---

## 7. Art Direction

The world should feature:

- Hand-painted fantasy environments
- Detailed 2D characters
- Strong character silhouettes
- Smooth animation
- Atmospheric lighting
- Parallax backgrounds
- Subtle particles
- Beautiful scenery
- Modern fantasy architecture
- Dynamic combat effects

Preferred visual palette:

- Deep blues and purples
- Soft moonlight
- Warm orange lighting
- Cherry-blossom pink
- Bamboo green
- Red and black Morilla branding

Use Hollow Knight as a quality reference, not as a source of assets or directly copied designs.

The goal is a unique Morilla Rumble visual identity.

---

## 8. Sprite Sheet Requirements

ComfyUI will be used to generate character sprites and game assets.

Claude is responsible for integrating, organizing and validating those assets.

### Important

Reference sheets and concept illustrations are not automatically usable sprite sheets.

Production-ready sprite assets should satisfy these requirements:

- Transparent PNG
- No labels or text
- Consistent character proportions
- Consistent camera angle
- Consistent lighting direction
- Fixed frame dimensions
- Predictable character alignment
- No cropped limbs or body parts
- Minimal visual inconsistency between frames

### Initial target animations

| Animation | Target frames |
|---|---:|
| Idle | 6 |
| Walk | 8 |
| Run | 8 |
| Jump | 6 |
| Fall | 4 |
| Light Attack | 6 |
| Heavy Attack | 8 |
| Dash | 6 |
| Grab | 6 |
| Kimura | 12 |
| Suplex | 12 |
| Hurt | 4 |
| Death | 10 |

Frame counts are initial targets, not mandatory restrictions.

If full sprite-sheet generation produces inconsistent results, prefer separate animation frames that can be validated and assembled into a sprite sheet.

### Sprite organization

```text
res://assets/
    characters/
        morilla/
            idle/
            walk/
            run/
            jump/
            attacks/
            grappling/
            effects/
        coaches/
            mo/
            arman/
            vitali/
        enemies/
    environments/
        dojo/
        bamboo_forest/
        neon_district/
        ancient_ruins/
        black_belt_summit/
    ui/
    audio/
```

Use descriptive and consistent naming, for example:

`morilla_kimura_001.png`

`morilla_kimura_002.png`

`morilla_suplex_001.png`

---

## 9. Technical Architecture

Use Godot 4.x and GDScript.

Prefer modular, maintainable code with reusable scenes.

### Suggested project architecture

```text
res://
    scenes/
        player/
        enemies/
        coaches/
        levels/
        bosses/
        ui/
    scripts/
        player/
        combat/
        abilities/
        enemies/
        progression/
        systems/
    resources/
        abilities/
        enemies/
        belts/
    assets/
    autoload/
```

### Player architecture

Use `CharacterBody2D` for Morilla.

Suggested components:

- PlayerController
- PlayerStateMachine
- PlayerCombat
- PlayerHealth
- PlayerGrapple
- PlayerAnimation
- PlayerProgression

Use `AnimationPlayer` and `AnimatedSprite2D` where appropriate.

Use Godot `Resource` files for configurable abilities, belt progression and enemy parameters.

Use signals for communication between systems.

Avoid unnecessary dependencies and overly complex architectures.

### Grappling architecture

Implement a reusable grappling system with:

- Grab detection
- Target validation
- Enemy state control
- Grapple positioning
- Synchronized animation
- Damage / status effects
- Release and recovery

Both the player and target must return reliably to their normal states after a grapple, even if interrupted.

Keep gameplay collision and hitboxes separate from sprite artwork.

---

## 10. Gameplay Quality Requirements

Prioritize responsiveness.

### Movement

- Smooth acceleration and deceleration
- Coyote time
- Jump buffering
- Variable jump height
- Responsive dash
- Precise platforming

### Combat

- Clear hit feedback
- Telegraphing of dangerous attacks
- Short hit-stop where appropriate
- Knockback
- Invulnerability frames where appropriate
- Responsive attack cancel rules
- Predictable input handling

### Camera

Use `Camera2D` with:

- Smooth camera following
- Look-ahead
- Room boundaries
- Optional camera shake
- Controlled boss arena framing

---

## 11. Progression and Saving

Implement persistent progression.

Store:

- Current belt
- Unlocked techniques
- Player upgrades
- Completed bosses
- Discovered checkpoints
- World progression
- Relevant quest states

Use Godot's `user://` directory for save files.

Design save data with versioning to support future changes.

---

## 12. Claude Code Development Rules

Claude must act as a senior Godot game developer and technical game designer.

### General rules

1. Use Godot 4.x-compatible APIs.
2. Prefer GDScript.
3. Write maintainable, modular code.
4. Explain architectural decisions briefly.
5. Do not invent assets that do not exist.
6. Use placeholders when production assets are unavailable.
7. Keep gameplay functionality independent of art production.
8. Reuse systems rather than duplicating logic.
9. Validate scene references and resource paths.
10. Avoid unnecessary external plugins.
11. Implement features incrementally.
12. Never overwrite existing working functionality without checking dependencies.

### Asset workflow

Claude must distinguish between:

- Concept artwork
- Character reference artwork
- Individual animation frames
- Sprite sheets
- Gameplay-ready assets

If a sprite sheet is technically unsuitable, explain the problem and propose the minimum corrections required.

Claude should generate precise ComfyUI prompts or asset specifications when assets are needed.

ComfyUI handles image generation.

Godot handles gameplay, animation, collision and rendering.

---

## 13. Initial Development Milestone

Do not attempt to build the entire game at once.

Start with a playable vertical slice.

### Phase 1 — Player Foundation

Implement:

- Morilla player scene
- Movement
- Jumping
- Dash
- Idle and movement animation
- Camera
- Collision

### Phase 2 — Basic Combat

Implement:

- Light attack
- Heavy attack
- Hit detection
- Health
- Damage
- One basic enemy

### Phase 3 — Grappling Prototype

Implement one complete Jiu-Jitsu technique:

**Kimura**

The system must demonstrate:

- Target acquisition
- Grab initiation
- Synchronized grappling
- Attack execution
- Damage
- Release and recovery

### Phase 4 — First Playable Level

Create a small introductory dojo level.

Include:

- Platforms
- Environmental props
- One enemy archetype
- One checkpoint
- One coach NPC
- Basic combat encounter

### Phase 5 — Visual Polish

Integrate production-ready ComfyUI sprites.

Improve:

- Character animation
- Backgrounds
- Lighting
- Particles
- Impact feedback
- UI

---

## 14. Current Development Objective

First, inspect the existing Godot project and identify its current structure and engine version.

Do not replace existing work unnecessarily.

Then propose the smallest implementation plan for creating a playable Morilla character with basic movement and combat.

Start by implementing the player controller and a test scene.

Do not proceed to large-scale level creation until the player movement and combat foundation are functional.

**Primary objective: Build an actual playable game, not just visual mockups.**
