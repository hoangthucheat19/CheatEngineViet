--[[
init script for the stealtheditor plugin
stealthedit adds 2 new functions:
  reguard() : Will set the guard protection flags on stealthedited pages
  stealthedit(address, size): Does a full module copy stealthedit and returns the address

It also adds one variable: 
  stealtheditpath : Path to the location of the stealthedit dll (Contains the dir seperator at the end)
--]]


function cbFindIntegrityCheckChange(sender)
  --gui stuff
  control_setEnabled(frmSESettings_cbRewatch, checkbox_getState(frmSESettings_cbFindIntegrityCheck)==cbChecked)
  control_setEnabled(frmSESettings_edtTime, checkbox_getState(frmSESettings_cbFindIntegrityCheck)==cbChecked)
  control_setEnabled(frmSESettings_lblMilliseconds, checkbox_getState(frmSESettings_cbFindIntegrityCheck)==cbChecked)
end

function btnApplyClick(sender)
  stealthedit_FindIntegrity=checkbox_getState(frmSESettings_cbFindIntegrityCheck)==cbChecked
  stealthedit_Rewatch=checkbox_getState(frmSESettings_cbRewatch)==cbChecked
  stealthedit_RewatchTimer=tonumber(control_getCaption(frmSESettings_edtTime))
end


createFormFromFile(stealtheditpath..'sesettings.FRM')
createFormFromFile(stealtheditpath..'results.FRM')


function ShowSEWindow()
  if stealthedit_FindIntegrity==true then
    form_show(frmResults)
  end
end

