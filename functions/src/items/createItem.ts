import * as admin from "firebase-admin";

export interface Layer1Result {
  detectedClass: string;
  confidence: number;
  boundingBox: {
    x: number;
    y: number;
    width: number;
    height: number;
  };
}

export async function createItem(
  userId: string,
  imageUrl: string,
  layer1Result: Layer1Result,
  detectedBarcode: string | null
): Promise<string> {
  const db = admin.firestore();
  const itemId = `item_${Date.now()}_${Math.random()
    .toString(36)
    .substring(7)}`;

  const itemData = {
    userId,
    imageUrl,
    layer1Result,
    detectedBarcode,
    status: "processing",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    layer1Complete: true,
    layer2aScheduled: true,
    layer2bScheduled: true,
  };

  await db.collection("items").doc(itemId).set(itemData);

  return itemId;
}
