/*
  Array is populated for TeachingAssignment
  Next is to go through the data fields and create arrays of the unique column headings and inserting all the data into the arrays
*/

#SingleInstance, force
Debug := 0
FileEncoding, UTF-8
SetTitleMatchMode, RegEx
SetDefaultMouseSpeed, 0

GroupAdd, ADarkRoom, A Raucous Village
GroupAdd, ADarkRoom, A Barren World
GroupAdd, ADarkRoom, A Dusty Path
GroupAdd, ADarkRoom, A Firelit Room
GroupAdd, ADarkRoom, A Silent Forest


; DBFilePath := "C:\Users\15ys\Documents\ahk_staff.csv"
DBFilePath := "C:\Users\15ys\Documents\ahk_staff_test.csv"
; DBFilePath := "C:\Users\15ys\Documents\ahk_staff_v2.csv"
DBFilePath := "C:\Users\15ys\Documents\ahk_staff_v3.csv"

TeacherAssignmentFilePath := "C:\Users\15ys\Documents\Teaching_Assignment_2014_15_raw.csv"
TeacherAssignmentFilePath := "C:\Users\15ys\Documents\Teaching_Assignment_2014_15_raw_test.csv"

TeacherAssignmentDataThreashhold := 0.1
; This is the ratio of data needed in a row to be considered "data".  0.1 = 10%
; First data row is determined to be column headers, and will have blank spaces populated with previous column data due to "merged cell" behavior

InitializeStaffNameDB()
/* Special notes about the StaffArrayName array
  First 3 index are the StaffInitial, StaffEnglishName, and StaffChineseName
  These 3 are processed differently, so loops that process the StaffArrayName array will skip the first 3 index
*/

InitializeTeachingAssignmentDB()
return

SaveClip() {
  global TempClip := ClipboardAll
}
RestoreClip() {
  global TempClip
  Clipboard := TempClip
}

dummy:
return

^+v::
; There is a Notepad++ specific version
; SavedClipboard := ClipboardAll
; Clipboard = %Clipboard%
Clipboard := RegExReplace(Clipboard, "\t", " ")
Clipboard := trim(RegExReplace(Clipboard, "[\r\n\cA-\cZ]"))
SendInput, ^v
; Sleep 10
; Clipboard := SavedClipboard
; SavedClipboard =
return

^F12::
reload
return

^+!F12::
exitapp
return

ToggleAutoHideTaskBar() {
	VarSetCapacity( APPBARDATA, 36, 0 )
	NumPut(36, APPBARDATA, 0, "UInt") ; First field is the size of the struct
	bits := DllCall("Shell32.dll\SHAppBarMessage"
    			,"UInt", 4 ; ABM_GETSTATE
    			,"UInt", &APPBARDATA )  
  NumPut( (bits ^ 0x1), APPBARDATA, 32, "UInt" ) ; Toggle Autohide
  DllCall("Shell32.dll\SHAppBarMessage"
    			,"UInt", ( ABM_SETSTATE := 0xA )
    			,"UInt", &APPBARDATA )
}

FindImage(X1, Y1, X2, Y2, ImageFile) {
  ImageSearch, , , %X1%, %Y1%, %X2%, %Y2%, %ImageFile%
  if (errorLevel = 2) {
    ToolTip, FindImage failed to start
    Sleep 1000
    ToolTip
    return 0
  } else if (errorlevel = 1) {
    return 0
  } else {
    return 1
  }
}

WaitImageLoss(X1, Y1, X2, Y2, ImageFile, CustomError = "Image Found", WaitImageDelay = 1000, WaitImageMaxLoop = 0) {
  WaitImageLoop := 0
  loop {
    ImageSearch, , , %X1%, %Y1%, %X2%, %Y2%, %ImageFile%
    if (errorLevel = 2) {
      ToolTip, WaitImage failed to start
      Sleep 500
      ToolTip
      return 0
    } else if (errorlevel = 1) {
      return 1
    } else {
      If (CustomError != "") {
        ToolTip, %CustomError%
        Sleep 500
        ToolTip
      }
      Sleep %WaitImageDelay%
    }
    if (WaitImageMaxLoop > 0) {
      WaitImageLoop += 1
      if (WaitImageLoop > WaitImageMaxLoop) {
        ; throw { what: "WaitImageLoss failure", file: A_LineFile, line: A_LineNumber }
        return 0
      }
    }
  }
}

