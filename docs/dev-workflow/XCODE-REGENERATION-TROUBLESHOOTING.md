# Xcode Project Troubleshooting

## Quick Fix

Most issues are solved by regenerating the project:

```bash
./scripts/regenerate-xcode-project.sh --yes
```

## Common Issues

### "No such module" errors

```bash
# Clean DerivedData and regenerate
rm -rf ~/Library/Developer/Xcode/DerivedData/Abundance-*
./scripts/regenerate-xcode-project.sh --yes
```

### Signing issues

1. Open `Abundance.xcodeproj` in Xcode
2. Select the Abundance target
3. Signing & Capabilities → Select your team
4. Build again

### XcodeGen not found

```bash
brew install xcodegen
```

## When to Regenerate

- After editing `project.yml`
- After adding/removing Swift files (usually auto-detected)
- When build errors don't match your code
- After pulling changes that modified project structure

## Architecture

The Xcode project is generated from `project.yml` using XcodeGen:

```
project.yml (source of truth)
    ↓ xcodegen generate
Abundance.xcodeproj (generated, git-ignored)
```

Never edit the `.xcodeproj` directly - changes will be lost on regeneration.
