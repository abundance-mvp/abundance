import { listItems } from "../listItems";

const mockGet = jest.fn(() =>
  Promise.resolve({
    docs: [
      { id: "item_1", data: () => ({ status: "complete" }) },
      { id: "item_2", data: () => ({ status: "processing" }) },
    ],
  })
);
const mockLimit = jest.fn(() => ({
  get: mockGet,
}));
const mockOrderBy = jest.fn(() => ({
  limit: mockLimit,
}));
const mockWhere = jest.fn(() => ({
  orderBy: mockOrderBy,
}));
const mockCollection = jest.fn(() => ({
  where: mockWhere,
}));

jest.mock("firebase-admin", () => ({
  firestore: jest.fn(() => ({
    collection: mockCollection,
  })),
}));

describe("listItems", () => {
  it("should list items for user", async () => {
    // When
    const items = await listItems("user_123", 10);

    // Then
    expect(items).toHaveLength(2);
    expect(items[0].id).toBe("item_1");
  });
});