WaitImage(X1, Y1, X2, Y2, ImageFile, CustomError = "Image Not Found", WaitImageDelay = 1000, WaitImageMaxLoop = 0) {
  WaitImageLoop := 0
  loop {
    ImageSearch, , , %X1%, %Y1%, %X2%, %Y2%, %ImageFile%
    if (errorLevel = 2) {
      ToolTip, WaitImage failed to start
      Sleep 500
      ToolTip
      return 0
    } else if (errorlevel = 1) {
      If (CustomError != "") {
        ToolTip, %CustomError%
        Sleep 500
        ToolTip
      }
      Sleep %WaitImageDelay%
    } else {
      return 1
    }
    if (WaitImageMaxLoop > 0) {
      WaitImageLoop += 1
      if (WaitImageLoop > WaitImageMaxLoop) {
        ; throw
        return 0
      }
    }
  }
}

ClickImage(X1, Y1, X2, Y2, ImageFile, CustomError = "Image Not Found", ClickOffsetX = 0, ClickOffsetY = 0, Double = 0) {
  ImageSearch, ISMouseX, ISMouseY, %X1%, %Y1%, %X2%, %Y2%, %ImageFile%
  if (errorLevel = 2) {
    ToolTip, ClickImage failed to start
    Sleep 500
    ToolTip
    return 0
  } else if (errorlevel = 1) {
    If (CustomError != "") {
      ToolTip, %CustomError%
      Sleep 500
      ToolTip
    }
    return 0
  } else {
    ISMouseX += ClickOffsetX
    ISMouseY += ClickOffsetY
    MouseMove, %ISMouseX%,%ISMouseY%
    Sleep 100
    If (Double) {
      Click 2
    } Else {
      Click
    }
    return 1
  }
}

InitializeTeachingAssignmentDB() {
  global
  TeachingAssignmentArray := Object()
  local columnHeadings := 0
  local rowDataCount := Object()
  local rowDataMaxConsecutiveEmpty := Object()
  
  local columnHeadingRow := 0
  Loop, Read, %TeacherAssignmentFilePath%
  {
    local Field := Object()
    local previousColumn := ""
    local rowDataCurrentConsecutiveEmpty := 0
    local totalColumns := 0
    rowDataCount.insert("0")
    rowDataMaxConsecutiveEmpty.insert("0")
    local outsideLoopIndex := A_Index
    Loop, parse, A_LoopReadLine, csv
    {
      totalColumns += 1
      if(A_LoopField) {
        rowDataCount[outsideLoopIndex] += 1
        tmp := rowDataCount[outsideLoopIndex]
        rowDataCurrentConsecutiveEmpty := 0
        Field.Insert(A_LoopField)
      } else {
        rowDataCurrentConsecutiveEmpty += 1
        if (rowDataCurrentConsecutiveEmpty > rowDataMaxConsecutiveEmpty[outsideLoopIndex]) {
          rowDataMaxConsecutiveEmpty[outsideLoopIndex] := rowDataCurrentConsecutiveEmpty
        }
        Field.Insert(A_LoopField)
      }
    }
    if (Debug) {
      local testOut := "Consect_Empty: " rowDataMaxConsecutiveEmpty[outsideLoopIndex] " Data_Count: " rowDataCount[outsideLoopIndex]
    }
    if((rowDataCount[outsideLoopIndex] / totalColumns) < 0.1) {
      Continue
    } else {
      if (!columnHeadingRow) {
        if (Debug) {
          testOut .= " *** Header Row *** "
        }
        columnHeadingRow := outsideLoopIndex
      }
      for index, element in Field
      {
        if (element) {
          previousColumn := element
        } else {
          if (columnHeadingRow = outsideLoopIndex) {
            ; cannot use element because it is a by-value variable
            Field[index] := previousColumn 
          }
        }
        if (Debug) {
          testOut .= " | " Field[index]
        }
      }
      
    }
    if (Debug) {
      Msgbox %testOut%
    }
    TeachingAssignmentArray.Insert(Field)
  }
  Sleep 1000
  ToolTip
}