stealthedit_FindIntegrity=false --this variablename is queried by the stealthedit plugin to determine if the memory should be guarded on stealthedit (don't change it)
--set to true if you wish it on by default. Also add this then:
--checkbox_setState(frmSESettings_cbFindIntegrityCheck, cbChecked) 

stealthedit_Rewatch=false
stealthedit_RewatchTimer=100



function onreguard(sender)
  timer_setEnabled(sender, false)
  reguard()
end


se_events={}

function IntegrityUpdate(rax, rbx, rcx, rdx, rsi, rdi, rbp, rsp, rip, r8, r9, r10, r11, r12, r13, r14, r15, stackcopy, stacksize)
  --A page that was guarded has been accessed (and made unguarded)
  if (control_getVisible(frmResults)==false) then
    ShowSEWindow()
  end

  --check if this rip address is already in the list, and if not, add it 


  if (se_events[rip]==nil) then
    --new, add it (don't add/update any other ones with this rip, those don't come with a stackcopy/stacksize)
    se_events[rip]={rax=rax, rbx=rbx, rcx=rcx, rdx=rdx, rsi=rsi, rdi=rdi, rbp=rbp, rsp=rsp, rip=rip, r8=r8, r9=r9, r10=r10, r11=r11, r12=r12, r13=r13, r14=r14, r15=r15, stackcopy=stackcopy, stacksize=stacksize} 
    local items=listbox_getItems(frmResults_lbAddresses)
    strings_add(items, string.format('%08X', rip))    

    if listbox_getItemIndex(frmResults_lbAddresses)==-1 then
      listbox_setItemIndex(frmResults_lbAddresses,0)
    end
  end



  if (stealthedit_Rewatch) then
    if (reguardtimer==nil) then
      reguardtimer=createTimer(nil, false)
      timer_onTimer(reguardtimer, onreguard)
    end

    timer_setInterval(reguardtimer, stealthedit_RewatchTimer)
    timer_setEnabled(reguardtimer, true)
  end
end           


function lbAddressesSelectionChange(sender, user)
 -- showMessage('selection changed')
 -- frmResults_lbAddresses
 -- frmResults_mData
  local is64bit=targetIs64Bit()
  local items=listbox_getItems(frmResults_lbAddresses)
  local itemindex=listbox_getItemIndex(frmResults_lbAddresses)    
  local event=se_events[tonumber('0x'..strings_getString(items, itemindex))]

  edit_clear(frmResults_mData)
  
  if is64bit then
    prefix='R'
  else
    prefix='E'
  end  

    
  memo_append(frmResults_mData,prefix..'AX = '..string.format('%08X',event.rax))
  memo_append(frmResults_mData,prefix..'BX = '..string.format('%08X',event.rbx))
  memo_append(frmResults_mData,prefix..'CX = '..string.format('%08X',event.rcx))
  memo_append(frmResults_mData,prefix..'DX = '..string.format('%08X',event.rdx))
  memo_append(frmResults_mData,prefix..'SI = '..string.format('%08X',event.rsi))
  memo_append(frmResults_mData,prefix..'DI = '..string.format('%08X',event.rdi))
  memo_append(frmResults_mData,prefix..'BP = '..string.format('%08X',event.rbp))
  memo_append(frmResults_mData,prefix..'SP = '..string.format('%08X',event.rsp))
  memo_append(frmResults_mData,prefix..'IP = '..string.format('%08X',event.rip))

  if is64bit then
    memo_append(frmResults_mData,' R8 = '..string.format('%08X',event.r8))
    memo_append(frmResults_mData,' R9 = '..string.format('%08X',event.r9))
    memo_append(frmResults_mData,'R10 = '..string.format('%08X',event.r10))
    memo_append(frmResults_mData,'R11 = '..string.format('%08X',event.r11))
    memo_append(frmResults_mData,'R12 = '..string.format('%08X',event.r12))
    memo_append(frmResults_mData,'R13 = '..string.format('%08X',event.r13))
    memo_append(frmResults_mData,'R14 = '..string.format('%08X',event.r14))
    memo_append(frmResults_mData,'R15 = '..string.format('%08X',event.r15))
  end

  memo_append(frmResults_mData,'')
  memo_append(frmResults_mData,'Stack copy = '..string.format('%08X',event.stackcopy))
  memo_append(frmResults_mData,'Stack size = '..string.format('%08X',event.stacksize))
end

function lbAddressesDblClick(sender)
  local items=listbox_getItems(frmResults_lbAddresses)
  local itemindex=listbox_getItemIndex(frmResults_lbAddresses)    
  local address=tonumber('0x'..strings_getString(items, itemindex))
  local mb=getMemoryViewForm()
  local dv=memoryview_getDisassemblerView(mb)
  disassemblerview_setSelectedAddress(dv, address)
  form_show(mb)  
end

function stealthedit_adjustRegionCopy(originaladdress, newaddress, size)
  local rrs=createRipRelativeScanner(newaddress, newaddress+size, true)
  local diff=newaddress-originaladdress

  for i=0, rrs.count-1 do
    writeInteger(rrs.Address[i], readInteger(rrs.Address[i])-diff)
  end

  rrs.destroy()

  if stealthedit_OnPostAdjustmentRegionCopy~=nil then 
    --this allows aa scripts to register a callback through lua so they can make minor adjustments before stealthedit is activated (e.g certain calls that rely on RIP might need to be rewritten)
    stealthedit_OnPostAdjustmentRegionCopy(originaladdress, newaddress, size)
  end
end

function stealthedit_allocMemoryForRegionCopy(baseaddress, size)
  if (size==nil) then return end

  autoAssemble([[
    alloc(secopy,]]..size..[[,"]]..string.format("%x",baseaddress)..[[")
    registersymbol(secopy)
  ]])

  local result=getAddress("secopy")
  unregisterSymbol("secopy")

  return result
end



function stealthedit_adjustModuleCopy64(modulename, newcopy)
  local originalbase=getAddress(modulename)
  local rrs=createRipRelativeScanner(modulename)

  local i
  local diff=newcopy-originalbase

  for i=0, rrs.count-1 do
    writeInteger(rrs.Address[i]+diff, readInteger(rrs.Address[i])-diff)
  end

  rrs.destroy()

  if stealthedit_OnPostAdjustmentModuleCopy~=nil then 
    --this allows aa scripts to register a callback through lua so they can make minor adjustments before stealthedit is activated (e.g certain calls that rely on RIP might need to be rewritten)
    stealthedit_OnPostAdjustmentModuleCopy(modulename, newcopy)
  end

end

function stealthedit_allocMemoryForModuleCopy(modulename, size)
  if (size==nil) then
    size=getModuleSize(modulename)
  end


  autoAssemble([[
    alloc(secopy,]]..size..[[,"]]..modulename..[[")
    registersymbol(secopy)
  ]])

  local result=getAddress("secopy")
  unregisterSymbol("secopy")

  return result
end

function stealthedit_copymodulefor64bit(modulename)
  --abandoned. after testing found to be too slow (but useful enough for testing)
  --print("stealthedit_copymodulefor64bit called");
  --print("modulename="..modulename)

  local originaladdress=getAddress(modulename)
  local copyaddress=stealthedit_allocMemoryForModuleCopy(modulename)

  local copy=readBytes(originaladdress, getModuleSize(modulename), true)
  writeBytes(copyaddress, copy)

  stealthedit_adjustModuleCopy64(modulename, copyaddress)

  return copyaddress
end