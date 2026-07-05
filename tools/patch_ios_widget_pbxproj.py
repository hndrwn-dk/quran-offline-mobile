#!/usr/bin/env python3
"""Patch ios/Runner.xcodeproj/project.pbxproj to add QuranBerandaWidget extension."""

from pathlib import Path

PBX = Path(__file__).resolve().parent.parent / "ios" / "Runner.xcodeproj" / "project.pbxproj"
text = PBX.read_text(encoding="utf-8")

if "QuranBerandaWidgetExtension" in text:
    print("Widget extension already present in project.pbxproj")
    raise SystemExit(0)

# --- PBXBuildFile ---
build_file_insert = """\t\t97C147011CF9000F007C117D /* LaunchScreen.storyboard in Resources */ = {isa = PBXBuildFile; fileRef = 97C146FF1CF9000F007C117D /* LaunchScreen.storyboard */; };
\t\tE7B1000B2BCD43700ED5F59 /* QuranBerandaWidget.swift in Sources */ = {isa = PBXBuildFile; fileRef = E7B100022BCD43700ED5F59 /* QuranBerandaWidget.swift */; };
\t\tE7B100132BCD43900ED5F59 /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = E7B100042BCD43900ED5F59 /* Assets.xcassets */; };
\t\tE7B100182BCD43700ED5F59 /* WidgetKit.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = E7B100072BCD43700ED5F59 /* WidgetKit.framework */; };
\t\tE7B100192BCD43700ED5F59 /* SwiftUI.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = E7B100082BCD43700ED5F59 /* SwiftUI.framework */; };
\t\tE7B1000C2BCD43900ED5F59 /* QuranBerandaWidgetExtension.appex in Embed Foundation Extensions */ = {isa = PBXBuildFile; fileRef = E7B100012BCD43700ED5F59 /* QuranBerandaWidgetExtension.appex */; settings = {ATTRIBUTES = (RemoveHeadersOnCopy, ); }; };
/* End PBXBuildFile section */"""

text = text.replace(
    "\t\t97C147011CF9000F007C117D /* LaunchScreen.storyboard in Resources */ = {isa = PBXBuildFile; fileRef = 97C146FF1CF9000F007C117D /* LaunchScreen.storyboard */; };\n/* End PBXBuildFile section */",
    build_file_insert,
)

# --- PBXContainerItemProxy ---
proxy_insert = """\t\t331C8085294A63A400263BE5 /* PBXContainerItemProxy */ = {
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = 97C146E61CF9000F007C117D /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = 97C146ED1CF9000F007C117D;
\t\t\tremoteInfo = Runner;
\t\t};
\t\tE7B1000E2BCD43900ED5F59 /* PBXContainerItemProxy */ = {
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = 97C146E61CF9000F007C117D /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = E7B1000A2BCD43700ED5F59;
\t\t\tremoteInfo = QuranBerandaWidgetExtension;
\t\t};
/* End PBXContainerItemProxy section */"""

text = text.replace(
    "\t\t331C8085294A63A400263BE5 /* PBXContainerItemProxy */ = {\n\t\t\tisa = PBXContainerItemProxy;\n\t\t\tcontainerPortal = 97C146E61CF9000F007C117D /* Project object */;\n\t\t\tproxyType = 1;\n\t\t\tremoteGlobalIDString = 97C146ED1CF9000F007C117D;\n\t\t\tremoteInfo = Runner;\n\t\t};\n/* End PBXContainerItemProxy section */",
    proxy_insert,
)

# --- PBXCopyFilesBuildPhase ---
embed_insert = """\t\t9705A1C41CF9048500538489 /* Embed Frameworks */ = {
\t\t\tisa = PBXCopyFilesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tdstPath = "";
\t\t\tdstSubfolderSpec = 10;
\t\t\tfiles = (
\t\t\t);
\t\t\tname = "Embed Frameworks";
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
\t\tE7B1000D2BCD43900ED5F59 /* Embed Foundation Extensions */ = {
\t\t\tisa = PBXCopyFilesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tdstPath = "";
\t\t\tdstSubfolderSpec = 13;
\t\t\tfiles = (
\t\t\t\tE7B1000C2BCD43900ED5F59 /* QuranBerandaWidgetExtension.appex in Embed Foundation Extensions */,
\t\t\t);
\t\t\tname = "Embed Foundation Extensions";
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
/* End PBXCopyFilesBuildPhase section */"""

