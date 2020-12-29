myAOBInjectionTemplates = {}

myAOBInjectionTemplates.Templates = {

{
displayName="Mảng thay thế",
submenu='Mẫu tiêm mảng tùy chỉnh',
templateSections=
[==[
<<INFO>>
// Tiến trình        : %processName%
// Tác giả           : %authorName%
// Phiên bản exe     : %exeVersion%
// Phiên bản mô-đun  : %moduleVersion%
// Ngày kịch bản     : %scriptDate%
// Được tạo với      : customAOBInjectionTemplates phiên bản: %extensionVersion%
<<INFO_END>>

<<ENABLE>>
aobscan%isModuleScan%(aob_%cheatName%,%moduleNameC%%searchPattern%)
registersymbol(aob_%cheatName%)
alloc(newmem_%cheatName%,1024%CmoduleName%)
label(return_%cheatName%)

newmem_%cheatName%:
%_originalCodeLines%
  jmp return_%cheatName%

aob_%cheatName%%aobAdjust%:
  jmp newmem_%cheatName%
%_nopLines%
return_%cheatName%:

<<ENABLE_END>>

<<DISABLE>>
aob_%cheatName%%aobAdjust%:
  db %originalBytes%

unregistersymbol(aob_%cheatName%)
dealloc(newmem_%cheatName%)

%additionalInfo%
<<DISABLE_END>>
]==]
},




{
displayName="Mảng thay thế với dấu ngoặc bù",
submenu='Mẫu tiêm mảng tùy chỉnh',
templateSections=
[==[
<<INFO>>
// Tiến trình        : %processName%
// Tác giả           : %authorName%
// Phiên bản exe     : %exeVersion%
// Phiên bản mô-đun  : %moduleVersion%
// Ngày kịch bản     : %scriptDate%
// Được tạo với      : customAOBInjectionTemplates phiên bản: %extensionVersion%
<<INFO_END>>

<<ENABLE>>
aobscan%isModuleScan%(aob_%cheatName%,%moduleNameC%%searchPattern%)
registersymbol(aob_%cheatName%)
alloc(newmem_%cheatName%,1024%CmoduleName%)
label(return_%cheatName%)
label(set_%cheatName%)
label(quit_%cheatName%)

newmem_%cheatName%:
  jmp quit_%cheatName%

set_%cheatName%:
  mov %bracketsRegsOffset%,0
  //jmp quit_%cheatName%

quit_%cheatName%:
%_originalCodeLines%
  jmp return_%cheatName%

aob_%cheatName%%aobAdjust%:
  jmp newmem_%cheatName%
%_nopLines%
return_%cheatName%:

<<ENABLE_END>>

<<DISABLE>>
aob_%cheatName%%aobAdjust%:
  db %originalBytes%

unregistersymbol(aob_%cheatName%)
dealloc(newmem_%cheatName%)

%additionalInfo%
<<DISABLE_END>>
]==]
},




{
displayName="Mảng thay thế với lén lút",
submenu='Mẫu tiêm mảng tùy chỉnh',
templateSections=
[==[
<<INFO>>
// Tiến trình        : %processName%
// Tác giả           : %authorName%
// Phiên bản exe     : %exeVersion%
// Phiên bản mô-đun  : %moduleVersion%
// Ngày kịch bản     : %scriptDate%
// Được tạo với      : customAOBInjectionTemplates phiên bản: %extensionVersion%
<<INFO_END>>

<<ENABLE>>
aobscan%isModuleScan%(aob_%cheatName%,%moduleNameC%%searchPattern%)
stealtheditex(See_%cheatName%,aob_%cheatName%%aobAdjust%,3)
label(SeeReg_%cheatName%)
registersymbol(SeeReg_%cheatName%)
alloc(newmem_%cheatName%,1024%CmoduleName%)
label(return_%cheatName%)

newmem_%cheatName%:
%_originalCodeLines%
  jmp return_%cheatName%

See_%cheatName%:
SeeReg_%cheatName%:
  jmp newmem_%cheatName%
%_nopLines%
return_%cheatName%:

<<ENABLE_END>>

<<DISABLE>>
SeeReg_%cheatName%:
  db %originalBytes%

unregistersymbol(SeeReg_%cheatName%)
dealloc(newmem_%cheatName%)

%additionalInfo%
<<DISABLE_END>>
]==]
},




{
displayName="Tiêm săn mồi mono",
submenu="Mẫu tiêm mảng săn mồi",
templateSections=
[==[
<<INFO>>
// Tiến trình        : %processName%
// Tác giả           : %authorName%
// Phiên bản exe     : %exeVersion%
// Phiên bản mô-đun  : %moduleVersion%
// Ngày kịch bản     : %scriptDate%
// Được tạo với      : customAOBInjectionTemplates phiên bản: %extensionVersion%
<<INFO_END>>

<<ENABLE>>
alloc(newmem_%cheatName%,1024%CmoduleName%)
label(%cheatName%)
registersymbol(%cheatName%)
label(return_%cheatName%)

newmem_%cheatName%:
%_originalCodeLines%
  jmp return_%cheatName%

%monoAddress%:
%cheatName%:
  jmp newmem_%cheatName%
%_nopLines%
return_%cheatName%:

<<ENABLE_END>>

<<DISABLE>>
%cheatName%:
  db %originalBytes%

unregistersymbol(%cheatName%)
dealloc(newmem_%cheatName%)

%additionalInfo%
<<DISABLE_END>>
]==]
},




{
displayName="Mảng csimbi; mục tiêu tiến trình",
submenu="Mẫu tiêm mảng csimbi",
group='normal',
templateSections=
[==[
<<INFO>>
// Tiến trình        : %processName%
// Tác giả           : %authorName%
// Phiên bản exe     : %exeVersion%
// Phiên bản mô-đun  : %moduleVersion%
// Ngày kịch bản     : %scriptDate%
// Được tạo với      : customAOBInjectionTemplates phiên bản: %extensionVersion%
<<INFO_END>>

<<ENABLE>>
{$lua}
return string.format([[
aobscanmodule(aob%cheatName%,%s,%searchPattern%)
]],process)
{$asm}

alloc(newmem%cheatName%,4096,aob%cheatName%)

label(aob%cheatName%_r)
label(aob%cheatName%_i)
registersymbol(aob%cheatName%_r)
registersymbol(aob%cheatName%_i)

label(lbl%cheatName%)
label(lbl%cheatName%Skip)
label(lbl%cheatName%Ret)

label(bEnable%cheatName%)
registersymbol(bEnable%cheatName%)

newmem%cheatName%:
bEnable%cheatName%:
dd 1

lbl%cheatName%:
%CoriginalCodeLines%
//db %originalBytes%
readmem(aob%cheatName%%aobAdjust%,%replacedInstructionsSize%)

cmp dword ptr [bEnable%cheatName%],1
jne short lbl%cheatName%Skip
// Place your code here

lbl%cheatName%Skip:
jmp lbl%cheatName%Ret
aob%cheatName%_i:
readmem(aob%cheatName%%aobAdjust%,%replacedInstructionsSize%)

//%injectAddress%:
aob%cheatName%%aobAdjust%:
aob%cheatName%_r:
jmp lbl%cheatName%
%nopLines%
lbl%cheatName%Ret:

<<ENABLE_END>>

<<DISABLE>>
//%injectAddress%:
%CoriginalCodeLines%
//db %originalBytes%
aob%cheatName%_r:
readmem(aob%cheatName%_i,%replacedInstructionsSize%)

unregistersymbol(aob%cheatName%_r)
unregistersymbol(aob%cheatName%_i)

unregistersymbol(bEnable%cheatName%)

dealloc(newmem%cheatName%)

%additionalInfo%
<<DISABLE_END>>

]==]
},

{
displayName="Mảng csimbi; mục tiêu mô-đun",
submenu="Mẫu tiêm mảng csimbi",
group='normal',
templateSections=
[==[
<<INFO>>
// Tiến trình        : %processName%
// Tác giả           : %authorName%
// Phiên bản exe     : %exeVersion%
// Phiên bản mô-đun  : %moduleVersion%
// Ngày kịch bản     : %scriptDate%
// Được tạo với      : customAOBInjectionTemplates phiên bản: %extensionVersion%
<<INFO_END>>

<<ENABLE>>
aobscan%isModuleScan%(aob%cheatName%,%moduleNameC%%searchPattern%)

alloc(newmem%cheatName%,4096,aob%cheatName%)

label(aob%cheatName%_r)
label(aob%cheatName%_i)
registersymbol(aob%cheatName%_r)
registersymbol(aob%cheatName%_i)

label(lbl%cheatName%)
label(lbl%cheatName%Skip)
label(lbl%cheatName%Ret)

label(bEnable%cheatName%)
registersymbol(bEnable%cheatName%)

newmem%cheatName%:
bEnable%cheatName%:
dd 1

lbl%cheatName%:
%CoriginalCodeLines%
//db %originalBytes%
readmem(aob%cheatName%%aobAdjust%,%replacedInstructionsSize%)

cmp dword ptr [bEnable%cheatName%],1
jne short lbl%cheatName%Skip
// Place your code here

lbl%cheatName%Skip:
jmp lbl%cheatName%Ret
aob%cheatName%_i:
readmem(aob%cheatName%%aobAdjust%,%replacedInstructionsSize%)

//%injectAddress%:
aob%cheatName%%aobAdjust%:
aob%cheatName%_r:
jmp lbl%cheatName%
%nopLines%
lbl%cheatName%Ret:

<<ENABLE_END>>

<<DISABLE>>
//%injectAddress%:
%CoriginalCodeLines%
//db %originalBytes%
aob%cheatName%_r:
readmem(aob%cheatName%_i,%replacedInstructionsSize%)

unregistersymbol(aob%cheatName%_r)
unregistersymbol(aob%cheatName%_i)

unregistersymbol(bEnable%cheatName%)

dealloc(newmem%cheatName%)

%additionalInfo%
<<DISABLE_END>>

]==]
},

{
displayName="Lấy bù mảng; mục tiêu tiến trình",
submenu="Mẫu tiêm mảng csimbi",
group='offset grab',
templateSections=
[==[
<<INFO>>
// Tiến trình        : %processName%
// Tác giả           : %authorName%
// Phiên bản exe     : %exeVersion%
// Phiên bản mô-đun  : %moduleVersion%
// Ngày kịch bản     : %scriptDate%
// Được tạo với      : customAOBInjectionTemplates phiên bản: %extensionVersion%
<<INFO_END>>

<<ENABLE>>
{$lua}
return string.format([[
aobscanmodule(aob%cheatName%,%s,%searchPattern%)
]],process)
{$asm}
// %searchPattern%
// 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F 20 21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F 30 31 32 33 34 35 36 37 38 39 3A 3B 3C 3D 3E 3F

alloc(newmem%cheatName%,4096,aob%cheatName%)

label(i%cheatName%)
registersymbol(i%cheatName%)

newmem%cheatName%:
i%cheatName%:
readmem(aob%cheatName%+XX,YY)

<<ENABLE_END>>

<<DISABLE>>

unregistersymbol(i%cheatName%)

dealloc(newmem%cheatName%)

%additionalInfo%
<<DISABLE_END>>

]==]
},

{
displayName="Lấy bù mảng; mục tiêu mô-đun",
submenu="Mẫu tiêm mảng csimbi",
group='offset grab',
templateSections=
[==[
<<INFO>>
// Tiến trình        : %processName%
// Tác giả           : %authorName%
// Phiên bản exe     : %exeVersion%
// Phiên bản mô-đun  : %moduleVersion%
// Ngày kịch bản     : %scriptDate%
// Được tạo với      : customAOBInjectionTemplates phiên bản: %extensionVersion%
<<INFO_END>>

<<ENABLE>>
aobscan%isModuleScan%(aob%cheatName%,%moduleNameC%%searchPattern%)
// %searchPattern%
// 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F 20 21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F 30 31 32 33 34 35 36 37 38 39 3A 3B 3C 3D 3E 3F

alloc(newmem%cheatName%,4096,aob%cheatName%)

label(i%cheatName%)
registersymbol(i%cheatName%)

newmem%cheatName%:
i%cheatName%:
readmem(aob%cheatName%+XX,YY)

<<ENABLE_END>>

<<DISABLE>>

unregistersymbol(i%cheatName%)

dealloc(newmem%cheatName%)

%additionalInfo%
<<DISABLE_END>>

]==]
},


}

