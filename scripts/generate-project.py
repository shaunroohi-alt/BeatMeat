#!/usr/bin/env python3
"""Generate BeatMeat's dependency-free native macOS Xcode project."""
from pathlib import Path
import hashlib
import json

root = Path(__file__).resolve().parent.parent
project = root / 'BeatMeat.xcodeproj'
project.mkdir(exist_ok=True)
objects = {}

def uid(name):
    return hashlib.sha256(('BeatMeat:'+name).encode()).hexdigest()[:24].upper()

def quote(value):
    return json.dumps(str(value))

def add(name, body):
    key = uid(name)
    objects[key] = body
    return key

def array(values):
    return '(' + ', '.join(values) + ',)'

sources = sorted(list((root/'Sources').rglob('*.swift')) + list((root/'Sources').rglob('*.cpp')))
headers = sorted((root/'Sources').rglob('*.h'))
resources = sorted((root/'Resources').glob('*')) if (root/'Resources').exists() else []
refs, source_builds, resource_builds = [], [], []
file_types = {'.swift':'sourcecode.swift', '.cpp':'sourcecode.cpp.cpp', '.h':'sourcecode.c.h', '.plist':'text.plist.xml', '.xcassets':'folder.assetcatalog', '.json':'text.json', '.txt':'text', '.png':'image.png', '.icns':'image.icns'}
for path in sources + headers + resources + [root/'Info.plist']:
    relative = path.relative_to(root).as_posix()
    kind = 'folder' if path.is_dir() and path.suffix != '.xcassets' else file_types.get(path.suffix, 'file')
    ref = add('ref:'+relative, f'isa = PBXFileReference; lastKnownFileType = {kind}; path = {quote(relative)}; sourceTree = "<group>";')
    refs.append(ref)
    if path in sources or path in resources:
        build = add('build:'+relative, f'isa = PBXBuildFile; fileRef = {ref};')
        (source_builds if path in sources else resource_builds).append(build)
product = add('product','isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = BeatMeat.app; sourceTree = BUILT_PRODUCTS_DIR;')
products = add('products', f'isa = PBXGroup; children = {array([product])}; name = Products; sourceTree = "<group>";')
group = add('group',f'isa = PBXGroup; children = {array(refs+[products])}; sourceTree = "<group>";')
src = add('sources',f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = {array(source_builds)}; runOnlyForDeploymentPostprocessing = 0;')
res = add('resources',f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = {array(resource_builds)}; runOnlyForDeploymentPostprocessing = 0;')
frameworks = add('frameworks','isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
project_settings = {
    'CLANG_ENABLE_MODULES':'YES', 'CLANG_ENABLE_OBJC_ARC':'YES',
    'CLANG_CXX_LANGUAGE_STANDARD':'c++17', 'CLANG_CXX_LIBRARY':'libc++',
    'MACOSX_DEPLOYMENT_TARGET':'14.0', 'SDKROOT':'macosx', 'SWIFT_VERSION':'5.0',
    'ARCHS':'$(ARCHS_STANDARD)', 'ONLY_ACTIVE_ARCH':'NO',
}
target_settings = {
    'PRODUCT_NAME':'BeatMeat', 'PRODUCT_BUNDLE_IDENTIFIER':'com.mpaudio.beatmeat',
    'INFOPLIST_FILE':'Info.plist', 'GENERATE_INFOPLIST_FILE':'NO',
    'SWIFT_OBJC_BRIDGING_HEADER':'Sources/BeatMeat-Bridging-Header.h',
    'SUPPORTED_PLATFORMS':'macosx', 'CODE_SIGN_STYLE':'Manual',
    'CODE_SIGN_IDENTITY':'-', 'ENABLE_APP_SANDBOX':'NO',
    'LD_RUNPATH_SEARCH_PATHS':'$(inherited) @executable_path/../Frameworks',
    'SWIFT_EMIT_LOC_STRINGS':'NO',
}
for level, base in [('project',project_settings),('target',target_settings)]:
    configs = []
    for configuration in ['Debug','Release']:
        settings = dict(base)
        settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone' if configuration == 'Debug' else '-O'
        settings['GCC_OPTIMIZATION_LEVEL'] = '0' if configuration == 'Debug' else '3'
        settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf' if configuration == 'Debug' else 'dwarf-with-dsym'
        if configuration == 'Debug':
            settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG'
        body = ' '.join(f'{name} = {quote(value)};' for name,value in settings.items())
        configs.append(add(level+':'+configuration,f'isa = XCBuildConfiguration; buildSettings = {{ {body} }}; name = {configuration};'))
    add(level+':configs',f'isa = XCConfigurationList; buildConfigurations = {array(configs)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
target = add('target',f'isa = PBXNativeTarget; buildConfigurationList = {uid("target:configs")}; buildPhases = {array([src,frameworks,res])}; buildRules = (); dependencies = (); name = BeatMeat; productName = BeatMeat; productReference = {product}; productType = "com.apple.product-type.application";')
main = add('project',f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 1600; TargetAttributes = {{ {target} = {{ CreatedOnToolsVersion = 16.0; }}; }}; }}; buildConfigurationList = {uid("project:configs")}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = {group}; productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; targets = {array([target])};')
text = '// !$*UTF8*$!\n{\n archiveVersion = 1; classes = {}; objectVersion = 56;\n objects = {\n'
text += '\n'.join(f'  {key} = {{ {body} }};' for key,body in objects.items())
text += f'\n }};\n rootObject = {main};\n}}\n'
(project/'project.pbxproj').write_text(text)
scheme = project/'xcshareddata/xcschemes/BeatMeat.xcscheme'
scheme.parent.mkdir(parents=True,exist_ok=True)
reference = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="BeatMeat.app" BlueprintName="BeatMeat" ReferencedContainer="container:BeatMeat.xcodeproj"/>'
scheme.write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{reference}</BuildActionEntry></BuildActionEntries></BuildAction>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference}</BuildableProductRunnable></LaunchAction>
 <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference}</BuildableProductRunnable></ProfileAction>
 <AnalyzeAction buildConfiguration="Debug"/>
 <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
print(f'Generated {project} with {len(sources)} native source files.')
