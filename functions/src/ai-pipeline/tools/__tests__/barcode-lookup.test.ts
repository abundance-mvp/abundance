import { lookupBarcode } from '../barcode-lookup';

describe('Barcode Lookup Tool', () => {
  const originalFetch = global.fetch;

  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterEach(() => {
    global.fetch = originalFetch;
  });

  it('should return product info when barcode found', async () => {
    const mockResponse = {
      items: [
        {
          ean: '012345678905',
          title: 'Coleman Sundome Tent',
          brand: 'Coleman',
          model: 'Sundome',
          description: '4-person camping tent'
        }
      ]
    };

    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => mockResponse
    });

    const result = await lookupBarcode('012345678905');

    expect(result.found).toBe(true);
    expect(result.product?.title).toBe('Coleman Sundome Tent');
    expect(result.product?.brand).toBe('Coleman');
    expect(result.product?.model).toBe('Sundome');
  });

  it('should return not found when barcode not in database', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ items: [] })
    });

    const result = await lookupBarcode('999999999999');

    expect(result.found).toBe(false);
    expect(result.barcode).toBe('999999999999');
    expect(result.product).toBeUndefined();
  });

  it('should handle API errors gracefully', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: false,
      status: 500
    });

    const result = await lookupBarcode('012345678905');

    expect(result.found).toBe(false);
    expect(result.barcode).toBe('012345678905');
  });

  it('should handle network timeout gracefully', async () => {
    global.fetch = jest.fn().mockRejectedValue(new Error('Network timeout'));

    const result = await lookupBarcode('012345678905');

    expect(result.found).toBe(false);
    expect(result.barcode).toBe('012345678905');
  });

  it('should handle missing items array gracefully', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({})
    });

    const result = await lookupBarcode('012345678905');

    expect(result.found).toBe(false);
    expect(result.barcode).toBe('012345678905');
  });

  it('should handle null items gracefully', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ items: null })
    });

    const result = await lookupBarcode('012345678905');

    expect(result.found).toBe(false);
    expect(result.barcode).toBe('012345678905');
  });

  it('should use first item when multiple items returned', async () => {
    const mockResponse = {
      items: [
        { title: 'First Product', brand: 'Brand A' },
        { title: 'Second Product', brand: 'Brand B' }
      ]
    };

    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => mockResponse
    });

    const result = await lookupBarcode('012345678905');

    expect(result.found).toBe(true);
    expect(result.product?.title).toBe('First Product');
    expect(result.product?.brand).toBe('Brand A');
  });

  it('should handle missing optional fields gracefully', async () => {
    const mockResponse = {
      items: [
        { title: 'Product Without Details' }
        // No brand, model, or description
      ]
    };

    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => mockResponse
    });

    const result = await lookupBarcode('012345678905');

    expect(result.found).toBe(true);
    expect(result.product?.title).toBe('Product Without Details');
    expect(result.product?.brand).toBeUndefined();
    expect(result.product?.model).toBeUndefined();
    expect(result.product?.description).toBeUndefined();
  });

  it('should construct correct API URL', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ items: [] })
    });

    await lookupBarcode('012345678905');

    expect(global.fetch).toHaveBeenCalledTimes(1);
    const calledUrl = (global.fetch as jest.Mock).mock.calls[0][0];
    expect(calledUrl).toContain('https://api.upcitemdb.com/prod/trial/lookup');
    expect(calledUrl).toContain('upc=012345678905');
  });

  it('should set correct headers', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ items: [] })
    });

    await lookupBarcode('012345678905');

    const callOptions = (global.fetch as jest.Mock).mock.calls[0][1];
    expect(callOptions.method).toBe('GET');
    expect(callOptions.headers['Accept']).toBe('application/json');
    expect(callOptions.headers['User-Agent']).toBe('Abundance-App/1.0');
  });
});
