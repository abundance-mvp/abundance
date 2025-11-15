import { getItem } from "../getItem";

const mockGet = jest.fn(() =>
  Promise.resolve({
    exists: true,
    data: () => ({ userId: "user_123", status: "complete" }),
  })
);
const mockDoc = jest.fn(() => ({
  get: mockGet,
}));
const mockCollection = jest.fn(() => ({
  doc: mockDoc,
}));

jest.mock("firebase-admin", () => ({
  firestore: jest.fn(() => ({
    collection: mockCollection,
  })),
}));

describe("getItem", () => {
  it("should retrieve item from Firestore", async () => {
    // When
    const item = await getItem("item_123");

    // Then
    expect(item).toBeDefined();
    expect(item?.userId).toBe("user_123");
  });
});
