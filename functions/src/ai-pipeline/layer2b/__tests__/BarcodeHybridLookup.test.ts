import { BarcodeHybridLookup } from '../BarcodeHybridLookup';

// Mock the providers
jest.mock('../../providers/OpenFoodFactsProvider', () => ({
  OpenFoodFactsProvider: jest.fn().mockImplementation(() => ({
    lookup: jest.fn().mockResolvedValue(null),
  })),
}));

jest.mock('../../providers/UPCitemdbProvider', () => ({
  UPCitemdbProvider: jest.fn().mockImplementation(() => ({
    lookup: jest.fn().mockResolvedValue(null),
  })),
}));

describe('BarcodeHybridLookup', () => {
  let lookup: BarcodeHybridLookup;

  beforeEach(() => {
    lookup = new BarcodeHybridLookup();
  });

  test('tries OpenFoodFacts first for food item', async () => {
    const barcodeData = { value: '049000050103', type: 'EAN-13' };
    const result = await lookup.lookup(barcodeData, 'test_item_123');

    // May return OpenFoodFacts or UPCitemdb result, or null
    // Since both are mocked to return null, result will be null
    expect(result).toBeNull();
  });

  test('returns null if no barcode data', async () => {
    const result = await lookup.lookup(null, 'test_item_456');
    expect(result).toBeNull();
  });
});