text = text.replace(
    "\t\t9705A1C41CF9048500538489 /* Embed Frameworks */ = {\n\t\t\tisa = PBXCopyFilesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tdstPath = \"\";\n\t\t\tdstSubfolderSpec = 10;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\tname = \"Embed Frameworks\";\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n/* End PBXCopyFilesBuildPhase section */",
    embed_insert,
)

# --- PBXFileReference ---
file_ref_insert = """\t\t97C147021CF9000F007C117D /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };
\t\tE7B100012BCD43700ED5F59 /* QuranBerandaWidgetExtension.appex */ = {isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = QuranBerandaWidgetExtension.appex; sourceTree = BUILT_PRODUCTS_DIR; };
\t\tE7B100022BCD43700ED5F59 /* QuranBerandaWidget.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = QuranBerandaWidget.swift; sourceTree = "<group>"; };
\t\tE7B100032BCD43700ED5F59 /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };
\t\tE7B100042BCD43900ED5F59 /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };
\t\tE7B100052BCD46500ED5F59 /* QuranBerandaWidgetExtension.entitlements */ = {isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = QuranBerandaWidgetExtension.entitlements; sourceTree = "<group>"; };
\t\tE7B100062BCD40B00ED5F59 /* Runner.entitlements */ = {isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = Runner.entitlements; sourceTree = "<group>"; };
\t\tE7B100072BCD43700ED5F59 /* WidgetKit.framework */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = WidgetKit.framework; path = System/Library/Frameworks/WidgetKit.framework; sourceTree = SDKROOT; };
\t\tE7B100082BCD43700ED5F59 /* SwiftUI.framework */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = SwiftUI.framework; path = System/Library/Frameworks/SwiftUI.framework; sourceTree = SDKROOT; };
/* End PBXFileReference section */"""

text = text.replace(
    "\t\t97C147021CF9000F007C117D /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; };\n/* End PBXFileReference section */",
    file_ref_insert,
)

# --- PBXFrameworksBuildPhase for widget ---
fw_insert = """\t\t97C146EB1CF9000F007C117D /* Frameworks */ = {
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
\t\tE7B100112BCD43700ED5F59 /* Frameworks */ = {
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\tE7B100182BCD43700ED5F59 /* WidgetKit.framework in Frameworks */,
\t\t\t\tE7B100192BCD43700ED5F59 /* SwiftUI.framework in Frameworks */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
/* End PBXFrameworksBuildPhase section */"""

text = text.replace(
    "\t\t97C146EB1CF9000F007C117D /* Frameworks */ = {\n\t\t\tisa = PBXFrameworksBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n/* End PBXFrameworksBuildPhase section */",
    fw_insert,
)

