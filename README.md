# 🎮 PongFPGA: Hardware Pong Implemented in VHDL

A complete implementation of the classic Pong game written entirely in **VHDL** and executed on an FPGA.

The project generates VGA video signals directly in hardware, renders all game graphics procedurally, handles real-time player input through FPGA switches, and implements game mechanics including paddle movement, ball physics, collision detection, scoring, and game-state management.

No software, operating system, frame buffer, or processor is required—the entire game runs as digital logic on the FPGA.

---

## 🎥 Demo

[Watch Demo Video](assets/demo.mp4)

---

## 📌 Project Overview

This project recreates the classic Pong arcade game using pure hardware design principles.

Features include:

* Real-time VGA graphics generation
* Two-player gameplay
* Paddle control using FPGA switches
* Ball collision physics
* Goal detection
* Win-state handling
* Finite State Machine game control
* Hardware-based timing and synchronization

---

## 🏗️ System Architecture

```text
50 MHz FPGA Clock
        │
        ▼
 Clock Divider
        │
        ▼
 25 MHz Pixel Clock
        │
 ┌──────┴──────┐
 ▼             ▼
VGA Timing   Game Engine
Generator
                 │
                 ▼
          Collision Logic
                 │
                 ▼
           Pixel Renderer
                 │
                 ▼
             VGA Output
```

---

## 🖥️ VGA Video System

The game generates a standard VGA signal entirely in hardware.

### Display Specifications

| Parameter    | Value     |
| ------------ | --------- |
| Resolution   | 640 × 480 |
| Refresh Rate | 60 Hz     |
| Pixel Clock  | 25 MHz    |
| Input Clock  | 50 MHz    |

The VGA controller generates:

* Horizontal Sync (HSYNC)
* Vertical Sync (VSYNC)
* RGB Video Output

---

## 🎮 Gameplay

Two players control paddles positioned on opposite sides of the screen.

### Controls

| Switch | Function      |
| ------ | ------------- |
| SW0    | Player 1 Down |
| SW1    | Player 1 Up   |
| SW2    | Player 2 Down |
| SW3    | Player 2 Up   |

---

## ⚽ Game Mechanics

### Paddle Movement

* Paddle positions update in real time.
* Movement is constrained within arena boundaries.
* Each paddle is rendered directly through coordinate comparisons.

### Ball Movement

The ball:

* Moves diagonally across the field.
* Updates position at a fixed hardware-controlled rate.
* Bounces off walls.
* Bounces off paddles.
* Changes direction after collisions.

### Goal Detection

Goals are positioned on the left and right sides of the arena.

When the ball enters a goal:

* A winner is determined.
* The game enters a "Lost" state.
* The winning player's color is displayed.
* The game automatically resets after a delay.

---

## 🔄 Finite State Machine

The game operates using three states:

### Reset State

* Initializes game objects
* Randomizes serve direction
* Centers paddles and ball

### Play State

* Processes player input
* Updates ball movement
* Detects collisions
* Checks scoring conditions

### Lost State

* Displays winner
* Continues ball movement briefly
* Waits before resetting

```text
Reset
  │
  ▼
Play
  │
  ▼
Lost
  │
  ▼
Reset
```

---

## 🎨 Graphics Rendering

All graphics are generated procedurally.

### Arena

* Green background
* White outer boundaries
* Goal openings
* Dashed center line

### Players

* Player 1: Red Paddle
* Player 2: Blue Paddle

### Ball

* White during gameplay
* Red when Player 1 wins
* Blue when Player 2 wins

No image assets or frame buffers are used.

---

## ⚙️ Hardware Timing

The game engine updates independently of the VGA refresh logic.

### Mechanics Update Rate

```text
25 MHz / 390625 ≈ 64 updates per second
```

This provides smooth gameplay while maintaining stable video output.

---

## 🧠 Digital Design Concepts Demonstrated

* VGA Timing Generation
* Clock Division
* Finite State Machines (FSMs)
* Collision Detection
* Hardware Rendering
* Synchronous Design
* Real-Time Input Processing
* FPGA-Based Game Development

---

## 🛠️ Technologies Used

* VHDL
* FPGA Development Tools
* VGA Interface
* Digital Logic Design
* Finite State Machines

---

## 🚀 Future Improvements

Potential extensions include:

* Score tracking
* Seven-segment display integration
* AI opponent
* Variable ball speeds
* Sound generation
* Power-ups
* Multiple game modes

---

## 📎 Author

**Mustansir Verdawala**