# VR Environment - Geometric Shapes

## Table of Contents

1. [About the Project](#1-about-the-project)
2. [Key Features](#2-key-features)
3. [Scene Structure](#3-scene-structure)
4. [Installation and Execution](#4-installation-and-execution)

---

## 1. About the Project

This project is an immersive demo environment developed in the **Godot Engine** focusing on the programmatic creation of 3D geometries (`MeshInstance3D`) and the implementation of a basic cinematic camera system.

The primary goal is to build a detailed indoor room scene (walls, furniture, lighting, artwork) entirely from GDScript code, avoiding complex scene files (`.tscn`) or imported models. It serves as a foundation for future development in interaction, advanced lighting, or Virtual Reality (VR) environments.

**Technology Used:**
* **Engine:** Godot Engine 4.x
* **Language:** GDScript

## 2. Key Features

* **Programmatic Generation:** All scene geometry (walls, ceiling, floor, table, chairs) is dynamically constructed using built-in `BoxMesh`, `CylinderMesh`, and other base mesh types.
* **Cinematic Camera:** Implementation of a camera controller that orbits around the scene's center, providing a smooth, 360-degree view of the room.
* **Adaptive Artwork System:** An artwork component that loads an external texture image and automatically adjusts the canvas and frame dimensions to maintain the image's original aspect ratio.
* **Entity Logic (Ghost):** A simple entity that moves cyclically between predefined points in the room and constantly rotates to look towards the scene's center (the camera).
* **Multiple Lighting:** Use of directional lights (`DirectionalLight3D`), omni lights (`OmniLight3D`), and spotlights (`SpotLight3D`) to create a realistic and contrasting atmosphere.

## 3. Scene Structure

The main scene is entirely constructed within the `Main.gd` script via the `_build_room()` function. The main elements generated include:

* **`Room` (Container):** Contains all static architectural and furniture meshes.
* **Architecture:** Floor, wall, and ceiling meshes with defined materials.
* **Furniture:** Composite objects such as the central Table and Chairs.
* **Lighting:** Ceiling lamp, floor lamp, and primary sun direction light.
* **Artwork:** A framed picture whose size is defined by the `FRAME_DIMENSIONS` constant.

## 4. Installation and Execution

To run this project, you need to have Godot Engine version 4.x installed.

### Requirements

* Godot Engine 4.x ([Download Here](https://godotengine.org/download/))

### Execution Steps

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/RaquelBascones/VR-environment.git](https://github.com/RaquelBascones/VR-environment.git)
    ```
2.  **Open in Godot:** Open the Godot Engine and select the "Import" option. Navigate to the cloned folder and open it.
3.  **Artwork Image Setup:** Ensure your custom image is located at the path: `res://images/super nenas.jpg`. If the path is different, edit the `ART_IMAGE_PATH` constant inside `Main.gd`.
4.  **Run:** Click the **Play** button (F5) to start the scene.
