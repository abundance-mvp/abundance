#!/usr/bin/env python3
"""
Test YOLOv11n object detection on an image
Usage: python3 test-yolo11n.py <image_path>
"""

from ultralytics import YOLO
import sys

if len(sys.argv) < 2:
    print("Usage: python3 test-yolo11n.py <image_path>")
    sys.exit(1)

image_path = sys.argv[1]

print(f"📸 Loading image: {image_path}")
print("")

# Load YOLOv11n model
model = YOLO('yolo11n.pt')

print("🎯 Running YOLOv11n Detection...")
print("═" * 60)

# Run inference
results = model(image_path, verbose=False)

# Process results
for result in results:
    boxes = result.boxes

    if len(boxes) == 0:
        print("⚠️  No objects detected")
        continue

    print(f"Total objects detected: {len(boxes)}")
    print("")

    for i, box in enumerate(boxes):
        # Get box coordinates
        x1, y1, x2, y2 = box.xyxy[0].tolist()
        conf = box.conf[0].item()
        cls = int(box.cls[0].item())
        label = model.names[cls]

        print(f"Object #{i+1}:")
        print(f"  Label: {label}")
        print(f"  Confidence: {conf*100:.2f}%")
        print(f"  Bounding Box (pixels):")
        print(f"    x1: {int(x1)}, y1: {int(y1)}")
        print(f"    x2: {int(x2)}, y2: {int(y2)}")
        print(f"    width: {int(x2-x1)}, height: {int(y2-y1)}")
        print("")

print("═" * 60)
print("")
print("📊 Metadata Structure:")
print("  • Boxes: tensor([x1, y1, x2, y2])")
print("  • Confidence: float (0-1)")
print("  • Class: int (0-79 for COCO)")
print("  • Label: string (e.g., 'mouse', 'scissors')")
print("")
print("🎯 COCO Classes Relevant to Your Image:")
print("  - mouse (class 64)")
print("  - scissors (class 76)")
print("  - keyboard (class 66)")
print("  - cell phone (class 67)")
print("  - book (class 73)")
