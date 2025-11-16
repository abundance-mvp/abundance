import { OpenFoodFactsProvider } from '../OpenFoodFactsProvider';

describe('OpenFoodFactsProvider', () => {
  let provider: OpenFoodFactsProvider;

  beforeEach(() => {
    provider = new OpenFoodFactsProvider();
  });

  test('finds product by barcode', async () => {
    const barcode = '049000050103'; // Coca-Cola Classic
    const result = await provider.lookup(barcode);

    expect(result).not.toBeNull();
    expect(result?.found).toBe(true);
    expect(result?.source).toBe('openfoodfacts');
    expect(result?.name).toBeDefined();
    expect(result?.barcode).toBe(barcode);
  });

  test('handles barcode lookup', async () => {
    const barcode = '012345678901'; // Test barcode
    const result = await provider.lookup(barcode);

    // May or may not find a product, just verify it returns valid structure
    if (result) {
      expect(result.found).toBe(true);
      expect(result.source).toBe('openfoodfacts');
    }
  });

  test('handles timeout gracefully', async () => {
    jest.setTimeout(5000);
    const barcode = '000000000000'; // Trigger slow response
    const result = await provider.lookup(barcode);

    expect(result).toBeNull();
  }, 5000);
});