InitializeStaffNameDB() {
  ; "AL","Lo Man Ho, Arthur","盧文豪","Teachers","6B"
  global
  StaffArrayName := Object()
  StaffArrayProperName := Object()

  Loop, Read, %DBFilePath%
  {
    local Field := Object()
    local outsideLoop := A_Index
    Loop, parse, A_LoopReadLine, csv
    {
      if (outsideLoop = 1) {
        StaffArrayName.Insert(A_LoopField)
      } else if(outsideLoop = 2){
        StaffArrayProperName.Insert(A_LoopField)
      } else {
        ; MsgBox, Field number %A_Index% is %A_LoopField%.
        Field.Insert(A_LoopField)
      }
    }
    if (A_Index = 1) {
      for i, e in StaffArrayName
      {
        ; Initialize all dynamic arrays
        ; Msgbox % i ": is " e
        %e% := Object()
      }
      continue
    }
    for index, element in Field
    {
      ; populating global staff data arrays for searching
      local StaffArrayInsert := StaffArrayName[index]
      %StaffArrayInsert%.Insert(element)
    }
    
    local ThisInitial := Field[1]
    local ThisEName := Field[2]
    local ThisCName := Field[3]
    local ThisRole := Field[4]
    local ThisHomeRoom := Field[5]
    
    ; global vars
    ; Some functions do not use the global vars since these were changed to global after those functions were created
    ; Not going to change them unless the arrays become too large to handle
    InitArrName := StaffArrayName[1]
    ENameArrName := StaffArrayName[2]
    CNameArrName := StaffArrayName[3]
    
    InitArr := %InitArrName%
    ENameArr := %ENameArrName%
    CNameArr := %CNameArrName%

    /*
      ; These variables are being populated dynamically
      RoleArrName := StaffArrayName[4]
      HomeRoomArrName := StaffArrayName[5]

      RoleArr := %RoleArrName%
      HomeRoomArr := %HomeRoomArrName%
    */
    

    ; Specific index processing for fast access
    ; i.e.) create an array using SM[] so all SM access are instant and do not require a search
    ; Currently using index 1 and 3 to create variable names (English Initial and UTF-8 Chinese Name)
    ; need to initialize all arrays, then loop through the fields to populate arrays

    ; Associating data to StaffInitial array key
    ObjRawSet(%InitArrName%, ThisCName, ThisInitial)
    ObjRawSet(%InitArrName%, ThisEName, ThisInitial)
    
    ; Associating data to StaffCName array key
    ObjRawSet(%CNameArrName%, ThisInitial, ThisCName)
    ObjRawSet(%CNameArrName%, ThisEName, ThisCName)
    
    ; Associating data to StaffEName array key
    ObjRawSet(%ENameArrName%, ThisInitial, ThisEName)
    ObjRawSet(%ENameArrName%, ThisCName, ThisEName)
    
    ; Auto-populate data in case of new data being entered
    loop % StaffArrayName.Length()
    {
      if(A_Index < 4) {
        Continue
      }
      ThisStaffArrayName := StaffArrayName[A_Index]
      ObjRawSet(%ThisStaffArrayName%, ThisInitial, Field[A_Index])
      ObjRawSet(%ThisStaffArrayName%, ThisEName, Field[A_Index])
      ObjRawSet(%ThisStaffArrayName%, ThisCName, Field[A_Index])
    }
    
    /*
    ObjRawSet(%RoleArrName%, ThisInitial, ThisRole)
    ObjRawSet(%RoleArrName%, ThisEName, ThisRole)
    ObjRawSet(%RoleArrName%, ThisCName, ThisRole)

    ObjRawSet(%HomeRoomArrName%, ThisInitial, ThisHomeRoom)
    ObjRawSet(%HomeRoomArrName%, ThisEName, ThisHomeRoom)
    ObjRawSet(%HomeRoomArrName%, ThisCName, ThisHomeRoom)
    */
  }
}

StaffFieldSearch(input) {
  ; outputs an array of staff initials
  global
  ; Msgbox, FieldSearch
  local outputArr := object()
  loop % InitArr.MaxIndex()
  {
    if(InitArr[A_Index] = input
    or ENameArr[A_Index] = input
    or CNameArr[A_Index] = input) {
      outputArr.Insert(InitArr[A_Index])
    } else {
      outsideIndex := A_Index
      ; loop through the StaffArrayName generated dynamic arrays to find the data
      loop % StaffArrayName.Length()
      {
        if (A_Index < 4) {
          Continue
        } else {
          local ThisStaffArrayName := StaffArrayName[A_Index]
          local ThisStaffArray := %ThisStaffArrayName%
          if(ThisStaffArray[outsideIndex] = input) {
            outputArr.Insert(InitArr[outsideIndex])
            MainMenuCategoryTitle := StaffArrayProperName[A_Index]
            break
          }
        }
      }
    }
    ; Msgbox % InitArr[A_Index] "|" ENameArr[A_Index] "|" CNameArr[A_Index] "|" RoleArr[A_Index] "|" HomeRoomArr[A_Index]
  }
  return outputArr
}

