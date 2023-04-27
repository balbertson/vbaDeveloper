Attribute VB_Name = "Git"
Option Explicit

' Helps execute Git Bash
' It requires a string command to execute inside Git Bash
' It also requires a VBProject, which it uses to cd to the project's source dir before running git commands
' For now, it assumes Git Bash is already installed in the default location
Public Function gitBash(usrcmd As String, vbaProject As VBProject) As Integer
    Dim cmd As String
    
    cmd = "C:\Users\" & Environ("username") & "\AppData\Local\Programs\Git\git-bash.exe"
    cmd = cmd & " --minimal-search-path"
    cmd = cmd & " --cd=" & CreateObject("Scripting.FileSystemObject").GetParentFolderName(vbaProject.fileName)
    cmd = cmd & " -c '" & usrcmd & "'"
    
    gitBash = System.execCmd(cmd)
End Function

' Runs a helper script from vbaDeveloper
' For now, it assumes the script exists
Public Function gitBashScript(script As String, vbaProject As VBProject, Optional args As String = "") As Integer
    Dim script_path, cmd As String
    script_path = CreateObject("Scripting.FileSystemObject").GetParentFolderName(Application.VBE.VBProjects("vbaDeveloper").fileName)
    script_path = script_path & "\scripts\"
    cmd = script_path & script
    convertToUnixPath cmd
    cmd = "source " & cmd & args
    gitBashScript = gitBash(cmd, vbaProject)
End Function

' Converts a Windows-style path to a Unix-style path in a simple fashion
' Replaces \ with /
' Replaces C: with /c (or any drive)
' Escapes ALL spaces (be careful with this)
Public Sub convertToUnixPath(path As String)
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
End Sub