# --- PBXGroup ---
group_insert = """\t\t97C146E51CF9000F007C117D = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t9740EEB11CF90186004384FC /* Flutter */,
\t\t\t\t97C146F01CF9000F007C117D /* Runner */,
\t\t\t\tE7B100092BCD43700ED5F59 /* QuranBerandaWidget */,
\t\t\t\tE7B100052BCD46500ED5F59 /* QuranBerandaWidgetExtension.entitlements */,
\t\t\t\t97C146EF1CF9000F007C117D /* Products */,
\t\t\t\t331C8082294A63A400263BE5 /* RunnerTests */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t};
\t\t97C146EF1CF9000F007C117D /* Products */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t97C146EE1CF9000F007C117D /* Runner.app */,
\t\t\t\tE7B100012BCD43700ED5F59 /* QuranBerandaWidgetExtension.appex */,
\t\t\t\t331C8081294A63A400263BE5 /* RunnerTests.xctest */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t};
\t\t97C146F01CF9000F007C117D /* Runner */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t97C146FA1CF9000F007C117D /* Main.storyboard */,
\t\t\t\t97C146FD1CF9000F007C117D /* Assets.xcassets */,
\t\t\t\t97C146FF1CF9000F007C117D /* LaunchScreen.storyboard */,
\t\t\t\t97C147021CF9000F007C117D /* Info.plist */,
\t\t\t\tE7B100062BCD40B00ED5F59 /* Runner.entitlements */,
\t\t\t\t1498D2321E8E86230040F4C2 /* GeneratedPluginRegistrant.h */,
\t\t\t\t1498D2331E8E89220040F4C2 /* GeneratedPluginRegistrant.m */,
\t\t\t\t74858FAE1ED2DC5600515810 /* AppDelegate.swift */,
\t\t\t\t74858FAD1ED2DC5600515810 /* Runner-Bridging-Header.h */,
\t\t\t);
\t\t\tpath = Runner;
\t\t\tsourceTree = "<group>";
\t\t};
\t\tE7B100092BCD43700ED5F59 /* QuranBerandaWidget */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\tE7B100022BCD43700ED5F59 /* QuranBerandaWidget.swift */,
\t\t\t\tE7B100032BCD43700ED5F59 /* Info.plist */,
\t\t\t\tE7B100042BCD43900ED5F59 /* Assets.xcassets */,
\t\t\t);
\t\t\tpath = QuranBerandaWidget;
\t\t\tsourceTree = "<group>";
\t\t};
/* End PBXGroup section */"""

text = text.replace(
    "\t\t97C146E51CF9000F007C117D = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t9740EEB11CF90186004384FC /* Flutter */,\n\t\t\t\t97C146F01CF9000F007C117D /* Runner */,\n\t\t\t\t97C146EF1CF9000F007C117D /* Products */,\n\t\t\t\t331C8082294A63A400263BE5 /* RunnerTests */,\n\t\t\t);\n\t\t\tsourceTree = \"<group>\";\n\t\t};\n\t\t97C146EF1CF9000F007C117D /* Products */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t97C146EE1CF9000F007C117D /* Runner.app */,\n\t\t\t\t331C8081294A63A400263BE5 /* RunnerTests.xctest */,\n\t\t\t);\n\t\t\tname = Products;\n\t\t\tsourceTree = \"<group>\";\n\t\t};\n\t\t97C146F01CF9000F007C117D /* Runner */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t97C146FA1CF9000F007C117D /* Main.storyboard */,\n\t\t\t\t97C146FD1CF9000F007C117D /* Assets.xcassets */,\n\t\t\t\t97C146FF1CF9000F007C117D /* LaunchScreen.storyboard */,\n\t\t\t\t97C147021CF9000F007C117D /* Info.plist */,\n\t\t\t\t1498D2321E8E86230040F4C2 /* GeneratedPluginRegistrant.h */,\n\t\t\t\t1498D2331E8E89220040F4C2 /* GeneratedPluginRegistrant.m */,\n\t\t\t\t74858FAE1ED2DC5600515810 /* AppDelegate.swift */,\n\t\t\t\t74858FAD1ED2DC5600515810 /* Runner-Bridging-Header.h */,\n\t\t\t);\n\t\t\tpath = Runner;\n\t\t\tsourceTree = \"<group>\";\n\t\t};\n/* End PBXGroup section */",
    group_insert,
)