StaffNameFuzzyLogic(input) {
  ; outputs an array of staff initials
  global
  local outputArr := object()
  
  local ThisStaffInitArrName := StaffArrayName[1]
  local ThisStaffInitArr := %ThisStaffInitArrName%

  local ThisStaffENameArrName := StaffArrayName[2]
  local ThisStaffENameArr := %ThisStaffENameArrName%

  local ThisStaffCNameArrName := StaffArrayName[3]
  local ThisStaffCNameArr := %ThisStaffCNameArrName%
  
  EMode := 0
  
  if (!RegExMatch(input, "[^\x00-\x7F]+") and RegExMatch(input, "[A-Za-z]{2}")) {
    ; English Mode, either contains no Unicode characters, or must contain 2 or more alpha
    EMode := 1
    local ThisStaffArrLoop := ThisStaffENameArr
    local inputString := trim(RegExReplace(input, "[^A-Za-z ]"))
    local inputArr := StrSplit(inputString, " ")
  } else if (StrLen(RegExReplace(input, "[\x00-\x7F]")) > 0) {
    ; Chinese Mode
    local ThisStaffArrLoop := ThisStaffCNameArr
    inputString := trim(RegExReplace(input, " "))
    local inputArr := StrSplit(inputString)
  } else {
    ; Miscellaneous Mode, doing nothing at the moment
    return
  }
  
  loop % ThisStaffArrLoop.MaxIndex()
  {
    local arrayInInputFail := 0
    local inputInArrayFail := 0
    
    local ThisStaffName := ThisStaffArrLoop[A_Index]
    if(ThisStaffName = "") {
      ; It is possible for some staff to not have a name in particular columns, e.g.) western teacher without a Chinese name
      Continue
    }
    ; two way regex search after stripping non-alpha characters and splitting the string
    ; multi direction and very inclusive... John Doe will match "Mr. John Doe", "Doe, John", "John Doe", "John McDoe the Third", "Doey Johnny", etc.
    if (EMode) {
      local ThisStaffNameString := trim(RegExReplace(ThisStaffName, "[^A-Za-z ]"))
    } else {
      local ThisStaffNameString := trim(RegExReplace(ThisStaffName, "[ ]"))
    }
    local ThisStaffNameArr := StrSplit(ThisStaffNameString, " ")
    
    for i, e in ThisStaffNameArr
    {
      if (!arrayInInputFail) {
        if (inputString = "" or e = "" or !InStr(inputString, e)) {
          arrayInInputFail := 1
        }
      }
    }
    for i, e in inputArr
    {
      if (!inputInArrayFail) {
        if (ThisStaffNameString = "" or e = "" or !InStr(ThisStaffNameString, e)) {
          inputInArrayFail := 1
        }
      }
    }
    if (!inputInArrayFail or !arrayInInputFail) {
      outputArr.Insert(ThisStaffInitArr[A_Index])
    }
  }
  return outputArr
}

