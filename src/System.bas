Attribute VB_Name = "System"
' This whole module is from https://learn.microsoft.com/en-us/office/vba/access/Concepts/Windows-API/determine-when-a-shelled-process-ends
Option Explicit

Private Type STARTUPINFO
cb As Long
lpReserved As String
lpDesktop As String
lpTitle As String
dwX As Long
dwY As Long
dwXSize As Long
dwYSize As Long
dwXCountChars As Long
dwYCountChars As Long
dwFillAttribute As Long
dwFlags As Long
wShowWindow As Integer
cbReserved2 As Integer
lpReserved2 As Long
hStdInput As Long
hStdOutput As Long
hStdError As Long
End Type

Private Type PROCESS_INFORMATION
hProcess As Long
hThread As Long
dwProcessID As Long
dwThreadID As Long
End Type

Private Declare PtrSafe Function WaitForSingleObject Lib "kernel32" (ByVal _
hHandle As Long, ByVal dwMilliseconds As Long) As Long

Private Declare PtrSafe Function CreateProcessA Lib "kernel32" (ByVal _
lpApplicationName As Long, ByVal lpCommandLine As String, ByVal _
lpProcessAttributes As Long, ByVal lpThreadAttributes As Long, _
ByVal bInheritHandles As Long, ByVal dwCreationFlags As Long, _
ByVal lpEnvironment As Long, ByVal lpCurrentDirectory As Long, _
lpStartupInfo As STARTUPINFO, lpProcessInformation As _
PROCESS_INFORMATION) As Long

Private Declare PtrSafe Function CloseHandle Lib "kernel32" (ByVal _
hObject As Long) As Long

Private Declare PtrSafe Function GetExitCodeProcess Lib "kernel32" (ByVal hProcess As Long, lpExitCode As Long) As Long

Private Const NORMAL_PRIORITY_CLASS = &H20&
Private Const INFINITE = -1&

Public Function execCmd(cmdline As String) As Long
Dim proc As PROCESS_INFORMATION
Dim start As STARTUPINFO
Dim ReturnValue As Integer
Dim EC As Long

' Initialize the STARTUPINFO structure:
start.cb = Len(start)

' Start the shelled application:
ReturnValue = CreateProcessA(0&, cmdline$, 0&, 0&, 1&, _
NORMAL_PRIORITY_CLASS, 0&, 0&, start, proc)

' Wait for the shelled application to finish:
Do
ReturnValue = WaitForSingleObject(proc.hProcess, 0)
DoEvents
Loop Until ReturnValue <> 258

ReturnValue = GetExitCodeProcess(proc.hProcess, EC)
ReturnValue = CloseHandle(proc.hProcess)
execCmd = EC
End Function

