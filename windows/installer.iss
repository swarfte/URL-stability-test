; ============================================================
; Parameters supplied by GitHub Actions:
;
; /DMyAppName=UrlStabilityTest
; /DMyAppExeName=url_stability_test.exe
; /DMyAppVersion=1.0.0
; /DBuildDir=...
; /DOutputDir=...
;
; The #ifndef blocks provide defaults for local compilation.
; ============================================================

#ifndef MyAppName
  #define MyAppName "UrlStabilityTest"
#endif

#ifndef MyAppExeName
  #define MyAppExeName "url_stability_test.exe"
#endif

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

#ifndef BuildDir
  #define BuildDir "..\build\windows\x64\runner\Release"
#endif

#ifndef OutputDir
  #define OutputDir "..\dist"
#endif

#define MyAppPublisher "URL Stability Test Team"
#define MyAppFileName "UrlStabilityTest-Windows-Setup"

[Setup]
AppId={{B43F6267-C230-4B22-9905-9A9881234567}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}

DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes

OutputDir={#OutputDir}
OutputBaseFilename={#MyAppFileName}

Compression=lzma2
SolidCompression=yes
WizardStyle=modern

ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog

UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}

SetupLogging=yes

[Files]
Source: "{#BuildDir}\*"; \
    DestDir: "{app}"; \
    Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; \
    Filename: "{app}\{#MyAppExeName}"; \
    WorkingDir: "{app}"

Name: "{autodesktop}\{#MyAppName}"; \
    Filename: "{app}\{#MyAppExeName}"; \
    WorkingDir: "{app}"; \
    Tasks: desktopicon

[Tasks]
Name: "desktopicon"; \
    Description: "建立桌面捷徑"; \
    GroupDescription: "其他選項："; \
    Flags: unchecked

[Run]
Filename: "{app}\{#MyAppExeName}"; \
    Description: "啟動 {#MyAppName}"; \
    WorkingDir: "{app}"; \
    Flags: nowait postinstall skipifsilent