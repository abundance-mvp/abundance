import {
  SYSTEM_PROMPT,
  CATALOG_TOOLS,
  GENERATION_CONFIG
} from '../prompts';

describe('Gemini 3 Pro Prompts', () => {
  describe('SYSTEM_PROMPT', () => {
    it('should include workflow instructions', () => {
      expect(SYSTEM_PROMPT).toContain('WORKFLOW');
      expect(SYSTEM_PROMPT).toContain('barcode');
      expect(SYSTEM_PROMPT).toContain('google_lens');
    });

    it('should include confidence scoring rules', () => {
      expect(SYSTEM_PROMPT).toContain('CONFIDENCE SCORING');
      expect(SYSTEM_PROMPT).toContain('high');
      expect(SYSTEM_PROMPT).toContain('medium');
      expect(SYSTEM_PROMPT).toContain('low');
    });

    it('should include pricing multipliers', () => {
      expect(SYSTEM_PROMPT).toContain('condition multipliers');
      expect(SYSTEM_PROMPT).toContain('0.65');
    });
  });

  describe('CATALOG_TOOLS', () => {
    it('should define google_lens_search tool', () => {
      const googleLensTool = CATALOG_TOOLS.find(
        t => t.functionDeclarations?.[0]?.name === 'google_lens_search'
      );
      expect(googleLensTool).toBeDefined();
      expect(googleLensTool?.functionDeclarations?.[0]?.parameters?.properties).toHaveProperty('image_url');
    });

    it('should define barcode_lookup tool', () => {
      const barcodeTool = CATALOG_TOOLS.find(
        t => t.functionDeclarations?.[0]?.name === 'barcode_lookup'
      );
      expect(barcodeTool).toBeDefined();
      expect(barcodeTool?.functionDeclarations?.[0]?.parameters?.properties).toHaveProperty('code');
    });

    it('should define web_search tool', () => {
      const webSearchTool = CATALOG_TOOLS.find(
        t => t.functionDeclarations?.[0]?.name === 'web_search'
      );
      expect(webSearchTool).toBeDefined();
      expect(webSearchTool?.functionDeclarations?.[0]?.parameters?.properties).toHaveProperty('query');
    });
  });

  describe('GENERATION_CONFIG', () => {
    it('should use low temperature for consistent output', () => {
      expect(GENERATION_CONFIG.temperature).toBeLessThanOrEqual(0.2);
    });

    it('should request JSON output', () => {
      expect(GENERATION_CONFIG.responseMimeType).toBe('application/json');
    });

    it('should include response schema', () => {
      expect(GENERATION_CONFIG.responseSchema).toBeDefined();
      expect(GENERATION_CONFIG.responseSchema.type).toBe('object');
    });
  });
});
