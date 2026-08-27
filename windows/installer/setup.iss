; Inno Setup script for DBase Video & Music Downloader.
; Compiled in CI with: ISCC.exe /DAppVersion=x.y.z /DSourceDir=... setup.iss

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\build"
#endif

[Setup]
AppId={{F82F3B2C-5BC6-437D-9021-7BAA2B1F106F}
AppName=DBase Video & Music Downloader
AppVersion={#AppVersion}
AppPublisher=DBase
AppPublisherURL=https://github.com/DBase-In-Rs/Downloader
AppSupportURL=https://github.com/DBase-In-Rs/Downloader/issues
AppUpdatesURL=https://github.com/DBase-In-Rs/Downloader/releases
DefaultDirName={autopf}\DBase Downloader
DefaultGroupName=DBase Downloader
DisableProgramGroupPage=yes
LicenseFile=..\..\LICENSE
; Per-user install: no admin prompt, and winget-friendly.
PrivilegesRequired=lowest
OutputDir={#OutputDir}
OutputBaseFilename=dbase-downloader-v{#AppVersion}-windows-x64-setup
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\dbase_downloader.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; \
  GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; \
  Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\DBase Downloader"; Filename: "{app}\dbase_downloader.exe"
Name: "{autodesktop}\DBase Downloader"; Filename: "{app}\dbase_downloader.exe"; \
  Tasks: desktopicon

[Run]
Filename: "{app}\dbase_downloader.exe"; \
  Description: "{cm:LaunchProgram,DBase Downloader}"; \
  Flags: nowait postinstall skipifsilent