local extensionVersion = '1.3.6'

function myAOBInjectionTemplates.formCreateNotify(form)
  if form.ClassName~="TfrmAutoInject" then return end

  local timer=createTimer()
  timer.Interval=100
  timer.OnTimer = function (t)
                    if (form.Menu==nil) then return end
                    t.destroy()
                    myAOBInjectionTemplates.addMenuEntries(form)
                  end
end

function myAOBInjectionTemplates.addMenuEntries(form)
  local m,mi,sm=form.emplate1,nil,nil
  local createdSubmenus={}
  local lastMenuItemFromGroup={}
  local smIndex = 1

  mi = createMenuItem(m); m.add(mi); mi.Caption = '-' -- separator

  for i=1,#myAOBInjectionTemplates.Templates do
    local submenu = myAOBInjectionTemplates.Templates[i].submenu
    local group = myAOBInjectionTemplates.Templates[i].group
    local groupname=(submenu or '')..(group or '')

    if submenu~=nil then
      if createdSubmenus[submenu] then
        sm=createdSubmenus[submenu]
      else
        sm = createMenuItem(m); m.add(sm)
        sm.Caption = submenu
        sm.Name = 'miAlternativeAOBtemplateSubmenu'..smIndex; smIndex=smIndex+1
        createdSubmenus[submenu]=sm
      end
    else
      sm=m
    end

    if lastMenuItemFromGroup[groupname]==nil then
      if sm.Count>0 then
        mi = createMenuItem(m); sm.add(mi); mi.Caption = '-' -- separator
      end
      mi = createMenuItem(m); sm.add(mi)
      lastMenuItemFromGroup[groupname]=mi
    else
      mi = createMenuItem(m); sm.insert(lastMenuItemFromGroup[groupname].MenuIndex+1, mi)
      lastMenuItemFromGroup[groupname]=mi
    end

    mi.OnClick = function (sender)
                  myAOBInjectionTemplates.generate(sender,myAOBInjectionTemplates.Templates[i])
                 end
    mi.Caption = myAOBInjectionTemplates.Templates[i].displayName
    mi.Name = 'miAlternativeAOBtemplate'..i
  end
