# World Demo — Design Document

> A simplified xianxia cultivation RPG. Work in progress.

## Open Questions

Before diving deep, we need to nail these down:

1. **Perspective** — 2D 
2. **Engine** — Godot / Unity / Unreal / something else? I don't know, let's figure out after we have the design aligned
3. **Core pillars** — Which 2-3 mechanics are the heart of the game?
   - NPC generateion, image, character, ablilty, etc (basically we should have something like AI agent config for each npc)
   - NPC relationships/social
   - NPC chatting 
4. **Scope** — What does a playable prototype look like? Let's focus on simple NPC generation, their profile generation, and the able to chat, we can have a simple map and everyone in the same place of the map, like classroom in school
5. **Art style** — Pixel? Hand-drawn? 3D low-poly? Ink/brush? I want anime style first, but ideally we can make the style flexible, use the anime style as a start point
6. **Solo or team?** solo, idally in the end we can let user form team with NPC
7. **Target platform** — PC only? Mobile too? PC only

## Inspiration

- 鬼谷八荒 (Tale of Immortal) — core cultivation loop, open world
- What to keep, what to simplify, what to do differently? 
   - character generation first 
      - character gen, should use some random choice from a pool
      - image gen, should use some random prompt and the charcter generate in the previous step as a part of the prompt, call image gen LLM to gen
      - history or related management, (keep it simple first)
   - NPC relationships/social
      - have a Favorability, Affection level etc
      - have a contact history
      - have some random relationship between with other NPC like talk 
   - NPC chatting 
      - able to chat (should use API to call the LLM to chat)
      - context management, like the chat history, and the character info etc

---

*Fill in the answers and I'll flesh out each section.*
