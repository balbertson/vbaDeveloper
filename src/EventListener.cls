VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "EventListener"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'This class receives and acts upon events from the excel application.
' To disable this eventhandling, simply don't instantiate this class. See Thisworkbook.

Private WithEvents App As Application
Attribute App.VB_VarHelpID = -1


Private Sub Class_Initialize()
    Set App = Application
End Sub


Private Sub App_WorkbookAfterSave(ByVal wb As Workbook, ByVal success As Boolean)
    On Error GoTo App_WorkbookAfterSave_Error
    Exit Sub
    'Export all the modules for this work book if save was successful
    If success Then
        Build.exportVbaCode wb.VBProject
        'NamedRanges.exportNamedRanges wb
        MsgBox "Finished saving workbook: " & wb.name & ". Code is exported."
    Else
        MsgBox "Saving workbook: " & wb.name & " was not successful. Code is not exported."
    End If

    Exit Sub
App_WorkbookAfterSave_Error:
    ErrorHandling.handleError "vbaDeveloper.EventListener afterSave"
End Sub


Private Sub App_WorkbookBeforeSave(ByVal wb As Workbook, ByVal SaveAsUI As Boolean, Cancel As Boolean)
    If Not Cancel Then
        'Formatter.formatProject wb.VBProject
    End If
End Sub


Private Sub App_WorkbookOpen(ByVal wb As Workbook)
    On Error GoTo ImportOnOpenNotFound
    ' Importing during open can be disabled
    If wb.ImportOnOpen = False Then
        Debug.Print "Importing on workbook open is disabled for " & wb.name
        Exit Sub
    End If
    On Error GoTo App_WorkbookOpen_Error
    ' Only import macro-enabled workbooks
    If wb.FileFormat <> xlOpenXMLWorkbookMacroEnabled And wb.FileFormat <> xlOpenXMLAddIn Then
        Debug.Print wb.name & " is not macro-enabled. Skipping import."
        Exit Sub
    End If
    ' Import all the modules for this workbook
    Dim importNow As Integer
    importNow = MsgBox("Import the code for " & wb.name & " now?", vbYesNo, "EventListener Workbook open event")
    If importNow = vbNo Then
        Exit Sub
    End If
    Application.EnableEvents = False
    Build.importVbaCode wb.VBProject
    Application.EnableEvents = True
    Exit Sub
ImportOnOpenNotFound:
    ' If the global variable isn't set, continue on as if it were set to True
    Resume Next
App_WorkbookOpen_Error:
    ErrorHandling.handleError "vbaDeveloper.EventListener WorkbookOpen"
    Application.EnableEvents = True
End Sub


Private Sub Class_Terminate()
    Set App = Nothing
End Sub

