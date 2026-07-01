# PosicionaAI

This repository contains the projects and challenges developed during the Computer Vision learning track of the Nexvisual program, carried out in partnership with Eldorado.

## About the Project

PosicionaAI is an iOS application focused on improving the acoustic placement of speakers through Computer Vision.

In its current MVP, the app analyzes a room photo, detects visible speakers, and returns simple placement guidance for non-technical users. The solution is built with native Apple technologies and uses Core ML for on-device inference.

## Objective

My main goal with this project is to build products that use computer vision to create more interactive and immersive experiences, exploring new ways to connect users with the physical environment around them.

## Technical Architecture

The application was designed around native Apple frameworks, with a focus on performance, privacy, and offline usage.

- Capture: room photo input selected directly in the app
- Inference: object detection with a custom Core ML model
- Logic: bounding-box analysis and lightweight heuristics to generate placement recommendations

## What this version does

- lets the user choose a static room photo
- detects visible speakers
- returns beginner-friendly placement recommendations
- runs fully offline on device

## Current scope

This is an MVP, so the scope is intentionally narrow.

- Platform: iPhone
- Input: one static photo
- Output: text-based guidance
- Detection target in v1: speakers only

## What it does not do yet

- it does not analyze video
- it does not measure real acoustic response
- it does not detect walls, racks, furniture, or other room elements yet
- it does not replace a proper acoustic calibration workflow

## Project structure

- `PosicionaAI/`: app source
- `PosicionaAI.xcodeproj/`: Xcode project
- `scripts/`: local model pipeline helpers
- `TRAINING.md`: notes for training and exporting the model

## Notes

This repository reflects the current learning and MVP stage of the project. The detection logic and guidance are intentionally simple in this version, and future iterations can expand the model coverage and improve recommendation quality.
