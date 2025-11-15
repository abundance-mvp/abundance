import * as admin from "firebase-admin";

export interface Item {
  userId: string;
  imageUrl: string;
  status: string;
  createdAt: admin.firestore.Timestamp;
  layer1Result?: any;
  detectedBarcode?: string | null;
}

export async function getItem(itemId: string): Promise<Item | null> {
  const db = admin.firestore();
  const doc = await db.collection("items").doc(itemId).get();

  if (!doc.exists) {
    return null;
  }

  return doc.data() as Item;
}