StaffNameMenu(input) {
  ; StaffArrayName : "StaffInitial","StaffEName","StaffCName","StaffRole","StaffHomeRoom","StaffEHonorific"
  ; Note: This variable is populated dynamically.  Refer to the data file for most up-to-date information
  
  global
  local ThisInitArrName := StaffArrayName[1]
  local ThisStaffInitArr := %ThisInitArrName%
  
  local ThisStaffENameArrName := StaffArrayName[2]
  local ThisStaffENameArr := %ThisStaffENameArrName%
  
  local ThisStaffCNameArrName := StaffArrayName[3]
  local ThisStaffCNameArr := %ThisStaffCNameArrName%

  local ThisStaffRoleArrName := StaffArrayName[4]
  local ThisStaffRoleArr := %ThisStaffRoleArrName%
  
  local ThisStaffHomeRoomArrName := StaffArrayName[5]
  local ThisStaffHomeRoomArr := %ThisStaffHomeRoomArrName%
  
  local ThisStaffInit := ThisStaffInitArr[input]
  local ThisStaffCName := ThisStaffCNameArr[input]
  local ThisStaffEName := ThisStaffENameArr[input]
  local ThisStaffRole := ThisStaffRoleArr[input]
  local ThisStaffHomeRoom := ThisStaffHomeRoomArr[input]
  
  AppendMode := 0
  
  MainMenuTitle := trim(input)

  Menu, StaffNameMenu, Add, mainTempTitle, dummy
  Menu, StaffNameMenu, Disable, mainTempTitle
  DataFound := 0
  
  ; Optional Data auto-loop
  loop % StaffArrayName.Length()
  {
    if (A_Index < 4) {
      ; Index 1 to 3 are processed differently
      Continue
    }
    local LoopStaffArrayName := StaffArrayName[A_Index]
    local LoopStaffArray := %LoopStaffArrayName%
    local LoopStaffArrayData := LoopStaffArray[input] ; Array hash call using input as the key
    if(LoopStaffArrayData) {
      DataFound := 1
      Menu, StaffNameMenu, Add, %LoopStaffArrayData%, StaffNameHandler
    }
  }

  ; End Optional Data auto-loop
  
  Menu, StaffNameMenu, Add
  if (ThisStaffInit) {
    DataFound := 1
    Menu, StaffNameMenu, Add, %ThisStaffInit%, StaffNameHandler
  }
  if (ThisStaffCName) {
    DataFound := 1
    Menu, StaffNameMenu, Add, %ThisStaffCName%, StaffNameHandler
  }
  if (ThisStaffEName) {
    DataFound := 1
    Menu, StaffNameMenu, Add, %ThisStaffEName%, StaffNameHandler
  }
  
  if (!DataFound) {
    returnArr := StaffFieldSearch(input)
    if (returnArr.Length() = 0) {
      returnArr := StaffNameFuzzyLogic(input)
    } 
    for i, e in returnArr
    {
      DataFound := 1
      local ThisInit := e
      local ThisCName := ThisStaffCNameArr[ThisInit]
      local ThisEName := ThisStaffENameArr[ThisInit]
      if (ThisCName) {
        Menu, %ThisInit% (%ThisCName%`, %ThisEName%), Add, %ThisInit%, StaffNameHandler
        Menu, %ThisInit% (%ThisCName%`, %ThisEName%), Add, %ThisCName%, StaffNameHandler
        Menu, %ThisInit% (%ThisCName%`, %ThisEName%), Add, %ThisEName%, StaffNameHandler
        Menu, StaffNameMenu, Add, %ThisInit% (%ThisCName%`, %ThisEName%), :%ThisInit% (%ThisCName%`, %ThisEName%)
      } else {
        Menu, %ThisInit% (%ThisEName%), Add, %ThisInit%, StaffNameHandler
        Menu, %ThisInit% (%ThisEName%), Add, %ThisEName%, StaffNameHandler
        Menu, StaffNameMenu, Add, %ThisInit% (%ThisEName%), :%ThisInit% (%ThisEName%)
      }
    }
  }
  
  if (!DataFound) {
    Menu, StaffNameMenu, Add, No Data Found, dummy
    Menu, StaffNameMenu, Disable, No Data Found
  }
  
  if(MainMenuCategoryTitle) {
    MainMenuTitle .= " - " . MainMenuCategoryTitle
    MainMenuCategoryTitle := 
  }
  Menu, StaffNameMenu, Rename, mainTempTitle, %MainMenuTitle%
  
  Menu, StaffNameMenu, Show
  Menu, StaffNameMenu, Delete
}

StaffNameHandler:
; SendInput, %A_ThisMenuItem%
Clipboard := A_ThisMenuItem
Sleep 10
SendInput, ^v
Sleep 10
Clipboard := TempClip
TempClip :=
return

#IfWinActive Onlink ahk_class SDL_app
RButton::
If (A_TimeSincePriorHotkey<400) and (A_TimeSincePriorHotkey<>-1) {
  Click, R
} else {
  SendInput, {backspace 30}
}
return

Numpad0::
loop, 10 {
  Click
}
return

`::
ClickImage(0, 0, 400, 80, "C:\Users\15ys\Documents\Coding\G\Onlink\TopMenu-PauseButton.png", "", 5, 5)
Sleep 10
WinMinimize, CrissCross
WinMinimize
return

F12::
WinMove, -2, -26
WinSet, AlwaysOnTop, On
return

#IfWinActive Ruckus
^RButton::
  Menu, APAdminMenu, Add, MMLC01MACList
  Menu, APAdminMenu, Show
return

MMLC01MACList() {
  MACList =
  (
  10:68:3F:4E:B0:EB
  B8-8A-60-1E-8F-68
  B8-8A-60-29-E2-80
  B8-8A-60-2A-C9-80
  B8-8A-60-1E-8F-50
  B8-8A-60-1D-A8-9C
  B8-8A-60-29-E0-54
  B8-8A-60-1E-80-74
  B8-8A-60-29-E2-00
  B8-8A-60-29-E1-C4
  B8-8A-60-1E-88-D4
  B8-8A-60-1E-8F-58
  B8-8A-60-2A-C9-A0
  B8-8A-60-1E-88-B4
  B8-8A-60-1E-84-60
  B8-8A-60-2A-D5-10
  B8-8A-60-1E-88-DC
  B8-8A-60-1E-8F-64
  B8-8A-60-2A-CE-70
  B8-8A-60-1E-8F-2C
  B8-8A-60-1E-88-A8
  B8-8A-60-2A-C9-74
  B8-8A-60-2A-CE-50
  B8-8A-60-1E-8F-38
  B8-8A-60-29-E1-D8
  B8-8A-60-1E-88-98
  B8-8A-60-1E-80-AC
  B8-8A-60-2A-C9-90
  B8-8A-60-2A-CE-7C
  B8-8A-60-1E-88-A4
  B8-8A-60-2A-CF-70
  B8-8A-60-1E-8F-60
  B8-8A-60-1E-83-C8
  B8-8A-60-29-D7-C0
  B8-8A-60-1E-80-78
  B8-8A-60-1E-8F-40
  B8-8A-60-2A-CE-68
  B8-8A-60-29-E1-FC
  B8-8A-60-29-E1-F4
  )
  AddMACList(MACList)
}


AddMACList(MACListInput) {
  ; Cleanup Replacements
  MACList := MACListInput
  MACList := StrReplace(MACList, " ")
  MACList := RegExReplace(MACList, "\n\n")

  ; SendInput Conversion Replacements
  MACList := StrReplace(MACList, ":", "{tab}")
  MACList := StrReplace(MACList, "-", "{tab}")
  MACList := RegExReplace(MACList, "\n", "{tab}{tab}{enter}")
  SendInput, %MACList%
}

#IfWinActive Ruckus Wireless Admin
^`::
login := chr(0x73)
login .= chr(0x75)
login .= chr(0x70)
login .= chr(0x65)
login .= chr(0x72)
login .= chr(0x76)
login .= chr(0x69)
login .= chr(0x73)
login .= chr(0x6F)
login .= chr(0x72)

pwd := chr(0x6D)
pwd .= chr(0x6D)
pwd .= chr(0x6C)
pwd .= chr(0x63)
pwd .= chr(0x46)
pwd .= chr(0x31)
pwd .= chr(0x74)
pwd .= chr(0x32)
pwd .= chr(0x36)
pwd .= chr(0x31)
pwd .= chr(0x35)

SendInput, %login%{tab}%pwd%{enter}
return

#IfWinActive Caravan Beast

tab::
SendInput {Click 50}
return

+1::
SendInput {Click 10}
return

+2::
SendInput {Click 20}
return

+3::
SendInput {Click 30}
return

#IfWinActive Kongregate
`::
Click
return

#IfWinActive ahk_exe putty.exe
^`::
pwd := chr(0x48)
pwd .= chr(0x71)
pwd .= chr(0x6D)
pwd .= chr(0x37)
pwd .= chr(0x6F)
pwd .= chr(0x6D)
pwd .= chr(0x72)
pwd .= chr(0x6C)
pwd .= chr(0x31)
pwd .= chr(0x32)
pwd .= chr(0x68)
pwd .= chr(0x61)
pwd .= chr(0x70)
pwd .= chr(0x49)
SendInput, %pwd%{enter}
return

#IfWinActive ahk_exe chrome.exe
^1::
SaveClip()
Clipboard :=
SendInput, ^l
Sleep 100
SendInput, ^c
ClipWait, 1
if (errorlevel) {
  return
}
if (RegExMatch(Clipboard,"http://www.cdgfss.edu.hk/.*") >= 1) {
  ConvertedPath := RegExReplace(Clipboard, ".*http://www.cdgfss.edu.hk", "/var/www/html")
  if (RegExMatch(ConvertedPath, "/?.*/", Match) > 0) {
    CDCmd := Match
    RegExMatch(StrReplace(ConvertedPath, CDCmd), "[^#]+", Match)
    FilenameCmd := Match
    IfWinNotExist, ahk_exe WinSCP.exe
    {
      run, "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\WinSCP.lnk"
      WinWaitActive, ahk_exe WinSCP.exe
      SendInput, CDGFSS{enter}
      WinWaitActive, html - CDGFSS Web - WinSCP ahk_exe WinSCP.exe
    }
    WinActivate, ahk_exe WinSCP.exe
    Sleep 200
    SendInput ^t
    WinWaitActive, Console ahk_exe WinSCP.exe, , 5
    if (ErrorLevel) {
      ToolTip, Console did not open in 5 seconds
      Sleep 1000
      ToolTip
      return
    }
    SendInput, cd %CDCmd%{enter}
    Sleep 200
    SendInput, {esc}
    Sleep 500
    RegExMatch(CDCmd, "/([^/]*)/$", LastDirectory)
    if (LastDirectory1) {
      LastDirectory := LastDirectory1
    } else {
      LastDirectory := "html"
    }
    loop % 5
    {
      IfWinNotActive, %LastDirectory% ahk_exe WinSCP.exe
      {
        SendInput, {tab}
        sleep 100
      } 
    }
    IfWinNotActive, %LastDirectory% ahk_exe WinSCP.exe
    {
      Msgbox, WinSCP is not in the %LastDirectory% folder from the path %CDCmd%
      return
    }
    if (FilenameCmd) {
      ; {tab 2} is sent because having the Queue active will display the remote folder if it was last selected
      SendInput, {tab 2}%FilenameCmd%{enter}
    }
    Sleep 500
    WinActivate, ahk_exe chrome.exe
    WinActivate, ahk_exe notepad++.exe
  } else {
    Msgbox, Could not parse path: %ConvertedPath%
  }
} else {
  ToolTip, Invalid URL: %Clipboard%
  Sleep 1000
  ToolTip
  return  
}
RestoreClip()
return

#IfWinActive ahk_exe WinSCP.exe
^1::
Clipboard =
Sleep 10
SendInput, ^1
ClipWait, 1
if (errorlevel) {
  ToolTip, No Data Received
  Sleep 1000
  ToolTip
  return
}
if (RegExMatch(Clipboard, "https?://.*") >= 1) {
  Run, %Clipboard%
} else {
  ToolTip, Non-URL data received: %Clipboard%
  Sleep 1000
  ToolTip
  return  
}
return

#IfWInActive Notepad++
^+v::
; SavedClipboard := ClipboardAll
; Clipboard = %Clipboard%
; Clipboard := StrReplace(Clipboard, " ")
; Clipboard := RegExReplace(Clipboard, "\t", " ")
; Clipboard := RegExReplace(Clipboard, "[\r\n\cA-\cZ]")
Clipboard := RegExReplace(Clipboard, "\r\n")
; SendInput, ^v{home 2}
SendInput, ^v
Sleep 10
; Clipboard := SavedClipboard
SavedClipboard =
return

^LButton::
SendInput, {Click 3}
return

^!+v::
Clipboard = %Clipboard%
Clipboard := RegExReplace(Clipboard, "\t", " ")
Clipboard := RegExReplace(Clipboard, "\r\n", ",")
SendInput, ^v
Sleep 10
SavedClipboard =
return

^+`::
SendInput, {enter}<link href="/common/chinese.css" rel="stylesheet" type="text/css" />
return

^`::
Clipboard =
SendInput, ^x
ClipWait, 1
Clipboard := "<span class=""name"">" . Trim(Clipboard) . "</span>"
SendInput, ^v
return

^1::
Clipboard =
SendInput, ^x
ClipWait, 1
Clipboard := "<h1>" . Trim(Clipboard) . "</h1>"
SendInput, ^v
return

^2::
Clipboard =
SendInput, ^x
ClipWait, 1
Clipboard := "<h2>" . Trim(Clipboard) . "</h2>"
SendInput, ^v
return

^3::
Clipboard =
SendInput, ^x
ClipWait, 1
Clipboard := "<h3>" . Trim(Clipboard) . "</h3>"
SendInput, ^v
return

^4:: ; <ul> tag
Clipboard =
SendInput, ^x
ClipWait, 1
Clipboard := "<ul>`r`n" . Trim(Clipboard) . "`r`n</ul>"
SendInput, ^v
return

^7:: ; <p> tag
Clipboard =
SendInput, ^x
ClipWait, 1
Clipboard := "    <p>" . Trim(Clipboard) . "</p>"
Clipboard := RegExReplace(Clipboard, "\r\n\r\n", "</p>`r`n    <p>")
Clipboard := RegExReplace(Clipboard, "\r\n[ ]*", "`r`n    ")
SendInput, ^v
return

^+8::
SendInput, <div style="clear: both;"></div>
return

^+!8::  ; image float right setup
Clipboard =
SendInput, ^x
ClipWait, 1
Clipboard := RegExReplace(Clipboard, "^ *http://www.cdgfss.edu.hk(.*)", "    <img class=""thirdWidth"" src=""$1""`r`n   >")
Clipboard := RegExReplace(Clipboard, "\r\n *http://www.cdgfss.edu.hk(.*)", "<img class=""thirdWidth"" src=""$1""`r`n   >")
SendInput, ^v
return

^8::  ; image float right setup
Clipboard =
SendInput, ^x
ClipWait, 1
Clipboard := RegExReplace(Clipboard, "http://www.cdgfss.edu.hk(.*)", "  <img class=""fullWidth"" src=""$1"">")
Clipboard := "    <div class=""rightSideImage"">`r`n" . Clipboard . "`r`n    </div>`r`n"
Clipboard := RegExReplace(Clipboard, "\r\n\r\n", "`r`n")
SendInput, ^v
return

^9:: ; Break long line into multi-line
Clipboard =
SendInput, ^x
ClipWait, 1
NewClipboard := RegExReplace(Clipboard, "(.{60}) ", "$1`r`n    ")
if (Clipboard == NewClipboard) {
  Clipboard := RegExReplace(Clipboard, "(.{40})", "$1`r`n    ") ; Chinese mode, no spaces.
} else {
  Clipboard := NewClipboard
}
SendInput, ^v
return

^0:: ; convert from comma list with line breaks to <ul> list
Clipboard =
SendInput, ^x
ClipWait, 1
Clipboard := RegExReplace(Clipboard, "\t", " ")
Clipboard := RegExReplace(Clipboard, ", ", "`r`n")
Clipboard := RegExReplace(Clipboard, ",", "")
Clipboard := RegExReplace(Clipboard, "\r\n\r\n", "`r`n")
Clipboard := RegExReplace(Clipboard, "(^|\r\n)[ ]*S?", "$1  <li>")
Clipboard := RegExReplace(Clipboard, "[ ]*($|\r\n)", "</li>$1")
Clipboard := "<ul>`r`n" . Clipboard . "`r`n</ul>"
if (InStr(Clipboard, "<li>", , , 5)) {
  Clipboard := RegExReplace(Clipboard, "(^|\r\n)", "$1  ")
  Clipboard := "<div class=""namelist"">`r`n" . Clipboard . "`r`n</div>"
}
Clipboard := RegExReplace(Clipboard, "(^|\r\n)", "$1    ")
SendInput, ^v
return

^+0:: ; add <h3> to non-student names
Clipboard =
SendInput, ^x
ClipWait, 1
Clipboard := RegExReplace(Clipboard, "(^|\r\n)([^0-9S][^\r\n]+)", "$1    <h3>$2</h3>")
SendInput, ^v
return

^+!0:: ; Clean HTML attributes
Clipboard =
SendInput, ^x
ClipWait, 1
Clipboard := RegExReplace(Clipboard, "(<[a-z]+) [^/>]*>", "$1>")
Clipboard := RegExReplace(Clipboard, "(^|\r\n) +", "`r`n")
Clipboard := RegExReplace(Clipboard, ">\r\n", "> ")
SendInput, ^v
return

:*://la::
SendInput, {raw}<script>listAwards("||");</script>
SendInput, {left 14}
return

#IfWinActive Endless Expansion
1::
SendInput, {Click 200}
return

#IfWinActive Battle Pirates
`::
click
return

tab::
click, 2
return

RButton::
Send, {up}
Click
return

MButton::
Send, {RButton}
return

#IfWinActive Kittens Game
Numpad0::
loop, 10
{
  Click
}
return

^Numpad0::
loop
{
  Click
  Sleep 70
}

#IfWinActive Kindle Cloud Reader

Numpad0::
loop, 100
{
SendInput, {PrintScreen}
Sleep 500
SendInput, {Right}
Sleep 1500
}
return

#IfWinActive Avernum
Numpad0::
`::
Click
return

tab::
if (!ClickIsDown) {
  Click down
}
ClickIsDown := 1

return

tab up::
Click up
ClickIsDown := 0
return

#IfWinActive Cosmic Raiders
1::
MouseGetPos, CosmicRaiderX, CosmicRaiderY
return

2::
Click %CosmicRaiderX%, %CosmicRaiderY%
return

#IfWinActive Star Wars
`::
Click
return

; #IfWinActive ahk_exe chrome.exe
#IfWinActive ahk_group ADarkRoom
`::
Click
return

^`::
loop, 100 {
  Click
  Sleep 100
}
return

+`::
loop, 10 {
  Click
  Sleep 100
}
return


tab::
SendInput {Click 50}
return

+1::
SendInput {Click 10}
return

+2::
SendInput {Click 20}
return

+3::
SendInput {Click 30}
return


return

#IfWinActive Google Calendar
`::
SendInput, {Click 3}7:30pm{tab}10:00pm
return

#IfWinActive

^NumpadMult::
  Send {Media_Next}
return

^NumpadDiv::
  Send {Media_Prev}
return

^Numpad0::
^NumpadEnter::
  Send {Media_Play_Pause}
return

^NumpadSub::
  Send {Media_Stop}
return

^+NumpadSub::
  Send {Volume_Mute}
return

^+NumpadMult::
  Send {Volume_Up 1}
return

^+NumpadDiv::
  Send {Volume_Down 1}
return

^RButton::
TempClip := ClipboardAll
Clipboard :=
SendInput, ^c
ClipWait, 0.1
If (ErrorLevel) {
  Clipboard := TempClip
  TempClip :=
  SendInput, ^{RButton}
} else {
  StaffNameMenu(Trim(Clipboard))
}
return

+!^`::
SetFormat, INTEGER, H
; Convert a string to chr(##) code
FieldContent := ""
FieldName = pwd
Output =
Loop, Parse, FieldContent
{
   Output .= FieldName " .= chr(" . Asc(A_LoopField) . ")`r`n"
}
Msgbox, %Output%
Clipboard := Output
return

; +`::
return

; `::
return

^`::
WinMinimize, A
return