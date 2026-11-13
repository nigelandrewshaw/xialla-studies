#!/usr/bin/env python3
"""Generate a minimal XiallaStudies.xcodeproj/project.pbxproj (no Mac/Xcode required)."""

from __future__ import annotations

import hashlib
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "XiallaStudies.xcodeproj" / "project.pbxproj"


def uid(name: str) -> str:
    return hashlib.md5(name.encode()).hexdigest()[:24].upper()


def main() -> None:
    swift_files = sorted((ROOT / "XiallaStudies").rglob("*.swift"))
    test_files = sorted((ROOT / "XiallaStudiesTests").rglob("*.swift"))
    asset = ROOT / "XiallaStudies" / "Resources" / "Assets.xcassets"
    info = ROOT / "XiallaStudies" / "Supporting" / "Info.plist"

    project_id = uid("project")
    target_id = uid("target.app")
    test_target_id = uid("target.tests")
    sources_phase = uid("phase.sources")
    resources_phase = uid("phase.resources")
    frameworks_phase = uid("phase.frameworks")
    test_sources_phase = uid("phase.testSources")
    project_config_list = uid("pcl.project")
    target_config_list = uid("pcl.target")
    test_config_list = uid("pcl.tests")
    debug_proj = uid("cfg.proj.debug")
    release_proj = uid("cfg.proj.release")
    debug_app = uid("cfg.app.debug")
    release_app = uid("cfg.app.release")
    debug_test = uid("cfg.test.debug")
    release_test = uid("cfg.test.release")
    main_group = uid("group.main")
    products_group = uid("group.products")
    app_group = uid("group.app")
    tests_group = uid("group.tests")
    product_ref = uid("product.app")
    test_product_ref = uid("product.tests")
    asset_ref = uid("file.assets")
    info_ref = uid("file.info")

    file_refs: dict[Path, str] = {}
    build_files: dict[Path, str] = {}

    for path in swift_files + test_files:
        rel = path.relative_to(ROOT)
        file_refs[path] = uid(f"ref.{rel}")
        build_files[path] = uid(f"build.{rel}")

    lines: list[str] = []
    w = lines.append

    w("// !$*UTF8*$!")
    w("{")
    w("\tarchiveVersion = 1;")
    w("\tclasses = {};")
    w("\tobjectVersion = 56;")
    w("\tobjects = {")
    w("")

    w("/* Begin PBXBuildFile section */")
    for path in swift_files:
        rel = path.relative_to(ROOT)
        w(
            f"\t\t{build_files[path]} /* {path.name} in Sources */ = "
            f"{{isa = PBXBuildFile; fileRef = {file_refs[path]} /* {path.name} */; }};"
        )
    for path in test_files:
        w(
            f"\t\t{build_files[path]} /* {path.name} in Sources */ = "
            f"{{isa = PBXBuildFile; fileRef = {file_refs[path]} /* {path.name} */; }};"
        )
    asset_build = uid("build.assets")
    w(
        f"\t\t{asset_build} /* Assets.xcassets in Resources */ = "
        f"{{isa = PBXBuildFile; fileRef = {asset_ref} /* Assets.xcassets */; }};"
    )
    w("/* End PBXBuildFile section */")
    w("")

    w("/* Begin PBXFileReference section */")
    w(
        f"\t\t{product_ref} /* XiallaStudies.app */ = "
        "{isa = PBXFileReference; explicitFileType = wrapper.application; "
        "includeInIndex = 0; path = XiallaStudies.app; sourceTree = BUILT_PRODUCTS_DIR; };"
    )
    w(
        f"\t\t{test_product_ref} /* XiallaStudiesTests.xctest */ = "
        "{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; "
        "includeInIndex = 0; path = XiallaStudiesTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };"
    )
    for path in swift_files + test_files:
        rel = path.relative_to(ROOT)
        w(
            f"\t\t{file_refs[path]} /* {path.name} */ = "
            f"{{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; "
            f"path = {path.name}; sourceTree = \"<group>\"; }};"
        )
    w(
        f"\t\t{asset_ref} /* Assets.xcassets */ = "
        "{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; "
        "path = Assets.xcassets; sourceTree = \"<group>\"; };"
    )
    w(
        f"\t\t{info_ref} /* Info.plist */ = "
        "{isa = PBXFileReference; lastKnownFileType = text.plist.xml; "
        "path = Info.plist; sourceTree = \"<group>\"; };"
    )
    w("/* End PBXFileReference section */")
    w("")

    # Groups — flat listing under logical folders for simplicity
    def group_id(key: str) -> str:
        return uid(f"group.{key}")

    # Build nested groups by directory under XiallaStudies
    dir_to_files: dict[Path, list[Path]] = {}
    for path in swift_files:
        dir_to_files.setdefault(path.parent, []).append(path)

    w("/* Begin PBXGroup section */")
    w(f"\t\t{main_group} = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    w(f"\t\t\t\t{app_group} /* XiallaStudies */,")
    w(f"\t\t\t\t{tests_group} /* XiallaStudiesTests */,")
    w(f"\t\t\t\t{products_group} /* Products */,")
    w("\t\t\t);")
    w('\t\t\tsourceTree = "<group>";')
    w("\t\t};")

    w(f"\t\t{products_group} /* Products */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    w(f"\t\t\t\t{product_ref} /* XiallaStudies.app */,")
    w(f"\t\t\t\t{test_product_ref} /* XiallaStudiesTests.xctest */,")
    w("\t\t\t);")
    w("\t\t\tname = Products;")
    w('\t\t\tsourceTree = "<group>";')
    w("\t\t};")

    # App root group children = top-level folders + Resources/Supporting refs
    top_dirs = sorted({p.relative_to(ROOT / "XiallaStudies").parts[0] for p in swift_files})
    top_group_ids = {name: group_id(f"app.{name}") for name in top_dirs}

    w(f"\t\t{app_group} /* XiallaStudies */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    for name in top_dirs:
        w(f"\t\t\t\t{top_group_ids[name]} /* {name} */,")
    w("\t\t\t);")
    w("\t\t\tpath = XiallaStudies;")
    w('\t\t\tsourceTree = "<group>";')
    w("\t\t};")

    # For each top-level folder, either list files or nested Feature folders
    for name in top_dirs:
        base = ROOT / "XiallaStudies" / name
        children_dirs = sorted({p.parent for p in swift_files if p.is_relative_to(base) and p.parent != base})
        files_here = [p for p in swift_files if p.parent == base]

        w(f"\t\t{top_group_ids[name]} /* {name} */ = {{")
        w("\t\t\tisa = PBXGroup;")
        w("\t\t\tchildren = (")
        if name == "Resources":
            w(f"\t\t\t\t{asset_ref} /* Assets.xcassets */,")
        if name == "Supporting":
            w(f"\t\t\t\t{info_ref} /* Info.plist */,")
        # nested relative groups
        nested = {}
        for d in children_dirs:
            rel = d.relative_to(base)
            nested[rel] = group_id(f"app.{name}.{rel}")
            w(f"\t\t\t\t{nested[rel]} /* {rel.as_posix()} */,")
        for f in files_here:
            w(f"\t\t\t\t{file_refs[f]} /* {f.name} */,")
        w("\t\t\t);")
        w(f"\t\t\tpath = {name};")
        w('\t\t\tsourceTree = "<group>";')
        w("\t\t};")

        for d in children_dirs:
            rel = d.relative_to(base)
            files = [p for p in swift_files if p.parent == d]
            # also deeper?
            deeper = sorted({p.parent for p in swift_files if p.is_relative_to(d) and p.parent != d})
            gid = nested[rel]
            w(f"\t\t{gid} /* {rel.as_posix()} */ = {{")
            w("\t\t\tisa = PBXGroup;")
            w("\t\t\tchildren = (")
            for dd in deeper:
                drel = dd.relative_to(d)
                dgid = group_id(f"app.{name}.{rel}.{drel}")
                nested[rel / drel] = dgid
                w(f"\t\t\t\t{dgid} /* {drel.as_posix()} */,")
            for f in files:
                w(f"\t\t\t\t{file_refs[f]} /* {f.name} */,")
            w("\t\t\t);")
            w(f"\t\t\tpath = {d.name};")
            w('\t\t\tsourceTree = "<group>";')
            w("\t\t};")

            for dd in deeper:
                drel = dd.relative_to(d)
                files2 = [p for p in swift_files if p.parent == dd]
                dgid = nested[rel / drel]
                w(f"\t\t{dgid} /* {drel.as_posix()} */ = {{")
                w("\t\t\tisa = PBXGroup;")
                w("\t\t\tchildren = (")
                for f in files2:
                    w(f"\t\t\t\t{file_refs[f]} /* {f.name} */,")
                w("\t\t\t);")
                w(f"\t\t\tpath = {dd.name};")
                w('\t\t\tsourceTree = "<group>";')
                w("\t\t};")

    w(f"\t\t{tests_group} /* XiallaStudiesTests */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    for path in test_files:
        w(f"\t\t\t\t{file_refs[path]} /* {path.name} */,")
    w("\t\t\t);")
    w("\t\t\tpath = XiallaStudiesTests;")
    w('\t\t\tsourceTree = "<group>";')
    w("\t\t};")
    w("/* End PBXGroup section */")
    w("")

    w("/* Begin PBXNativeTarget section */")
    w(f"\t\t{target_id} /* XiallaStudies */ = {{")
    w("\t\t\tisa = PBXNativeTarget;")
    w(f"\t\t\tbuildConfigurationList = {target_config_list} /* Build configuration list for PBXNativeTarget \"XiallaStudies\" */;")
    w("\t\t\tbuildPhases = (")
    w(f"\t\t\t\t{sources_phase} /* Sources */,")
    w(f"\t\t\t\t{frameworks_phase} /* Frameworks */,")
    w(f"\t\t\t\t{resources_phase} /* Resources */,")
    w("\t\t\t);")
    w("\t\t\tbuildRules = (")
    w("\t\t\t);")
    w("\t\t\tdependencies = (")
    w("\t\t\t);")
    w("\t\t\tname = XiallaStudies;")
    w("\t\t\tproductName = XiallaStudies;")
    w(f"\t\t\tproductReference = {product_ref} /* XiallaStudies.app */;")
    w("\t\t\tproductType = \"com.apple.product-type.application\";")
    w("\t\t};")

    w(f"\t\t{test_target_id} /* XiallaStudiesTests */ = {{")
    w("\t\t\tisa = PBXNativeTarget;")
    w(f"\t\t\tbuildConfigurationList = {test_config_list} /* Build configuration list for PBXNativeTarget \"XiallaStudiesTests\" */;")
    w("\t\t\tbuildPhases = (")
    w(f"\t\t\t\t{test_sources_phase} /* Sources */,")
    w("\t\t\t);")
    w("\t\t\tbuildRules = (")
    w("\t\t\t);")
    w("\t\t\tdependencies = (")
    w(f"\t\t\t\t{uid('dep.tests')} /* PBXTargetDependency */,")
    w("\t\t\t);")
    w("\t\t\tname = XiallaStudiesTests;")
    w("\t\t\tproductName = XiallaStudiesTests;")
    w(f"\t\t\tproductReference = {test_product_ref} /* XiallaStudiesTests.xctest */;")
    w("\t\t\tproductType = \"com.apple.product-type.bundle.unit-test\";")
    w("\t\t};")
    w("/* End PBXNativeTarget section */")
    w("")

    w("/* Begin PBXProject section */")
    w(f"\t\t{project_id} /* Project object */ = {{")
    w("\t\t\tisa = PBXProject;")
    w("\t\t\tattributes = {")
    w("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    w('\t\t\t\tLastSwiftUpdateCheck = 1600;')
    w("\t\t\t\tLastUpgradeCheck = 1600;")
    w("\t\t\t\tTargetAttributes = {")
    w(f"\t\t\t\t\t{target_id} = {{")
    w("\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;")
    w("\t\t\t\t\t};")
    w(f"\t\t\t\t\t{test_target_id} = {{")
    w("\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;")
    w("\t\t\t\t\t\tTestTargetID = " + target_id + ";")
    w("\t\t\t\t\t};")
    w("\t\t\t\t};")
    w("\t\t\t};")
    w(f"\t\t\tbuildConfigurationList = {project_config_list} /* Build configuration list for PBXProject \"XiallaStudies\" */;")
    w('\t\t\tcompatibilityVersion = "Xcode 15.0";')
    w("\t\t\tdevelopmentRegion = en;")
    w("\t\t\thasScannedForEncodings = 0;")
    w("\t\t\tknownRegions = (")
    w("\t\t\t\ten,")
    w("\t\t\t\tBase,")
    w("\t\t\t);")
    w(f"\t\t\tmainGroup = {main_group};")
    w(f"\t\t\tproductRefGroup = {products_group} /* Products */;")
    w('\t\t\tprojectDirPath = "";')
    w('\t\t\tprojectRoot = "";')
    w("\t\t\ttargets = (")
    w(f"\t\t\t\t{target_id} /* XiallaStudies */,")
    w(f"\t\t\t\t{test_target_id} /* XiallaStudiesTests */,")
    w("\t\t\t);")
    w("\t\t};")
    w("/* End PBXProject section */")
    w("")

    w("/* Begin PBXResourcesBuildPhase section */")
    w(f"\t\t{resources_phase} /* Resources */ = {{")
    w("\t\t\tisa = PBXResourcesBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    w(f"\t\t\t\t{asset_build} /* Assets.xcassets in Resources */,")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXResourcesBuildPhase section */")
    w("")

    w("/* Begin PBXFrameworksBuildPhase section */")
    w(f"\t\t{frameworks_phase} /* Frameworks */ = {{")
    w("\t\t\tisa = PBXFrameworksBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXFrameworksBuildPhase section */")
    w("")

    w("/* Begin PBXSourcesBuildPhase section */")
    w(f"\t\t{sources_phase} /* Sources */ = {{")
    w("\t\t\tisa = PBXSourcesBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    for path in swift_files:
        w(f"\t\t\t\t{build_files[path]} /* {path.name} in Sources */,")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")

    w(f"\t\t{test_sources_phase} /* Sources */ = {{")
    w("\t\t\tisa = PBXSourcesBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    for path in test_files:
        w(f"\t\t\t\t{build_files[path]} /* {path.name} in Sources */,")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXSourcesBuildPhase section */")
    w("")

    container_proxy = uid("proxy.tests")
    target_dep = uid("dep.tests")
    w("/* Begin PBXContainerItemProxy section */")
    w(f"\t\t{container_proxy} /* PBXContainerItemProxy */ = {{")
    w("\t\t\tisa = PBXContainerItemProxy;")
    w(f"\t\t\tcontainerPortal = {project_id} /* Project object */;")
    w("\t\t\tproxyType = 1;")
    w(f"\t\t\tremoteGlobalIDString = {target_id};")
    w('\t\t\tremoteInfo = XiallaStudies;')
    w("\t\t};")
    w("/* End PBXContainerItemProxy section */")
    w("")

    w("/* Begin PBXTargetDependency section */")
    w(f"\t\t{target_dep} /* PBXTargetDependency */ = {{")
    w("\t\t\tisa = PBXTargetDependency;")
    w("\t\t\ttarget = " + target_id + " /* XiallaStudies */;")
    w(f"\t\t\ttargetProxy = {container_proxy} /* PBXContainerItemProxy */;")
    w("\t\t};")
    w("/* End PBXTargetDependency section */")
    w("")

    def cfg(oid: str, name: str, extra: dict[str, str]) -> None:
        w(f"\t\t{oid} /* {name} */ = {{")
        w("\t\t\tisa = XCBuildConfiguration;")
        w("\t\t\tbuildSettings = {")
        for k, v in extra.items():
            w(f"\t\t\t\t{k} = {v};")
        w("\t\t\t};")
        w(f"\t\t\tname = {name};")
        w("\t\t};")

    common_proj = {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "COPY_PHASE_STRIP": "NO",
        "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
        "GCC_DYNAMIC_NO_PIC": "NO",
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        "SDKROOT": "iphoneos",
        "SWIFT_VERSION": "5.0",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    }

    w("/* Begin XCBuildConfiguration section */")
    cfg(
        debug_proj,
        "Debug",
        {
            **common_proj,
            "DEBUG_INFORMATION_FORMAT": "dwarf",
            "GCC_OPTIMIZATION_LEVEL": "0",
            "ONLY_ACTIVE_ARCH": "YES",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
            "SWIFT_OPTIMIZATION_LEVEL": '"-Onone"',
        },
    )
    cfg(release_proj, "Release", {**common_proj, "SWIFT_COMPILATION_MODE": "wholemodule"})
    cfg(
        debug_app,
        "Debug",
        {
            "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            "CODE_SIGN_STYLE": "Automatic",
            "CURRENT_PROJECT_VERSION": "1",
            "DEVELOPMENT_TEAM": '""',
            "GENERATE_INFOPLIST_FILE": "NO",
            "INFOPLIST_FILE": "XiallaStudies/Supporting/Info.plist",
            "LD_RUNPATH_SEARCH_PATHS": '"$(inherited) @executable_path/Frameworks"',
            "MARKETING_VERSION": "0.1.0",
            "PRODUCT_BUNDLE_IDENTIFIER": "com.xialla.studies",
            "PRODUCT_NAME": '"$(TARGET_NAME)"',
            "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
            "SUPPORTS_MACCATALYST": "NO",
            "SWIFT_EMIT_LOC_STRINGS": "YES",
            "TARGETED_DEVICE_FAMILY": '"1,2"',
        },
    )
    cfg(
        release_app,
        "Release",
        {
            "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            "CODE_SIGN_STYLE": "Automatic",
            "CURRENT_PROJECT_VERSION": "1",
            "DEVELOPMENT_TEAM": '""',
            "GENERATE_INFOPLIST_FILE": "NO",
            "INFOPLIST_FILE": "XiallaStudies/Supporting/Info.plist",
            "LD_RUNPATH_SEARCH_PATHS": '"$(inherited) @executable_path/Frameworks"',
            "MARKETING_VERSION": "0.1.0",
            "PRODUCT_BUNDLE_IDENTIFIER": "com.xialla.studies",
            "PRODUCT_NAME": '"$(TARGET_NAME)"',
            "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
            "SUPPORTS_MACCATALYST": "NO",
            "SWIFT_EMIT_LOC_STRINGS": "YES",
            "TARGETED_DEVICE_FAMILY": '"1,2"',
        },
    )
    cfg(
        debug_test,
        "Debug",
        {
            "BUNDLE_LOADER": '"$(TEST_HOST)"',
            "CODE_SIGN_STYLE": "Automatic",
            "CURRENT_PROJECT_VERSION": "1",
            "GENERATE_INFOPLIST_FILE": "YES",
            "MARKETING_VERSION": "0.1.0",
            "PRODUCT_BUNDLE_IDENTIFIER": "com.xialla.studies.tests",
            "PRODUCT_NAME": '"$(TARGET_NAME)"',
            "TARGETED_DEVICE_FAMILY": '"1,2"',
            "TEST_HOST": '"$(BUILT_PRODUCTS_DIR)/XiallaStudies.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/XiallaStudies"',
        },
    )
    cfg(
        release_test,
        "Release",
        {
            "BUNDLE_LOADER": '"$(TEST_HOST)"',
            "CODE_SIGN_STYLE": "Automatic",
            "CURRENT_PROJECT_VERSION": "1",
            "GENERATE_INFOPLIST_FILE": "YES",
            "MARKETING_VERSION": "0.1.0",
            "PRODUCT_BUNDLE_IDENTIFIER": "com.xialla.studies.tests",
            "PRODUCT_NAME": '"$(TARGET_NAME)"',
            "TARGETED_DEVICE_FAMILY": '"1,2"',
            "TEST_HOST": '"$(BUILT_PRODUCTS_DIR)/XiallaStudies.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/XiallaStudies"',
        },
    )
    w("/* End XCBuildConfiguration section */")
    w("")

    def cfg_list(oid: str, label: str, debug_id: str, release_id: str) -> None:
        w(f"\t\t{oid} /* Build configuration list for {label} */ = {{")
        w("\t\t\tisa = XCConfigurationList;")
        w("\t\t\tbuildConfigurations = (")
        w(f"\t\t\t\t{debug_id} /* Debug */,")
        w(f"\t\t\t\t{release_id} /* Release */,")
        w("\t\t\t);")
        w("\t\t\tdefaultConfigurationIsVisible = 0;")
        w("\t\t\tdefaultConfigurationName = Release;")
        w("\t\t};")

    w("/* Begin XCConfigurationList section */")
    cfg_list(project_config_list, 'PBXProject "XiallaStudies"', debug_proj, release_proj)
    cfg_list(target_config_list, 'PBXNativeTarget "XiallaStudies"', debug_app, release_app)
    cfg_list(test_config_list, 'PBXNativeTarget "XiallaStudiesTests"', debug_test, release_test)
    w("/* End XCConfigurationList section */")
    w("\t};")
    w(f"\trootObject = {project_id} /* Project object */;")
    w("}")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {OUT} ({len(swift_files)} app sources, {len(test_files)} tests)")


if __name__ == "__main__":
    # Path.is_relative_to is 3.9+; ensure available
    main()
