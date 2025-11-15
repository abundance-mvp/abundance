import * as admin from "firebase-admin";
import { Item } from "./getItem";

export interface ItemWithId extends Item {
  id: string;
}

export async function listItems(
  userId: string,
  limit: number = 20
): Promise<ItemWithId[]> {
  const db = admin.firestore();

  const querySnapshot = await db
    .collection("items")
    .where("userId", "==", userId)
    .orderBy("createdAt", "desc")
    .limit(limit)
    .get();

  return querySnapshot.docs.map((doc) => ({
    id: doc.id,
    ...(doc.data() as Item),
  }));
}
