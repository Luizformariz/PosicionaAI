#!/bin/zsh

set -euo pipefail

PROJECT_ROOT="/Users/luizformariz/Documents/New project/PosicionaAI"
DATASET_ROOT="/Users/luizformariz/Downloads/speaker-detector"
VENV_DIR="$PROJECT_ROOT/.venv-speaker-model"
DEFAULT_MODEL="yolo11n.pt"
DEFAULT_IMAGE_SIZE="640"
DEFAULT_EPOCHS="50"

usage() {
  cat <<EOF
Usage:
  ./scripts/speaker_model_pipeline.sh setup
  ./scripts/speaker_model_pipeline.sh train [model] [epochs] [imgsz]
  ./scripts/speaker_model_pipeline.sh export [weights_path]
  ./scripts/speaker_model_pipeline.sh all [model] [epochs] [imgsz]

Examples:
  ./scripts/speaker_model_pipeline.sh setup
  ./scripts/speaker_model_pipeline.sh train
  ./scripts/speaker_model_pipeline.sh train yolo11n.pt 75 640
  ./scripts/speaker_model_pipeline.sh export
  ./scripts/speaker_model_pipeline.sh all
EOF
}

ensure_dataset() {
  if [[ ! -f "$DATASET_ROOT/data.yaml" ]]; then
    echo "Dataset not found at: $DATASET_ROOT"
    exit 1
  fi
}

activate_venv() {
  if [[ ! -f "$VENV_DIR/bin/activate" ]]; then
    echo "Virtual environment not found. Run: ./scripts/speaker_model_pipeline.sh setup"
    exit 1
  fi

  source "$VENV_DIR/bin/activate"
}

setup_env() {
  echo "Creating virtual environment at $VENV_DIR"
  python3 -m venv "$VENV_DIR"
  source "$VENV_DIR/bin/activate"
  python -m pip install --upgrade pip
  python -m pip install ultralytics coremltools
  echo "Setup complete."
}

train_model() {
  local model="${1:-$DEFAULT_MODEL}"
  local epochs="${2:-$DEFAULT_EPOCHS}"
  local imgsz="${3:-$DEFAULT_IMAGE_SIZE}"

  ensure_dataset
  activate_venv

  cd "$PROJECT_ROOT"
  yolo task=detect mode=train \
    model="$model" \
    data="$DATASET_ROOT/data.yaml" \
    imgsz="$imgsz" \
    epochs="$epochs" \
    project="$PROJECT_ROOT/model_runs" \
    name="speaker_detector"
}

export_model() {
  local weights_path="${1:-$PROJECT_ROOT/model_runs/speaker_detector/weights/best.pt}"

  activate_venv

  if [[ ! -f "$weights_path" ]]; then
    echo "Weights not found at: $weights_path"
    echo "Train the model first or pass a custom weights path."
    exit 1
  fi

  cd "$PROJECT_ROOT"
  yolo mode=export \
    model="$weights_path" \
    format=coreml \
    imgsz="$DEFAULT_IMAGE_SIZE" \
    int8=True
}

run_all() {
  setup_env
  train_model "${1:-$DEFAULT_MODEL}" "${2:-$DEFAULT_EPOCHS}" "${3:-$DEFAULT_IMAGE_SIZE}"
  export_model
}

main() {
  local command="${1:-}"

  case "$command" in
    setup)
      setup_env
      ;;
    train)
      shift
      train_model "${1:-$DEFAULT_MODEL}" "${2:-$DEFAULT_EPOCHS}" "${3:-$DEFAULT_IMAGE_SIZE}"
      ;;
    export)
      shift
      export_model "${1:-$PROJECT_ROOT/model_runs/speaker_detector/weights/best.pt}"
      ;;
    all)
      shift
      run_all "${1:-$DEFAULT_MODEL}" "${2:-$DEFAULT_EPOCHS}" "${3:-$DEFAULT_IMAGE_SIZE}"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