end

registerFormAddNotification(myAOBInjectionTemplates.formCreateNotify)



function myAOBInjectionTemplates.generate(sender,chosenTemplate)

  local displayName = chosenTemplate.displayName
  local cheatName = chosenTemplate.defaultSymbolName or 'example'
  local template = chosenTemplate.templateSections
  local form=sender.Owner.Owner
  local origScript = form.Assemblescreen.Lines.Text

  --gather existing names from origScript from registersymbol
  local existingNames = {}
  for existingName in origScript:gmatch('registersymbol%(%s*(.-)%s*%)') do
    existingNames[1+#existingNames] = existingName
  end
  -- also from define
  for existingName in origScript:gmatch('define%(%s*(.-)%s*,') do
    existingNames[1+#existingNames] = existingName
  end

  local function checkForCollides(str)
    for i,v in ipairs(existingNames) do
      if v:find(str, 1, true)~=nil then return 'Tên "'..str..'" va chạm với "'..v..'" đang có' end
      if str:find(v, 1, true)~=nil then return 'Hiện có "'..v..'" va chạm với tên "'..str..'"' end
    end
    return nil
  end

  local address = 0
  if form.owner.DisassemblerView then
    address = form.owner.DisassemblerView.SelectedAddress
  else
    address = getMemoryViewForm().DisassemblerView.SelectedAddress
  end

  --try to find module name+offset
  local selectedAddress = getNameFromAddress(address)
  local modulesTable,size = enumModules(),0
  local exeVersionStr = ''
  local moduleVersionStr=''
  for i,v in pairs(modulesTable) do
    size = getModuleSize(v.Name)
    if size~=nil and (address>=v.Address and address<=v.Address+size)
      then
        if i~=1 then
          local _,moduleVersionTbl = getFileVersion(v.PathToFile)
          moduleVersionStr = moduleVersionTbl==nil and '' or (moduleVersionTbl.major..'.'..moduleVersionTbl.minor..'.'..
                                                                  moduleVersionTbl.release..'.'..moduleVersionTbl.build)
        end
        selectedAddress = '"'..v.Name..'"+'..string.format('%X',address-v.Address)
        break
      end
  end

  local _,exeVersionTbl = getFileVersion(modulesTable[1].PathToFile)
  local exeVersionStr = exeVersionTbl==nil and '' or (exeVersionTbl.major..'.'..exeVersionTbl.minor..'.'..
                                                      exeVersionTbl.release..'.'..exeVersionTbl.build)

  selectedAddress=inputQuery(displayName,'Bạn muốn nhảy vào địa chỉ nào?', selectedAddress)
  if selectedAddress==nil then return end

  cheatName=inputQuery(displayName,'Bạn muốn đặt tên ký hiệu cho điểm tiêm là gì?', cheatName)
  if cheatName==nil then return end

  ::setValidname:: --do not allow default name or those already existing/colliding or empty
  while cheatName:lower()=='inject' or
        cheatName=='' do
    cheatName=inputQuery('Chú ý!', 'Tên xấu. Thay đổi nó.', cheatName) or ''
    cheatName=cheatName:gsub('%s','') -- remove spaces
  end

  -- check if already exist or collides with each other
  local collides = checkForCollides(cheatName)
  if collides~=nil then
    cheatName=inputQuery('Chú ý!', collides..'. Thay đổi nó.', cheatName) or ''
    cheatName=cheatName:gsub('%s','') -- remove spaces
    goto setValidname
  end

  local newScript_stringlist = createStringlist()
  local gaobisResult = generateAOBInjectionScript(newScript_stringlist, cheatName, selectedAddress)
  local newScript = newScript_stringlist.Text
  newScript_stringlist.destroy()

  -- is process opened?
  if newScript:match('No Process Selected') then showMessage("Không có tiến trình nào được chọn!") return end

  -- is aob unique?
  if newScript:match('Could not find unique AOB') then
    showMessage("Cảnh báo. Không thể tìm thấy mảng duy nhất.")
    newScript = newScript:gsub('ERROR: Could not find unique AOB,','ERROR: Could not find unique AOB;')
  end

  if not gaobisResult
  then showMessage("generateAOBInjectionScript nêu ra ngoại lệ!") return end


  -- note: 'origScript' and 'newScript' will have "carriage return & line feed" at the end of each line
  --       because it is taken from TStrings object.
  --       'template' has only "line feed"


  local authorName    = newScript:match('Author : (.-)\r\n')
  local processName   = newScript:match('Game   : (.-)\r\n')
  local scriptDate   = newScript:match('Date   : (.-)\r\n')
  local isModuleScan  = newScript:match('aobscan(module)') or ''
  local searchPattern = newScript:match('aobscan.-%(.*,(.-)%) // should be unique')

  local moduleName, moduleName_comma, comma_moduleName

  if isModuleScan=='module' then
    moduleName = newScript:match('aobscan.-%(.-,(.-),.-%)')
    moduleName_comma = moduleName..','
    comma_moduleName = ','..moduleName
  else
    moduleName = ''
    moduleName_comma = ''
    comma_moduleName = ''
  end

  local _originalCodeLines = newScript:match('code:\r\n(.-)\r\n  jmp return')
  local aobAdjust          = newScript:match('code:.-jmp return\r\n\r\n'..cheatName..'(.-):')
  local _nopLines          = newScript:match('  jmp code\r\n(.-)\r\nreturn:') or ''

  if _nopLines=='' then  -- other case
        _nopLines          = newScript:match('  jmp newmem\r\n(.-)\r\nreturn:') or ''
  end

  local originalBytes      = newScript:match('  db (.-)\r\n')
  local additionalInfo     = newScript:match('{\r\n// ORIGINAL CODE %- INJECTION POINT.*')

  local origfirstLine = (_originalCodeLines..'\r\n'):match( "(.-)\r\n" )
  local bracketsRegsOffset  = origfirstLine:match('[dq]?word ptr %[.-%]')
                           or origfirstLine:match('byte ptr %[.-%]')
                           or origfirstLine:match('%[.-%]')
                           or ''
  local regsOffset = origfirstLine:match('%[(.-)%]') or ''

  local originalCodeLines = _originalCodeLines:sub(3):gsub('\r\n  ','\r\n')       -- indent less version
  local nopLines = _nopLines=='' and '' or _nopLines:sub(3):gsub('\r\n  ','\r\n') -- indent less version
  local CoriginalCodeLines = '//Alt: '.._originalCodeLines:sub(3):gsub('\r\n  ','\r\n//Alt: ')-- commented version

  local db90s=''
  if _nopLines~='' then
    if _nopLines:match('  nop (%x+)') then --CE7.0 and above has '  nop '+inttohex(NopCount)
      local nopNumber = tonumber(_nopLines:match('  nop (%x+)'),16)
      db90s = 'db'..string.rep(" 90", nopNumber)
    else --up to CE6.8.3
      db90s = 'db'..(nopLines..'\r\n'):gsub('nop\r\n',' 90')
    end
  end

  local _,replacedInstructionsSize = originalBytes:gsub('%x%x','')
  local replacedInstructionsSizeHex = string.format('%X',replacedInstructionsSize)


  --Mono & Hook Address
  local injectAddress = newScript:match('INJECTING HERE %-%-%-%-%-%-%-%-%-%-\r\n(.-):')
  local injectAddressNum = getAddress(injectAddress)
  local monoAddress = ''
  if template:find('%%monoAddress%%') then -- remove lag for templates without mono
    if LaunchMonoDataCollector~=nil and LaunchMonoDataCollector()~=0 then
      monoAddress = mono_addressLookupCallback(injectAddressNum) or ''
    end
  end

  --reassembleReplacedInstructions
  local tmp = getInstructionSize(injectAddressNum)
  local reassembleReplacedInstructions = 'reassemble(~)'
  while tmp < replacedInstructionsSize do
    reassembleReplacedInstructions = reassembleReplacedInstructions .. '\nreassemble(~+'..string.format('%X',tmp)..')'
    tmp = tmp + getInstructionSize(injectAddressNum+tmp)
  end

  -- use the template
  template = template:gsub('%%cheatName%%', cheatName)
  template = template:gsub('%%authorName%%', authorName)
  template = template:gsub('%%processName%%', processName)
  template = template:gsub('%%isModuleScan%%', isModuleScan)
  template = template:gsub('%%searchPattern%%', searchPattern)
  template = template:gsub('%%CmoduleName%%', comma_moduleName)
  template = template:gsub('%%moduleNameC%%', moduleName_comma)
  template = template:gsub('%%moduleName%%', moduleName)
  template = template:gsub('%%replacedInstructionsSize%%', replacedInstructionsSize)
  template = template:gsub('%%replacedInstructionsSizeHex%%', replacedInstructionsSizeHex)
  template = template:gsub('%%_originalCodeLines%%', _originalCodeLines)
  template = template:gsub('%%originalCodeLines%%', originalCodeLines)
  template = template:gsub('%%CoriginalCodeLines%%', CoriginalCodeLines)
  template = template:gsub('%%originalBytes%%', originalBytes)
  template = template:gsub('%%aobAdjust%%', aobAdjust)
  template = template:gsub('%%additionalInfo%%', additionalInfo)
  template = template:gsub('%%bracketsRegsOffset%%', bracketsRegsOffset)
  template = template:gsub('%%regsOffset%%', regsOffset)
  template = template:gsub('%%injectAddress%%', injectAddress)
  template = template:gsub('%%monoAddress%%', monoAddress)
  template = template:gsub('%%reassembleReplacedInstructions%((.-)%)%%', function (a)
    return reassembleReplacedInstructions:gsub('~',a)
  end)
  template = template:gsub('%%scriptDate%%', scriptDate)
  template = template:gsub('%%exeVersion%%', exeVersionStr)
  template = template:gsub('%%moduleVersion%%', moduleVersionStr)

  if db90s~='' then
   template = template:gsub('%%nopLines%%', nopLines)
   template = template:gsub('%%_nopLines%%', _nopLines)
   template = template:gsub('%%db90s%%', db90s)
  else
   -- remove whole line when NOP'ing is not needed
   template = template:gsub('%%nopLines%%.-\n', '')
   template = template:gsub('%%_nopLines%%.-\n', '')
   template = template:gsub('%%db90s%%.-\n', '')
  end

  template = template:gsub('%%extensionVersion%%', extensionVersion)

  local enablePart  = template:match('<<ENABLE>>.(.*).<<ENABLE_END>>')
  local disablePart = template:match('<<DISABLE>>.(.*).<<DISABLE_END>>')
  local infoPart = template:match('<<INFO>>.(.*).<<INFO_END>>')

  if origScript=='\r\n' then origScript='' end --after manually deleting all lines, there's always one empty line

  local pos=origScript:find('%[DISABLE]')
  if pos then newScript=origScript:sub(1,pos-1)..'\r\n'..enablePart..'\r\n'..origScript:sub(pos)..'\r\n'..disablePart
         else newScript=origScript..'[ENABLE]\r\n'..enablePart..'\r\n[DISABLE]\r\n'..disablePart
  end

  if pos==nil and infoPart~=nil then newScript=infoPart..'\r\n'..newScript end

  form.Assemblescreen.Lines.Text = newScript -- update
end