# --- PBXNativeTarget widget + Runner deps/phases ---
target_insert = """\t\t97C146ED1CF9000F007C117D /* Runner */ = {
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = 97C147051CF9000F007C117D /* Build configuration list for PBXNativeTarget "Runner" */;
\t\t\tbuildPhases = (
\t\t\t\t9740EEB61CF901F6004384FC /* Run Script */,
\t\t\t\t97C146EA1CF9000F007C117D /* Sources */,
\t\t\t\t97C146EB1CF9000F007C117D /* Frameworks */,
\t\t\t\t97C146EC1CF9000F007C117D /* Resources */,
\t\t\t\t9705A1C41CF9048500538489 /* Embed Frameworks */,
\t\t\t\tE7B1000D2BCD43900ED5F59 /* Embed Foundation Extensions */,
\t\t\t\t3B06AD1E1E4923F5004D2608 /* Thin Binary */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t\tE7B1000F2BCD43900ED5F59 /* PBXTargetDependency */,
\t\t\t);
\t\t\tname = Runner;
\t\t\tproductName = Runner;
\t\t\tproductReference = 97C146EE1CF9000F007C117D /* Runner.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t};
\t\tE7B1000A2BCD43700ED5F59 /* QuranBerandaWidgetExtension */ = {
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = E7B100142BCD43900ED5F59 /* Build configuration list for PBXNativeTarget "QuranBerandaWidgetExtension" */;
\t\t\tbuildPhases = (
\t\t\t\tE7B100102BCD43700ED5F59 /* Sources */,
\t\t\t\tE7B100112BCD43700ED5F59 /* Frameworks */,
\t\t\t\tE7B100122BCD43900ED5F59 /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = QuranBerandaWidgetExtension;
\t\t\tproductName = QuranBerandaWidgetExtension;
\t\t\tproductReference = E7B100012BCD43700ED5F59 /* QuranBerandaWidgetExtension.appex */;
\t\t\tproductType = "com.apple.product-type.app-extension";
\t\t};
/* End PBXNativeTarget section */"""

text = text.replace(
    "\t\t97C146ED1CF9000F007C117D /* Runner */ = {\n\t\t\tisa = PBXNativeTarget;\n\t\t\tbuildConfigurationList = 97C147051CF9000F007C117D /* Build configuration list for PBXNativeTarget \"Runner\" */;\n\t\t\tbuildPhases = (\n\t\t\t\t9740EEB61CF901F6004384FC /* Run Script */,\n\t\t\t\t97C146EA1CF9000F007C117D /* Sources */,\n\t\t\t\t97C146EB1CF9000F007C117D /* Frameworks */,\n\t\t\t\t97C146EC1CF9000F007C117D /* Resources */,\n\t\t\t\t9705A1C41CF9048500538489 /* Embed Frameworks */,\n\t\t\t\t3B06AD1E1E4923F5004D2608 /* Thin Binary */,\n\t\t\t);\n\t\t\tbuildRules = (\n\t\t\t);\n\t\t\tdependencies = (\n\t\t\t);\n\t\t\tname = Runner;\n\t\t\tproductName = Runner;\n\t\t\tproductReference = 97C146EE1CF9000F007C117D /* Runner.app */;\n\t\t\tproductType = \"com.apple.product-type.application\";\n\t\t};\n/* End PBXNativeTarget section */",
    target_insert,
)

# --- PBXProject targets + attributes ---
text = text.replace(
    "\t\t\t\t97C146ED1CF9000F007C117D = {\n\t\t\t\t\tCreatedOnToolsVersion = 7.3.1;\n\t\t\t\t\tLastSwiftMigration = 1100;\n\t\t\t\t};",
    "\t\t\t\t97C146ED1CF9000F007C117D = {\n\t\t\t\t\tCreatedOnToolsVersion = 7.3.1;\n\t\t\t\t\tLastSwiftMigration = 1100;\n\t\t\t\t};\n\t\t\t\tE7B1000A2BCD43700ED5F59 = {\n\t\t\t\t\tCreatedOnToolsVersion = 15.0;\n\t\t\t\t};",
)

text = text.replace(
    "\t\t\ttargets = (\n\t\t\t\t97C146ED1CF9000F007C117D /* Runner */,\n\t\t\t\t331C8080294A63A400263BE5 /* RunnerTests */,\n\t\t\t);",
    "\t\t\ttargets = (\n\t\t\t\t97C146ED1CF9000F007C117D /* Runner */,\n\t\t\t\tE7B1000A2BCD43700ED5F59 /* QuranBerandaWidgetExtension */,\n\t\t\t\t331C8080294A63A400263BE5 /* RunnerTests */,\n\t\t\t);",
)

