# Feature Spec: Online Hangouts & Social Sharing 🏖️☕

## Overview
Connects friends across the web in lightweight multiplayer gathering spots (The Zoo, The Café, The Beach) and drives viral growth through seamless sharing on Instagram, Threads, and Facebook.

## 1. Virtual Gathering Places
- **The Café**: A soothing lo-fi room with rain sounds where users' friends sit at wooden tables, study together, and high-five.
- **The Beach**: A bright coastal playground where friends chase crabs, build sand burrows, and swim.
- **The Zoo**: A vibrant sanctuary where users can walk around together, inspect rare evolutionary variants, and play tag.

## 2. Technical Architecture
- Lightweight WebRTC / WebSocket room server (e.g. Node.js or Dart server).
- Client sends minimal telemetry: `Offset position`, `LifeStage`, `MascotPalette`, `ActiveEmote`.
- Non-intrusive: stays in background or can be opened as an interactive tab/window.

## 3. Social Media Sharing
- **1-Click Polaroid Snapshot**: Generates an aesthetic Polaroid card featuring:
  - Companion avatar with current accessories.
  - Life stage & days alive counter.
  - Favorite quote or funny thought.
- **Direct Export Formats**:
  - Instagram Story (1080x1920 with transparent or aesthetic pastel background).
  - Threads / Facebook image card with hashtag `#AndFriend`.
