import { ClaudeHaikuProvider } from '../ClaudeHaikuProvider';
import { VisualMatch } from '../SerpAPIProvider';

// Mock the Anthropic SDK
jest.mock('@anthropic-ai/sdk', () => {
  return {
    __esModule: true,
    default: jest.fn().mockImplementation(() => ({
      messages: {
        create: jest.fn().mockResolvedValue({
          content: [{
            type: 'text',
            text: JSON.stringify({
              brand: 'Coleman',
              model: 'Triton',
              variant: '2-Burner',
              estimatedValue: 44.99,
              confidence: 0.9,
              reasoning: 'Consistent results across multiple sources',
            }),
          }],
          usage: {
            input_tokens: 500,
            output_tokens: 100,
          },
        }),
      },
    })),
  };
});

describe('ClaudeHaikuProvider', () => {
  let provider: ClaudeHaikuProvider;

  beforeEach(() => {
    process.env.ANTHROPIC_API_KEY = 'test-anthropic-key';
    provider = new ClaudeHaikuProvider();
  });

  test('parses SerpAPI results into structured product data', async () => {
    const visualMatches: VisualMatch[] = [
      {
        position: 1,
        title: 'Coleman Triton 2-Burner Camping Stove - Green',
        link: 'https://www.amazon.com/Coleman-Triton-Camping-Stove/dp/B0009PUQK8',
        source: 'Amazon.com',
        price: {
          value: '$44.99',
          extracted_value: 44.99,
          currency: 'USD',
        },
      },
      {
        position: 2,
        title: 'Coleman Camping Stove',
        link: 'https://www.walmart.com/...',
        source: 'Walmart',
        price: {
          value: '$45',
          extracted_value: 45.00,
          currency: 'USD',
        },
      },
    ];

    const result = await provider.parse(visualMatches, 'test_item_123');

    expect(result.brand).toBe('Coleman');
    expect(result.model).toContain('Triton');
    expect(result.variant).toContain('2-Burner');
    expect(result.estimatedValue).toBeGreaterThan(0);
    expect(result.confidence).toBeGreaterThan(0);
    expect(result.tokensUsed.total).toBeGreaterThan(0);
  });
});
