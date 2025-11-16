import { UPCitemdbProvider, RateLimitError } from '../UPCitemdbProvider';

describe('UPCitemdbProvider', () => {
  let provider: UPCitemdbProvider;

  beforeEach(() => {
    process.env.UPCITEMDB_API_KEY = 'test-api-key';
    provider = new UPCitemdbProvider();
  });

  test('finds product with valid barcode', async () => {
    // Mock fetch for testing
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        code: 'OK',
        total: 1,
        items: [{
          title: 'Coleman Triton 2-Burner Camping Stove',
          brand: 'Coleman',
          category: 'Camping & Hiking',
          images: ['https://example.com/coleman.jpg'],
          upc: '012345678905',
          ean: '0012345678905',
        }],
      }),
    });

    const barcode = '012345678905';
    const result = await provider.lookup(barcode);

    expect(result).not.toBeNull();
    expect(result?.found).toBe(true);
    expect(result?.source).toBe('upcitemdb');
    expect(result?.name).toContain('Coleman');
    expect(result?.brand).toBe('Coleman');
  });

  test('returns null for invalid barcode (404)', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: false,
      status: 404,
    });

    const barcode = '000000000000';
    const result = await provider.lookup(barcode);

    expect(result).toBeNull();
  });

  test('throws RateLimitError on 429', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: false,
      status: 429,
    });

    const barcode = '012345678905';
    await expect(provider.lookup(barcode)).rejects.toThrow(RateLimitError);
  });
});
