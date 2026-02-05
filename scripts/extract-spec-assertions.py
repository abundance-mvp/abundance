#!/usr/bin/env python3
"""
extract-spec-assertions.py - Extract testable assertions from spec documents

This script:
1. Reads all spec documents in docs/specs/
2. Extracts testable assertions (marked with ```spec-assertions blocks)
3. Generates:
   - XCTest test cases (automated tests)
   - Manual testing checklist (.debug/manual-testing-checklist.md)
   - Runtime assertion helpers (Swift code)

Usage:
    python3 scripts/extract-spec-assertions.py

Created: 2025-11-16
References: Abundance iteration system Layer 2
"""

import os
import re
import json
from pathlib import Path
from typing import List, Dict, Any

PROJECT_ROOT = Path(__file__).parent.parent
SPECS_DIR = PROJECT_ROOT / "docs" / "specs"
OUTPUT_DIR = PROJECT_ROOT / ".debug"
TESTS_DIR = PROJECT_ROOT / "Tests" / "Generated"


class SpecAssertion:
    """Represents a testable assertion extracted from a spec document"""

    def __init__(self, spec_name: str, section: str, assertion: str, assertion_type: str = "manual"):
        self.spec_name = spec_name
        self.section = section
        self.assertion = assertion
        self.assertion_type = assertion_type  # "automated" or "manual"

    def to_swift_test(self) -> str:
        """Generate XCTest test case"""
        test_name = self._sanitize_test_name()
        return f'''
    func test{test_name}() async throws {{
        // {self.spec_name} § {self.section}
        // ASSERT: {self.assertion}

        // TODO: Implement test logic
        XCTFail("Test not implemented yet")
    }}
'''

    def to_checklist_item(self) -> str:
        """Generate manual testing checklist item"""
        return f"- [ ] {self.assertion}"

    def _sanitize_test_name(self) -> str:
        """Convert assertion to valid Swift test method name"""
        # Extract key words from assertion
        words = re.findall(r'\w+', self.assertion)
        # Take first 5-6 significant words
        name = ''.join(word.capitalize() for word in words[:6])
        return name


def extract_assertions_from_spec(spec_path: Path) -> List[SpecAssertion]:
    """Extract assertions from a single spec document"""
    assertions = []

    with open(spec_path, 'r') as f:
        content = f.read()

    spec_name = spec_path.stem

    # Find all ```spec-assertions blocks
    assertion_blocks = re.findall(
        r'```spec-assertions\s*\n(.*?)\n```',
        content,
        re.DOTALL
    )

    # Also look for explicit assertion markers
    assertion_lines = re.findall(
        r'- ASSERT:\s*(.+?)(?:\n|$)',
        content
    )

    current_section = "General"

    # Extract section headings
    lines = content.split('\n')
    for i, line in enumerate(lines):
        # Detect section headings (## or ###)
        if line.startswith('## ') or line.startswith('### '):
            current_section = line.strip('# ').strip()

        # Look for assertion markers
        if '- ASSERT:' in line or 'MUST:' in line or 'SHOULD:' in line:
            assertion_text = line.strip().lstrip('- ').lstrip('ASSERT:').strip()
            assertions.append(SpecAssertion(
                spec_name=spec_name,
                section=current_section,
                assertion=assertion_text,
                assertion_type="manual"
            ))

    # Process assertion blocks
    for block in assertion_blocks:
        for line in block.split('\n'):
            line = line.strip()
            if line and line.startswith('- ASSERT:'):
                assertion_text = line.lstrip('- ASSERT:').strip()
                assertions.append(SpecAssertion(
                    spec_name=spec_name,
                    section=current_section,
                    assertion=assertion_text,
                    assertion_type="automated"
                ))

    return assertions


def generate_xctest_file(assertions: List[SpecAssertion]) -> str:
    """Generate XCTest file with all spec assertions"""
    test_cases = '\n'.join(a.to_swift_test() for a in assertions if a.assertion_type == "automated")

    return f'''//
// SpecAssertionTests.swift
// Generated from spec documents by extract-spec-assertions.py
//
// DO NOT EDIT MANUALLY - regenerate with:
//   python3 scripts/extract-spec-assertions.py
//
// Created: {Path(__file__).stat().st_mtime}

import XCTest
@testable import Abundance

/// Automated tests generated from spec document assertions
/// These tests verify that implementation matches specification
class SpecAssertionTests: XCTestCase {{

{test_cases}
}}
'''


