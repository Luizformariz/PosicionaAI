# Speaker Model Pipeline

Use this after exporting the annotated Roboflow dataset to:

`/Users/luizformariz/Downloads/speaker-detector`

Repository path used below:

`/Users/luizformariz/GitHub/posicionaAI/PosicionaAI`

## One-time setup

```bash
cd '/Users/luizformariz/GitHub/posicionaAI/PosicionaAI'
chmod +x scripts/speaker_model_pipeline.sh
./scripts/speaker_model_pipeline.sh setup
```

## Train the first model

```bash
cd '/Users/luizformariz/GitHub/posicionaAI/PosicionaAI'
./scripts/speaker_model_pipeline.sh train
```

Defaults:

- Base model: `yolo11n.pt`
- Epochs: `50`
- Image size: `640`

Custom example:

```bash
./scripts/speaker_model_pipeline.sh train yolo11n.pt 75 640
```

## Export to Core ML

```bash
cd '/Users/luizformariz/GitHub/posicionaAI/PosicionaAI'
./scripts/speaker_model_pipeline.sh export
```

Expected weights path:

`/Users/luizformariz/GitHub/posicionaAI/PosicionaAI/model_runs/speaker_detector/weights/best.pt`

## Full pipeline

```bash
cd '/Users/luizformariz/GitHub/posicionaAI/PosicionaAI'
./scripts/speaker_model_pipeline.sh all
```

## Expected output

After export, look for a Core ML artifact generated inside the project root or inside `model_runs`.
Add that file to the Xcode project and make sure it is included in the app target.
