Attribute VB_Name = "Git"
Option Explicit

Private Const LOGBASE As String = ".vbaDeveloper-git-bash"
Private Const EC_LOG As String = LOGBASE & "-ec"

Private Sub Test()
    On Error GoTo errhand
    gitBashScript "git-update.sh", Application.VBE.VBProjects("ASIC_Power_Spreadsheet"), args:="", path_override:=False
    Exit Sub
errhand:
    Err.Description = "Update failed"
    ErrorHandling.handleError
End Sub

' Helps execute Git Bash
' It requires a string command to execute inside Git Bash
' It also requires a VBProject, which it uses to cd to the project's source dir before running git commands
' For now, it assumes Git Bash is already installed in the default location
Public Sub gitBash(usrcmd As String, vbaProject As VBProject)
    Dim cmd As String
    Dim workdir As String
    Dim EC As Integer
    
    workdir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(vbaProject.fileName)

    On Error GoTo gitBashErrorHandler
    ' Get full path to installation directory
    cmd = getGitInstallPath()
    ' Add executable name
    cmd = cmd & "\git-bash.exe"
    ' git-bash args
    cmd = cmd & " --minimal-search-path"
    ' cd to the directory of the workbook
    cmd = cmd & " --cd=" & workdir
    ' start the git-bash command with the user's command
    cmd = cmd & " -c '" & usrcmd
    ' add a call to the post-command bash scriptss
    cmd = cmd & "; source " & createPostBashScript(workdir)
    ' terminate the git-bash command
    cmd = cmd & "'"
    
    On Error GoTo 0
    Debug.Print cmd
    System.execCmd cmd
    EC = getGitBashEC(workdir)
    If EC <> 0 Then
        ErrorHandling.RaiseError EC, "Git.gitBash", "Git Bash returned " & EC
    End If
    Exit Sub
gitBashErrorHandler:
    'Err.Description = "Unable to run command: " & usrcmd
    ErrorHandling.handleError "Git.gitBash"
End Sub

' Sources a bash script to run in Git Bash
' Params:
'   script: just the file name of a bash script to run
'   vbaProject: the VBA project to cd into before running the script
'   args: a string that's appended after the script. Can hold script arguments and/or subsequent commands
'   path_override: If false (the default), look for the script in the vbaDeveloper space. If true, look in the scripts/ directory of the vbaProject space.
' It assumes the script is bash and can be executed
Public Sub gitBashScript(script As String, vbaProject As VBProject, Optional args As String = "", Optional path_override As Boolean = False)
    Dim cmd As String
    Dim path As String

    ' Act on the path_override param
    If path_override = True Then
        path = vbaProject.fileName
    Else
        path = Application.VBE.VBProjects("vbaDeveloper").fileName
    End If
    
    ' Remove the file name of the workbook
    cmd = CreateObject("Scripting.FileSystemObject").GetParentFolderName(path)
    ' Append the scripts dir
    cmd = cmd & "\scripts\"
    ' Append the script name
    cmd = cmd & script
    
    ' Check that the script exists
    If Len(Dir(cmd)) = 0 Then
        ErrorHandling.RaiseError 5, "Git.gitBashScript", "Script not found: " & vbNewLine & cmd
        Exit Sub
    End If
    
    cmd = "source " & convertToUnixPath(cmd) & args

    gitBash cmd, vbaProject
End Sub

Public Sub update(vbaProjectName As String)
    gitBashScript "git-update.sh", Application.VBE.VBProjects(vbaProjectName)
End Sub

' Converts a Windows-style path to a Unix-style path in a simple fashion
' Replaces \ with /
' Replaces C: with /c (or any drive)
' Escapes ALL spaces (be careful with this)
Public Function convertToUnixPath(ByVal path As String) As String
    Dim Regex As RegExp
    Set Regex = New RegExp
    
    Regex.Pattern = "\\"
    Regex.Global = True
    path = Regex.Replace(path, "/")
    
    Regex.Pattern = "^([A-Z]):/"
    Regex.Global = False
    path = Regex.Replace(path, "/$1/")
    
    Regex.Pattern = "\s"
    Regex.Global = True
    path = Regex.Replace(path, "\ ")
    
    convertToUnixPath = path
End Function

' Returns the installation path of Git for Windows
' It relies on Registry entry created by the installer
' If the Registry lookup fails, this throws and error
Private Function getGitInstallPath() As String
    On Error GoTo getInstallPathError
    getGitInstallPath = CreateObject("WScript.Shell").RegRead("HKEY_CURRENT_USER\SOFTWARE\GitForWindows\InstallPath")
    Exit Function
getInstallPathError:
    Dim source As String
    source = "Git.getInstallPath"
    Err.Description = Err.Description & " Git for Windows might not be installed."
    ErrorHandling.handleError source
    getGitInstallPath = Err.Description
    ErrorHandling.RaiseError 5, source, Err.Description
End Function

' Create a script that should run after any git bash call.
' It creates a file that's used to communicate the exit code
' between git bash and VBA.
Private Function createPostBashScript(path As String) As String
    Dim f
    Dim scriptname As String
    
    scriptname = path & "/" & LOGBASE & ".sh"
    
    Set f = CreateObject("Scripting.FileSystemObject").OpenTextFile(scriptname, IOMode:=ForWriting, Create:=True, format:=TristateFalse)
    
    ' capture the exit code
    f.WriteLine "EC=$?"
    ' overwrite the exit code file
    f.WriteLine "echo $EC > " & EC_LOG
    
    f.Close
    
    createPostBashScript = convertToUnixPath(scriptname)
End Function

Private Function getGitBashEC(path As String) As Integer
    Dim f
    Dim EC As String

    Set f = CreateObject("Scripting.FileSystemObject").OpenTextFile(path & "\" & EC_LOG, IOMode:=ForReading, Create:=False, format:=TristateFalse)
    
    EC = f.ReadLine
    f.Close
    
    getGitBashEC = CInt(EC)
End Function
