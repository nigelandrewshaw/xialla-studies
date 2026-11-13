#!/usr/bin/env python3
"""Wire Vendor/ResearchKit into XiallaStudies.xcodeproj (subproject + Embed & Sign).

Idempotent: safe to re-run after bootstrap. Uses stable ResearchKit target / product IDs
from upstream ResearchKit.xcodeproj (ResearchKit + ResearchKitUI frameworks).
"""

from __future__ import annotations

import hashlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / "XiallaStudies.xcodeproj" / "project.pbxproj"
RK_XCODEPROJ = ROOT / "Vendor" / "ResearchKit" / "ResearchKit.xcodeproj"

# Upstream ResearchKit.xcodeproj IDs (ResearchKit / ResearchKitUI iOS frameworks).
RK_TARGET = "B183A4731A8535D100C76870"
RK_PRODUCT = "B183A5951A8535D100C76870"
RKUI_TARGET = "CA1C7A40288B0C68004DAB3A"
RKUI_PRODUCT = "CA1C7A5A288B0C68004DAB3A"

MARKER = "/* Begin ResearchKit wiring (scripts/wire_researchkit_xcodeproj.py) */"


def uid(name: str) -> str:
    return hashlib.md5(f"rk.wire.{name}".encode()).hexdigest()[:24].upper()


