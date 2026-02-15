#!/usr/bin/env python3
"""Export EdgeTAM PyTorch weights to three CoreML .mlpackage files.

This script automates the full export pipeline:
1. Clones the EdgeTAM repository (if not present)
2. Downloads the checkpoint (if not present)
3. Runs the official CoreML export
4. Copies the resulting .mlpackage files to Sources/EdgeTAMFeature/Resources/

Usage:
    python scripts/export_edgetam_coreml.py

    # Skip clone/download if you already have them:
    python scripts/export_edgetam_coreml.py \
        --edgetam-repo /path/to/EdgeTAM \
        --checkpoint /path/to/edgetam.pt

Output:
    Sources/EdgeTAMFeature/Resources/edgetam_image_encoder.mlpackage
    Sources/EdgeTAMFeature/Resources/edgetam_prompt_encoder.mlpackage
    Sources/EdgeTAMFeature/Resources/edgetam_mask_decoder.mlpackage

Reference:
    https://github.com/facebookresearch/EdgeTAM/tree/main/coreml
"""

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

# Project root (one level up from scripts/)
PROJECT_ROOT = Path(__file__).resolve().parent.parent
RESOURCES_DIR = PROJECT_ROOT / "Sources" / "EdgeTAMFeature" / "Resources"
DEFAULT_WORK_DIR = PROJECT_ROOT / ".edgetam-export"
EDGETAM_REPO_URL = "https://github.com/facebookresearch/EdgeTAM.git"
CHECKPOINT_URL = "https://huggingface.co/facebook/EdgeTAM/resolve/main/edgetam.pt"

MODEL_NAMES = [
    "edgetam_image_encoder.mlpackage",
    "edgetam_prompt_encoder.mlpackage",
    "edgetam_mask_decoder.mlpackage",
]


def run_cmd(cmd: list[str], cwd: Path | None = None, env: dict | None = None) -> None:
    """Run a shell command, streaming output."""
    print(f"  $ {' '.join(str(c) for c in cmd)}")
    result = subprocess.run(cmd, cwd=cwd, env=env)
    if result.returncode != 0:
        print(f"Command failed with exit code {result.returncode}")
        sys.exit(1)


def clone_repo(work_dir: Path) -> Path:
    """Clone EdgeTAM repo if not present."""
    repo_dir = work_dir / "EdgeTAM"
    if repo_dir.exists():
        print(f"EdgeTAM repo already exists at {repo_dir}")
        return repo_dir

    print("Cloning EdgeTAM repository...")
    work_dir.mkdir(parents=True, exist_ok=True)
    run_cmd(["git", "clone", "--depth", "1", EDGETAM_REPO_URL], cwd=work_dir)
    return repo_dir


def download_checkpoint(work_dir: Path) -> Path:
    """Download EdgeTAM checkpoint if not present."""
    checkpoint = work_dir / "edgetam.pt"
    if checkpoint.exists():
        print(f"Checkpoint already exists at {checkpoint}")
        return checkpoint

    print("Downloading EdgeTAM checkpoint (~54 MB)...")
    work_dir.mkdir(parents=True, exist_ok=True)

    # Try huggingface-cli first, fall back to curl
    try:
        run_cmd([
            "huggingface-cli", "download", "facebook/EdgeTAM",
            "edgetam.pt", "--local-dir", str(work_dir),
        ])
    except (FileNotFoundError, SystemExit):
        print("  huggingface-cli not found, using curl...")
        run_cmd(["curl", "-L", "-o", str(checkpoint), CHECKPOINT_URL])

    if not checkpoint.exists():
        print("ERROR: Failed to download checkpoint")
        sys.exit(1)

    size_mb = checkpoint.stat().st_size / (1024 * 1024)
    print(f"  Downloaded: {size_mb:.1f} MB")
    return checkpoint


