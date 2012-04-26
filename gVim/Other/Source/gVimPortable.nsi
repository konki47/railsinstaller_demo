;Copyright (C) 2004-2009 John T. Haller of PortableApps.com
;Copyright (C) 2008-2009 Chris Morgan of PortableApps.com

;Website: http://PortableApps.com/gVimPortable

;This software is OSI Certified Open Source Software.
;OSI Certified is a certification mark of the Open Source Initiative.

;This program is free software; you can redistribute it and/or
;modify it under the terms of the GNU General Public License
;as published by the Free Software Foundation; either version 2
;of the License, or (at your option) any later version.

;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.

;You should have received a copy of the GNU General Public License
;along with this program; if not, write to the Free Software
;Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

!define PORTABLEAPPNAME "gVim Portable"
!define APPNAME "gVim"
!define NAME "gVimPortable"
!define VER "1.6.3.0"
!define WEBSITE "PortableApps.com/gVimPortable"
!define LAUNCHERLANGUAGE "English"

;=== Program Details
Name "${PORTABLEAPPNAME}"
OutFile "..\..\${NAME}.exe"
Caption "${PORTABLEAPPNAME} | PortableApps.com"
VIProductVersion "${VER}"
VIAddVersionKey ProductName "${PORTABLEAPPNAME}"
VIAddVersionKey Comments "Allows ${APPNAME} to be run from a removable drive.  For additional details, visit ${WEBSITE}"
VIAddVersionKey CompanyName "PortableApps.com"
VIAddVersionKey LegalCopyright "PortableApps.com & Contributors"
VIAddVersionKey FileDescription "${PORTABLEAPPNAME}"
VIAddVersionKey FileVersion "${VER}"
VIAddVersionKey ProductVersion "${VER}"
VIAddVersionKey InternalName "${PORTABLEAPPNAME}"
VIAddVersionKey LegalTrademarks "PortableApps.com is a Trademark of Rare Ideas, LLC."
VIAddVersionKey OriginalFilename "${NAME}.exe"
;VIAddVersionKey PrivateBuild ""
;VIAddVersionKey SpecialBuild ""

;=== Runtime Switches
CRCCheck On
WindowIcon Off
SilentInstall Silent
AutoCloseWindow True
RequestExecutionLevel user
XPStyle On

; Best Compression
SetCompress Auto
SetCompressor /SOLID lzma
SetCompressorDictSize 32
SetDatablockOptimize On

;=== Include
;(Standard NSIS)
!include FileFunc.nsh
!insertmacro GetParameters
!insertmacro GetRoot
!insertmacro GetParent
!include LogicLib.nsh

;(NSIS Plugins)
!include TextReplace.nsh

;(Custom)
!include ReplaceInFileWithTextReplace.nsh

;=== Program Icon
Icon "..\..\App\AppInfo\appicon.ico"

;=== Icon & Stye ===
;!define MUI_ICON "..\..\App\AppInfo\appicon.ico"

;=== Languages
;!insertmacro MUI_LANGUAGE "${LAUNCHERLANGUAGE}"
LoadLanguageFile "${NSISDIR}\Contrib\Language files\${LAUNCHERLANGUAGE}.nlf"
!include PortableApps.comLauncherLANG_${LAUNCHERLANGUAGE}.nsh

Var MISSINGFILEORPATH

Section "Main"
	${IfNot} ${FileExists} "$EXEDIR\App\vim\vim72\gvim.exe"
		StrCpy $MISSINGFILEORPATH "gvim.exe"
		MessageBox MB_OK|MB_ICONEXCLAMATION `$(LauncherFileNotFound)`
		Abort
	${EndIf}

	ReadINIStr $0 "$EXEDIR\${NAME}.ini" "${NAME}" "DisableSplashScreen"
	${If} $0 != "true"
		;=== Show the splash screen while processing registry entries
		InitPluginsDir
		File /oname=$PLUGINSDIR\splash.jpg "${NAME}.jpg"
		newadvsplash::show /NOUNLOAD 1200 0 0 -1 /L $PLUGINSDIR\splash.jpg
	${EndIf}

	;=== Start working with the settings
	${IfNot} ${FileExists} "$EXEDIR\Data\settings\_vimrc"
		CreateDirectory "$EXEDIR\Data\settings"
		CopyFiles /SILENT `$EXEDIR\App\DefaultData\settings\*.*` "$EXEDIR\Data\settings"
	${EndIf}

	;=== Set environment variables
	System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("VIM", "$EXEDIR\App\vim").n'
	System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("VIMRUNTIME", "$EXEDIR\App\vim\vim72").n'
	System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("HOME", "$EXEDIR\Data\settings").n'

	;=== Manage TEMP redirection
	FindProcDLL::FindProc "gvim.exe"
	${If} $R0 = 1
		RMDir /r $EXEDIR\Data\temp
	${EndIf}

	CreateDirectory "$EXEDIR\Data\temp"
	System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("TEMP", "$EXEDIR\Data\temp").n'
	System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("TMP", "$EXEDIR\Data\temp").n'
	
	;=== Update drive letter
	ReadINIStr $0 "$EXEDIR\Data\settings\${NAME}Settings.ini" "${NAME}Settings" "LastDrive"
	${GetRoot} $EXEDIR $1
	${If} $0 != $1
		WriteINIStr "$EXEDIR\Data\settings\${NAME}Settings.ini" "${NAME}Settings" "LastDrive" "$1"
		${If} ${FileExists} "$EXEDIR\Data\settings\_viminfo"
			${ReplaceInFile} "$EXEDIR\Data\settings\_viminfo" "$0/" "$1/"
			${ReplaceInFile} "$EXEDIR\Data\settings\_viminfo" "$0\" "$1\"
		${EndIf}
	${EndIf}

	;=== Launch and exit
	${GetParameters} $0
	StrCpy $1 `"$EXEDIR\App\vim\vim72\gvim.exe" -n $0`

	ReadINIStr $0 "$EXEDIR\${NAME}.ini" "${NAME}" "AdditionalParameters"
	StrCpy $1 `$1 $0`
	Exec $1
		newadvsplash::stop /WAIT
SectionEnd
