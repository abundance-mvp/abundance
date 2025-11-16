import { ClaudeSonnetProvider, Layer2aData, Layer2bData, SynthesizedMetadata } from '../providers/ClaudeSonnetProvider';

export async function synthesizeMetadata(
  itemData: {
    detectedLabel: string;
    layer2a: Layer2aData;
    layer2b: Layer2bData;
  },
  itemId: string
): Promise<SynthesizedMetadata> {
  const claudeSonnet = new ClaudeSonnetProvider();

  console.log(`[Layer3] Starting synthesis for item ${itemId}`);

  const synthesized = await claudeSonnet.synthesize(
    itemData.layer2a,
    itemData.layer2b,
    itemData.detectedLabel,
    itemId
  );

  console.log(`[Layer3] ✅ Synthesis complete for item ${itemId}: ${synthesized.name}`);

  return synthesized;
}
