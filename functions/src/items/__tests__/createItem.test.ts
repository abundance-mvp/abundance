import { createItem } from "../createItem";

// Mock Firestore
const mockSet = jest.fn(() => Promise.resolve());
const mockDoc = jest.fn(() => ({
  set: mockSet,
}));
const mockCollection = jest.fn(() => ({
  doc: mockDoc,
}));

jest.mock("firebase-admin", () => {
  const mockFirestore = jest.fn(() => ({
    collection: mockCollection,
  }));

  // Add FieldValue as a static property
  (mockFirestore as any).FieldValue = {
    serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP"),
  };

  return {
    firestore: mockFirestore,
  };
});

describe("createItem", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("should create item in Firestore with correct data", async () => {
    // Given
    const userId = "user_123";
    const imageUrl = "https://storage.googleapis.com/test.jpg";
    const layer1Result = {
      detectedClass: "tent",
      confidence: 0.87,
      boundingBox: { x: 100, y: 200, width: 300, height: 400 },
    };

    // When
    const itemId = await createItem(userId, imageUrl, layer1Result, null);

    // Then
    expect(itemId).toMatch(/^item_/);
    expect(mockCollection).toHaveBeenCalledWith("items");
  });
});
