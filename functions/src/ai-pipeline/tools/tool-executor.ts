/**
 * Tool Executor
 *
 * Routes Gemini function calls to the appropriate tool implementations.
 * This is the central dispatch point for all AI pipeline tool invocations.
 */

import { searchGoogleLens } from './google-lens';
import { lookupBarcode } from './barcode-lookup';
import { searchWeb } from './web-search';

/**
 * Execute a tool call from Gemini's function calling response.
 *
 * @param name - The name of the tool to execute
 * @param args - Arguments passed by Gemini for the tool
 * @param imageUrl - Default image URL to use for image-based tools
 * @returns The result from the tool execution
 * @throws Error if the tool name is unknown
 */
export async function executeToolCall(
  name: string,
  args: Record<string, unknown>,
  imageUrl: string
): Promise<unknown> {
  switch (name) {
    case 'google_lens_search': {
      const searchImageUrl = (args.image_url as string) || imageUrl;
      return searchGoogleLens(searchImageUrl);
    }

    case 'barcode_lookup': {
      return lookupBarcode(
        args.code as string,
        args.symbology as string | undefined
      );
    }

    case 'web_search': {
      return searchWeb(args.query as string);
    }

    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}
