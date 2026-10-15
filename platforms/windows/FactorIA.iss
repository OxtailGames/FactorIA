; FactorIA-windows-x64-setup.exe: the Windows installer (Inno Setup 6.3 or newer). Built by .github/workflows/release.yml
; from the same FactorIA\ folder that becomes FactorIA-windows-x64.zip; docs/GETTING_STARTED.md, "Download".
;
;   set FA_INSTALLER_VERSION=0.1.2
;   set FA_INSTALLER_SOURCE=C:\path\to\FactorIA
;   ISCC /OC:\path\to\out platforms\windows\FactorIA.iss
;
; The version is `factoria version` of that folder (the CMake project VERSION), so nothing here is versioned by hand.
; Both inputs come from the environment, not from /D, so a version or a path needs no quoting on the command line.
;
; Per-user install (no admin prompt) into %LOCALAPPDATA%\Programs\FactorIA. That folder is writable by the user, which
; the editor's self-updater needs: it replaces the files next to factoria.exe with the ones of the new zip
; (tools/editor/src/update.cpp). It never touches unins000.*, and the file names are the same, so the uninstaller keeps
; working after an update. What the updater leaves behind (.update\, *.old) is removed by [UninstallDelete].

#define AppVersion GetEnv("FA_INSTALLER_VERSION")
#define PackageDir GetEnv("FA_INSTALLER_SOURCE")
#if AppVersion == ""
  #error Set FA_INSTALLER_VERSION to the output of `factoria version` (see the top of this file)
#endif
#if PackageDir == ""
  #error Set FA_INSTALLER_SOURCE to the unpacked FactorIA folder (see the top of this file)
#endif

[Setup]
; Never change AppId: it is what makes a newer installer upgrade this install instead of adding a second one.
AppId={{89B68DB2-D710-4561-B80D-DB55FB7D4829}
AppName=FactorIA
AppVersion={#AppVersion}
AppPublisher=OxtailGames
AppPublisherURL=https://github.com/OxtailGames/FactorIA
AppSupportURL=https://github.com/OxtailGames/FactorIA/issues
; {autopf} is %LOCALAPPDATA%\Programs without admin rights. The folder is fixed (no directory page): it has to be
; one the user can write to, and the uninstaller only removes what it installed there.
DefaultDirName={autopf}\FactorIA
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Tells Explorer (and so the next terminals) about the PATH change at the end of the install and the uninstall.
ChangesEnvironment=yes
OutputBaseFilename=FactorIA-windows-x64-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName=FactorIA
UninstallDisplayIcon={app}\FactorIA-Editor.exe

[Files]
; ignoreversion: our exes have no version resource, so Inno would otherwise compare dates.
Source: "{#PackageDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\FactorIA Editor"; Filename: "{app}\FactorIA-Editor.exe"

[Run]
Filename: "{app}\FactorIA-Editor.exe"; Description: "Open the FactorIA editor"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Left by the editor's updater: the download folder of an update in progress and the replaced files.
Type: filesandordirs; Name: "{app}\.update"
Type: files; Name: "{app}\*.old"

[Code]
// The install folder goes on the USER path (HKCU\Environment), so `factoria` runs from any new terminal and the
// `.mcp.json` that `factoria new` writes (it starts the bare `factoria` command) works. ChangesEnvironment=yes
// broadcasts the change.

const
  EnvKey = 'Environment';

// True when the PATH entry Item is the folder Dir: case-insensitive, one trailing backslash ignored.
function SameDir(Item, Dir: String): Boolean;
begin
  if (Item <> '') and (Item[Length(Item)] = '\') then
    Delete(Item, Length(Item), 1);
  Result := CompareText(Item, Dir) = 0;
end;

// List without the entries for Dir (and without empty entries); Found tells whether there was one.
function WithoutDir(List, Dir: String; var Found: Boolean): String;
var
  Item: String;
  P: Integer;
begin
  Result := '';
  Found := False;
  while List <> '' do
  begin
    P := Pos(';', List);
    if P = 0 then
    begin
      Item := List;
      List := '';
    end else
    begin
      Item := Copy(List, 1, P - 1);
      List := Copy(List, P + 1, Length(List));
    end;
    if Item = '' then
      Continue;
    if SameDir(Item, Dir) then
      Found := True
    else
    begin
      if Result <> '' then
        Result := Result + ';';
      Result := Result + Item;
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  Old, Rest, Dir: String;
  Found: Boolean;
begin
  if CurStep <> ssPostInstall then
    Exit;
  Dir := ExpandConstant('{app}');
  if not RegQueryStringValue(HKCU, EnvKey, 'Path', Old) then
    Old := '';
  Rest := WithoutDir(Old, Dir, Found);
  if Found then
    Exit;  // already there (a reinstall or an upgrade): leave the user's PATH alone
  if (Old <> '') and (Old[Length(Old)] <> ';') then
    Old := Old + ';';
  RegWriteExpandStringValue(HKCU, EnvKey, 'Path', Old + Dir);
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  Old, Rest: String;
  Found: Boolean;
begin
  if CurUninstallStep <> usPostUninstall then
    Exit;
  if not RegQueryStringValue(HKCU, EnvKey, 'Path', Old) then
    Exit;
  Rest := WithoutDir(Old, ExpandConstant('{app}'), Found);
  if not Found then
    Exit;
  if Rest = '' then
    RegDeleteValue(HKCU, EnvKey, 'Path')
  else
    RegWriteExpandStringValue(HKCU, EnvKey, 'Path', Rest);
end;