def generate_manual_checklist(assertions: List[SpecAssertion]) -> str:
    """Generate manual testing checklist"""

    # Group assertions by spec document
    by_spec: Dict[str, List[SpecAssertion]] = {}
    for assertion in assertions:
        if assertion.spec_name not in by_spec:
            by_spec[assertion.spec_name] = []
        by_spec[assertion.spec_name].append(assertion)

    checklist = "# Manual Testing Checklist (Auto-Generated)\n\n"
    checklist += "Generated from spec documents. Use this checklist during manual testing sessions.\n\n"
    checklist += "**Usage**: Build and deploy via `/project:device-tester`, then work through this checklist.\n\n"
    checklist += "**Capture issues**: If any item fails, tell Claude: 'capture this issue' (reference spec: <spec-name>)\n\n"
    checklist += "---\n\n"

    for spec_name, spec_assertions in sorted(by_spec.items()):
        checklist += f"## {spec_name}\n\n"

        # Group by section
        by_section: Dict[str, List[SpecAssertion]] = {}
        for assertion in spec_assertions:
            section = assertion.section
            if section not in by_section:
                by_section[section] = []
            by_section[section].append(assertion)

        for section, section_assertions in sorted(by_section.items()):
            checklist += f"### {section}\n\n"
            for assertion in section_assertions:
                checklist += assertion.to_checklist_item() + "\n"
            checklist += "\n"

        checklist += "---\n\n"

    return checklist


def main():
    print("🔍 Extracting spec assertions...")
    print(f"   Specs directory: {SPECS_DIR}")

    if not SPECS_DIR.exists():
        print(f"❌ Specs directory not found: {SPECS_DIR}")
        return

    all_assertions: List[SpecAssertion] = []

    # Process all spec documents
    for spec_file in SPECS_DIR.glob("**/*.md"):
        print(f"   Processing: {spec_file.name}")
        assertions = extract_assertions_from_spec(spec_file)
        all_assertions.extend(assertions)
        print(f"     Found {len(assertions)} assertions")

    print(f"\n✅ Extracted {len(all_assertions)} total assertions")

    # Generate outputs
    print("\n📝 Generating outputs...")

    # 1. XCTest file
    TESTS_DIR.mkdir(parents=True, exist_ok=True)
    xctest_file = TESTS_DIR / "SpecAssertionTests.swift"
    with open(xctest_file, 'w') as f:
        f.write(generate_xctest_file(all_assertions))
    print(f"   ✅ Generated: {xctest_file}")

    # 2. Manual testing checklist
    checklist_file = OUTPUT_DIR / "manual-testing-checklist.md"
    with open(checklist_file, 'w') as f:
        f.write(generate_manual_checklist(all_assertions))
    print(f"   ✅ Generated: {checklist_file}")

    # 3. Assertion summary (JSON)
    summary = {
        "total_assertions": len(all_assertions),
        "automated": len([a for a in all_assertions if a.assertion_type == "automated"]),
        "manual": len([a for a in all_assertions if a.assertion_type == "manual"]),
        "by_spec": {}
    }

    for assertion in all_assertions:
        if assertion.spec_name not in summary["by_spec"]:
            summary["by_spec"][assertion.spec_name] = 0
        summary["by_spec"][assertion.spec_name] += 1

    summary_file = OUTPUT_DIR / "spec-assertions-summary.json"
    with open(summary_file, 'w') as f:
        json.dump(summary, f, indent=2)
    print(f"   ✅ Generated: {summary_file}")

    print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("✅ Spec assertion extraction complete!")
    print("")
    print("Next steps:")
    print(f"  1. Review manual checklist: {checklist_file}")
    print(f"  2. Implement automated tests: {xctest_file}")
    print(f"  3. Run tests: swift test")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")


if __name__ == "__main__":
    main()