# --- PBXResourcesBuildPhase widget ---
res_insert = """\t\t97C146EC1CF9000F007C117D /* Resources */ = {
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t97C147011CF9000F007C117D /* LaunchScreen.storyboard in Resources */,
\t\t\t\t3B3967161E833CAA004F5970 /* AppFrameworkInfo.plist in Resources */,
\t\t\t\t97C146FE1CF9000F007C117D /* Assets.xcassets in Resources */,
\t\t\t\t97C146FC1CF9000F007C117D /* Main.storyboard in Resources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
\t\tE7B100122BCD43900ED5F59 /* Resources */ = {
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\tE7B100132BCD43900ED5F59 /* Assets.xcassets in Resources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
/* End PBXResourcesBuildPhase section */"""

text = text.replace(
    "\t\t97C146EC1CF9000F007C117D /* Resources */ = {\n\t\t\tisa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t\t97C147011CF9000F007C117D /* LaunchScreen.storyboard in Resources */,\n\t\t\t\t3B3967161E833CAA004F5970 /* AppFrameworkInfo.plist in Resources */,\n\t\t\t\t97C146FE1CF9000F007C117D /* Assets.xcassets in Resources */,\n\t\t\t\t97C146FC1CF9000F007C117D /* Main.storyboard in Resources */,\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n/* End PBXResourcesBuildPhase section */",
    res_insert,
)

# --- PBXSourcesBuildPhase widget ---
src_insert = """\t\t97C146EA1CF9000F007C117D /* Sources */ = {
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t74858FAF1ED2DC5600515810 /* AppDelegate.swift in Sources */,
\t\t\t\t1498D2341E8E89220040F4C2 /* GeneratedPluginRegistrant.m in Sources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
\t\tE7B100102BCD43700ED5F59 /* Sources */ = {
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\tE7B1000B2BCD43700ED5F59 /* QuranBerandaWidget.swift in Sources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};
/* End PBXSourcesBuildPhase section */"""

text = text.replace(
    "\t\t97C146EA1CF9000F007C117D /* Sources */ = {\n\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t\t74858FAF1ED2DC5600515810 /* AppDelegate.swift in Sources */,\n\t\t\t\t1498D2341E8E89220040F4C2 /* GeneratedPluginRegistrant.m in Sources */,\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n/* End PBXSourcesBuildPhase section */",
    src_insert,
)

# --- PBXTargetDependency ---
dep_insert = """\t\t331C8086294A63A400263BE5 /* PBXTargetDependency */ = {
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = 97C146ED1CF9000F007C117D /* Runner */;
\t\t\ttargetProxy = 331C8085294A63A400263BE5 /* PBXContainerItemProxy */;
\t\t};
\t\tE7B1000F2BCD43900ED5F59 /* PBXTargetDependency */ = {
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = E7B1000A2BCD43700ED5F59 /* QuranBerandaWidgetExtension */;
\t\t\ttargetProxy = E7B1000E2BCD43900ED5F59 /* PBXContainerItemProxy */;
\t\t};
/* End PBXTargetDependency section */"""

text = text.replace(
    "\t\t331C8086294A63A400263BE5 /* PBXTargetDependency */ = {\n\t\t\tisa = PBXTargetDependency;\n\t\t\ttarget = 97C146ED1CF9000F007C117D /* Runner */;\n\t\t\ttargetProxy = 331C8085294A63A400263BE5 /* PBXContainerItemProxy */;\n\t\t};\n/* End PBXTargetDependency section */",
    dep_insert,
)

