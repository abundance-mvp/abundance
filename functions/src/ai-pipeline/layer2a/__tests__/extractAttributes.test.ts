import { extractAttributesLayer2a } from '../extractAttributes';
import { GeminiProvider } from '../../providers/GeminiProvider';
import { CostLogger } from '../../cost-tracking/CostLogger';

jest.mock('../../providers/GeminiProvider');
jest.mock('../../cost-tracking/CostLogger');

describe('extractAttributesLayer2a', () => {
  it('should extract attributes and log cost', async () => {
    const mockExtract = jest.fn().mockResolvedValue({
      category: 'camping',
      color: 'green',
      material: 'fabric',
      condition: 'good',
      confidence: 0.87,
      usage: {
        inputTokens: 258,
        outputTokens: 100,
        totalTokens: 358
      }
    });

    const mockCalculateCost = jest.fn().mockReturnValue(0.00006);
    const mockLogCost = jest.fn().mockResolvedValue(undefined);

    (GeminiProvider as jest.Mock).mockImplementation(() => ({
      extractAttributes: mockExtract
    }));

    (CostLogger as jest.Mock).mockImplementation(() => ({
      calculateCost: mockCalculateCost,
      logCost: mockLogCost
    }));

    const result = await extractAttributesLayer2a(
      'user123',
      'item456',
      'https://storage.googleapis.com/test/image.jpg'
    );

    expect(result).toEqual({
      category: 'camping',
      color: 'green',
      material: 'fabric',
      condition: 'good',
      confidence: 0.87
    });

    expect(mockExtract).toHaveBeenCalledWith(
      'https://storage.googleapis.com/test/image.jpg',
      'user123',
      'item456'
    );

    expect(mockCalculateCost).toHaveBeenCalledWith(
      'gemini-2.5-flash-lite',
      258,
      100
    );

    expect(mockLogCost).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: 'user123',
        itemId: 'item456',
        provider: 'gemini',
        model: 'gemini-2.5-flash-lite',
        operation: 'layer2a_extraction',
        inputTokens: 258,
        outputTokens: 100,
        totalTokens: 358,
        cost: 0.00006
      })
    );
  });
});