def run_export(repo_dir: Path, checkpoint: Path, output_dir: Path) -> None:
    """Run the official EdgeTAM CoreML export script."""
    export_script = repo_dir / "coreml" / "export_to_coreml.py"
    config_file = repo_dir / "sam2" / "configs" / "edgetam.yaml"

    if not export_script.exists():
        print(f"ERROR: Export script not found at {export_script}")
        sys.exit(1)

    if not config_file.exists():
        # Try alternate config location
        config_file = repo_dir / "configs" / "edgetam.yaml"
        if not config_file.exists():
            print(f"ERROR: Config file not found")
            sys.exit(1)

    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"\nRunning CoreML export...")
    print(f"  Config:     {config_file}")
    print(f"  Checkpoint: {checkpoint}")
    print(f"  Output:     {output_dir}")

    # Set PYTHONPATH to include the EdgeTAM repo
    env = os.environ.copy()
    existing_path = env.get("PYTHONPATH", "")
    env["PYTHONPATH"] = f"{repo_dir}:{existing_path}" if existing_path else str(repo_dir)

    run_cmd(
        [
            sys.executable, str(export_script.resolve()),
            "--sam2_cfg", str(config_file.resolve()),
            "--sam2_checkpoint", str(checkpoint.resolve()),
            "--output_dir", str(output_dir.resolve()),
        ],
        cwd=repo_dir,
        env=env,
    )


def copy_to_resources(output_dir: Path) -> None:
    """Copy exported .mlpackage files to EdgeTAMFeature/Resources."""
    RESOURCES_DIR.mkdir(parents=True, exist_ok=True)

    print(f"\nCopying models to {RESOURCES_DIR}...")
    for name in MODEL_NAMES:
        src = output_dir / name
        dst = RESOURCES_DIR / name

        if not src.exists():
            print(f"ERROR: Expected model not found: {src}")
            sys.exit(1)

        if dst.exists():
            shutil.rmtree(dst)

        shutil.copytree(src, dst)
        size_mb = sum(f.stat().st_size for f in dst.rglob("*") if f.is_file()) / (1024 * 1024)
        print(f"  {name} ({size_mb:.1f} MB)")

    # Remove placeholder file if it exists
    placeholder = RESOURCES_DIR / "Placeholder.strings"
    if placeholder.exists():
        placeholder.unlink()
        print("  Removed Placeholder.strings")

    print("\nDone! Models are ready for SPM build.")


def verify_models() -> bool:
    """Verify all three .mlpackage files exist in Resources."""
    all_ok = True
    for name in MODEL_NAMES:
        path = RESOURCES_DIR / name
        if path.exists():
            size_mb = sum(f.stat().st_size for f in path.rglob("*") if f.is_file()) / (1024 * 1024)
            print(f"  {name}: {size_mb:.1f} MB")
        else:
            print(f"  {name}: MISSING")
            all_ok = False
    return all_ok


def main():
    parser = argparse.ArgumentParser(
        description="Export EdgeTAM to CoreML for Abundance MVP"
    )
    parser.add_argument(
        "--edgetam-repo",
        type=Path,
        help="Path to existing EdgeTAM repo (skips clone)",
    )
    parser.add_argument(
        "--checkpoint",
        type=Path,
        help="Path to existing edgetam.pt checkpoint (skips download)",
    )
    parser.add_argument(
        "--work-dir",
        type=Path,
        default=DEFAULT_WORK_DIR,
        help=f"Working directory for clone/download (default: {DEFAULT_WORK_DIR})",
    )
    parser.add_argument(
        "--verify-only",
        action="store_true",
        help="Only verify models exist in Resources, don't export",
    )

    args = parser.parse_args()

    if args.verify_only:
        print("Verifying models in Resources/...")
        if verify_models():
            print("\nAll models present.")
        else:
            print("\nSome models missing. Run export first.")
            sys.exit(1)
        return

    print("=== EdgeTAM CoreML Export ===\n")

    # Step 1: Get repo
    if args.edgetam_repo:
        repo_dir = args.edgetam_repo.resolve()
        if not repo_dir.exists():
            print(f"ERROR: Repo not found at {repo_dir}")
            sys.exit(1)
    else:
        repo_dir = clone_repo(args.work_dir)

    # Step 2: Get checkpoint
    if args.checkpoint:
        checkpoint = args.checkpoint.resolve()
        if not checkpoint.exists():
            print(f"ERROR: Checkpoint not found at {checkpoint}")
            sys.exit(1)
    else:
        checkpoint = download_checkpoint(args.work_dir)

    # Step 3: Export
    export_output = args.work_dir / "coreml_models"
    run_export(repo_dir, checkpoint, export_output)

    # Step 4: Copy to Resources
    copy_to_resources(export_output)

    # Step 5: Verify
    print("\nVerification:")
    verify_models()

    print(f"""
Next steps:
  1. Run 'swift build' to compile .mlpackage -> .mlmodelc
  2. Run benchmark tests on device:
     swift test --filter EdgeTAMBenchmarkTests
""")


if __name__ == "__main__":
    main()