# --- Widget XCBuildConfiguration ---
widget_configs = """
\t\tE7B100152BCD43900ED5F59 /* Debug */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME = WidgetBackground;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = QuranBerandaWidgetExtension.entitlements;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)";
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_FILE = QuranBerandaWidget/Info.plist;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = "Quran Beranda";
\t\t\t\tINFOPLIST_KEY_NSHumanReadableCopyright = "";
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t\t"@executable_path/../../Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = "$(FLUTTER_BUILD_NAME)";
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.tursinalabs.quranoffline.QuranBerandaWidget;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSKIP_INSTALL = YES;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t};
\t\t\tname = Debug;
\t\t};
\t\tE7B100162BCD43900ED5F59 /* Release */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME = WidgetBackground;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = QuranBerandaWidgetExtension.entitlements;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)";
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_FILE = QuranBerandaWidget/Info.plist;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = "Quran Beranda";
\t\t\t\tINFOPLIST_KEY_NSHumanReadableCopyright = "";
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t\t"@executable_path/../../Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = "$(FLUTTER_BUILD_NAME)";
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.tursinalabs.quranoffline.QuranBerandaWidget;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSKIP_INSTALL = YES;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t};
\t\t\tname = Release;
\t\t};
\t\tE7B100172BCD43900ED5F59 /* Profile */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME = WidgetBackground;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = QuranBerandaWidgetExtension.entitlements;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)";
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_FILE = QuranBerandaWidget/Info.plist;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = "Quran Beranda";
\t\t\t\tINFOPLIST_KEY_NSHumanReadableCopyright = "";
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t\t"@executable_path/../../Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = "$(FLUTTER_BUILD_NAME)";
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.tursinalabs.quranoffline.QuranBerandaWidget;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSKIP_INSTALL = YES;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t};
\t\t\tname = Profile;
\t\t};
/* End XCBuildConfiguration section */"""

text = text.replace("/* End XCBuildConfiguration section */", widget_configs)

# --- Runner CODE_SIGN_ENTITLEMENTS ---
for marker in (
    "\t\t\tINFOPLIST_FILE = Runner/Info.plist;\n\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (",
):
    pass

runner_entitlements = "\t\t\t\tCODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;\n\t\t\t\t"

text = text.replace(
    "\t\t\tINFOPLIST_FILE = Runner/Info.plist;\n\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (\n\t\t\t\t\t\"$(inherited)\",\n\t\t\t\t\t\"@executable_path/Frameworks\",\n\t\t\t\t);\n\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.tursinalabs.quranoffline;",
    "\t\t\tINFOPLIST_FILE = Runner/Info.plist;\n\t\t\t\tCODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;\n\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (\n\t\t\t\t\t\"$(inherited)\",\n\t\t\t\t\t\"@executable_path/Frameworks\",\n\t\t\t\t);\n\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.tursinalabs.quranoffline;",
)

# --- XCConfigurationList for widget ---
config_list = """\t\t97C147051CF9000F007C117D /* Build configuration list for PBXNativeTarget "Runner" */ = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t97C147061CF9000F007C117D /* Debug */,
\t\t\t\t97C147071CF9000F007C117D /* Release */,
\t\t\t\t249021D4217E4FDB00AE95B9 /* Profile */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t};
\t\tE7B100142BCD43900ED5F59 /* Build configuration list for PBXNativeTarget "QuranBerandaWidgetExtension" */ = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\tE7B100152BCD43900ED5F59 /* Debug */,
\t\t\t\tE7B100162BCD43900ED5F59 /* Release */,
\t\t\t\tE7B100172BCD43900ED5F59 /* Profile */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t};
/* End XCConfigurationList section */"""

text = text.replace(
    "\t\t97C147051CF9000F007C117D /* Build configuration list for PBXNativeTarget \"Runner\" */ = {\n\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = (\n\t\t\t\t97C147061CF9000F007C117D /* Debug */,\n\t\t\t\t97C147071CF9000F007C117D /* Release */,\n\t\t\t\t249021D4217E4FDB00AE95B9 /* Profile */,\n\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n\t\t\tdefaultConfigurationName = Release;\n\t\t};\n/* End XCConfigurationList section */",
    config_list,
)

PBX.write_text(text, encoding="utf-8")
print("Patched project.pbxproj with QuranBerandaWidgetExtension target")