def main() -> int:
    if not RK_XCODEPROJ.is_dir():
        print(
            f"Missing {RK_XCODEPROJ}. Run scripts/bootstrap-researchkit.sh first.",
            file=sys.stderr,
        )
        return 1
    if not PBX.is_file():
        print(f"Missing {PBX}", file=sys.stderr)
        return 1

    text = PBX.read_text(encoding="utf-8")
    if MARKER in text or "Vendor/ResearchKit/ResearchKit.xcodeproj" in text:
        print("ResearchKit already wired into XiallaStudies.xcodeproj — skipping.")
        return 0

    # Stable local IDs for this wiring.
    rk_proj_ref = uid("proj.ref")
    rk_products_group = uid("products.group")
    vendor_group = uid("vendor.group")

    rk_proxy_product = uid("proxy.product.rk")
    rkui_proxy_product = uid("proxy.product.rkui")
    rk_ref_proxy = uid("refproxy.rk")
    rkui_ref_proxy = uid("refproxy.rkui")

    rk_proxy_target = uid("proxy.target.rk")
    rkui_proxy_target = uid("proxy.target.rkui")
    rk_dep = uid("dep.rk")
    rkui_dep = uid("dep.rkui")

    rk_build_fw = uid("build.fw.rk")
    rkui_build_fw = uid("build.fw.rkui")
    rk_build_embed = uid("build.embed.rk")
    rkui_build_embed = uid("build.embed.rkui")
    embed_phase = uid("phase.embed")

    # Locate app target id from generated project.
    m = re.search(
        r"([A-F0-9]{24}) /\* XiallaStudies \*/ = \{\s*isa = PBXNativeTarget;",
        text,
    )
    if not m:
        print("Could not find XiallaStudies PBXNativeTarget", file=sys.stderr)
        return 1
    app_target = m.group(1)

    frameworks_phase_m = re.search(
        r"([A-F0-9]{24}) /\* Frameworks \*/ = \{\s*isa = PBXFrameworksBuildPhase;",
        text,
    )
    if not frameworks_phase_m:
        print("Could not find Frameworks build phase", file=sys.stderr)
        return 1
    frameworks_phase = frameworks_phase_m.group(1)

    main_group_m = re.search(r"mainGroup = ([A-F0-9]{24});", text)
    if not main_group_m:
        print("Could not find mainGroup", file=sys.stderr)
        return 1
    main_group = main_group_m.group(1)

    block = f"""
{MARKER}
		{rk_build_fw} /* ResearchKit.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {rk_ref_proxy} /* ResearchKit.framework */; }};
		{rkui_build_fw} /* ResearchKitUI.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {rkui_ref_proxy} /* ResearchKitUI.framework */; }};
		{rk_build_embed} /* ResearchKit.framework in Embed Frameworks */ = {{isa = PBXBuildFile; fileRef = {rk_ref_proxy} /* ResearchKit.framework */; settings = {{ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }}; }};
		{rkui_build_embed} /* ResearchKitUI.framework in Embed Frameworks */ = {{isa = PBXBuildFile; fileRef = {rkui_ref_proxy} /* ResearchKitUI.framework */; settings = {{ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }}; }};
		{rk_proj_ref} /* ResearchKit.xcodeproj */ = {{isa = PBXFileReference; lastKnownFileType = "wrapper.pb-project"; name = ResearchKit.xcodeproj; path = Vendor/ResearchKit/ResearchKit.xcodeproj; sourceTree = "<group>"; }};
		{vendor_group} /* Vendor */ = {{
			isa = PBXGroup;
			children = (
				{rk_proj_ref} /* ResearchKit.xcodeproj */,
			);
			name = Vendor;
			sourceTree = "<group>";
		}};
		{rk_products_group} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{rk_ref_proxy} /* ResearchKit.framework */,
				{rkui_ref_proxy} /* ResearchKitUI.framework */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
		{rk_proxy_product} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {rk_proj_ref} /* ResearchKit.xcodeproj */;
			proxyType = 2;
			remoteGlobalIDString = {RK_PRODUCT};
			remoteInfo = ResearchKit;
		}};
		{rkui_proxy_product} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {rk_proj_ref} /* ResearchKit.xcodeproj */;
			proxyType = 2;
			remoteGlobalIDString = {RKUI_PRODUCT};
			remoteInfo = ResearchKitUI;
		}};
		{rk_proxy_target} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {rk_proj_ref} /* ResearchKit.xcodeproj */;
			proxyType = 1;
			remoteGlobalIDString = {RK_TARGET};
			remoteInfo = ResearchKit;
		}};
		{rkui_proxy_target} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {rk_proj_ref} /* ResearchKit.xcodeproj */;
			proxyType = 1;
			remoteGlobalIDString = {RKUI_TARGET};
			remoteInfo = ResearchKitUI;
		}};
		{rk_ref_proxy} /* ResearchKit.framework */ = {{
			isa = PBXReferenceProxy;
			fileType = wrapper.framework;
			path = ResearchKit.framework;
			remoteRef = {rk_proxy_product} /* PBXContainerItemProxy */;
			sourceTree = BUILT_PRODUCTS_DIR;
		}};
		{rkui_ref_proxy} /* ResearchKitUI.framework */ = {{
			isa = PBXReferenceProxy;
			fileType = wrapper.framework;
			path = ResearchKitUI.framework;
			remoteRef = {rkui_proxy_product} /* PBXContainerItemProxy */;
			sourceTree = BUILT_PRODUCTS_DIR;
		}};
		{rk_dep} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			name = ResearchKit;
			targetProxy = {rk_proxy_target} /* PBXContainerItemProxy */;
		}};
		{rkui_dep} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			name = ResearchKitUI;
			targetProxy = {rkui_proxy_target} /* PBXContainerItemProxy */;
		}};
		{embed_phase} /* Embed Frameworks */ = {{
			isa = PBXCopyFilesBuildPhase;
			buildActionMask = 2147483647;
			dstPath = "";
			dstSubfolderSpec = 10;
			files = (
				{rk_build_embed} /* ResearchKit.framework in Embed Frameworks */,
				{rkui_build_embed} /* ResearchKitUI.framework in Embed Frameworks */,
			);
			name = "Embed Frameworks";
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End ResearchKit wiring */
"""

    # Insert wiring objects just after Begin PBXBuildFile (as a sibling objects chunk).
    text = text.replace(
        "/* Begin PBXBuildFile section */",
        "/* Begin PBXBuildFile section */\n" + block,
        1,
    )

    # Add Vendor to main group children.
    text = re.sub(
        rf"({main_group} = \{{\s*isa = PBXGroup;\s*children = \()",
        rf"\1\n\t\t\t\t{vendor_group} /* Vendor */,",
        text,
        count=1,
    )

    # Add Frameworks build files.
    text = re.sub(
        rf"({frameworks_phase} /\* Frameworks \*/ = \{{\s*isa = PBXFrameworksBuildPhase;\s*buildActionMask = 2147483647;\s*files = \()",
        rf"\1\n\t\t\t\t{rk_build_fw} /* ResearchKit.framework in Frameworks */,\n\t\t\t\t{rkui_build_fw} /* ResearchKitUI.framework in Frameworks */,",
        text,
        count=1,
    )

    # Add Embed Frameworks phase + target dependencies on app target.
    text = re.sub(
        rf"({app_target} /\* XiallaStudies \*/ = \{{\s*isa = PBXNativeTarget;.*?buildPhases = \()",
        rf"\1\n\t\t\t\t{embed_phase} /* Embed Frameworks */,",
        text,
        count=1,
        flags=re.S,
    )
    text = re.sub(
        rf"({app_target} /\* XiallaStudies \*/ = \{{\s*isa = PBXNativeTarget;.*?dependencies = \()",
        rf"\1\n\t\t\t\t{rk_dep} /* PBXTargetDependency */,\n\t\t\t\t{rkui_dep} /* PBXTargetDependency */,",
        text,
        count=1,
        flags=re.S,
    )

    # Add projectReferences to PBXProject.
    if "projectReferences = (" not in text:
        text = text.replace(
            'projectDirPath = "";',
            f"""projectDirPath = "";
\t\t\tprojectReferences = (
\t\t\t\t{{
\t\t\t\t\tProductGroup = {rk_products_group} /* Products */;
\t\t\t\t\tProjectRef = {rk_proj_ref} /* ResearchKit.xcodeproj */;
\t\t\t\t}},
\t\t\t);""",
            1,
        )

    PBX.write_text(text, encoding="utf-8")
    print(f"Wired ResearchKit + ResearchKitUI into {PBX}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
