local miConvertTo=createMenuItem(AddressList)
miConvertTo.Caption='Chuyển thành tiêu đề có địa chỉ'
miConvertTo.OnClick=function(s)
  local i
  for i=0,AddressList.Count-1 do
    if AddressList[i].Selected then
      AddressList[i].IsGroupHeader=true
      AddressList[i].IsAddressGroupHeader=true
    end
  end
end
AddressList.PopupMenu.Items.add(miConvertTo)

local miConvertFrom=createMenuItem(AddressList)
miConvertFrom.Caption='Chuyển từ tiêu đề thành bản ghi'
miConvertFrom.OnClick=function(s)
  local i
  for i=0,AddressList.Count-1 do
    if AddressList[i].Selected then
      AddressList[i].IsAddressGroupHeader=false
      AddressList[i].IsGroupHeader=false
    end
  end
end

AddressList.PopupMenu.Items.add(miConvertFrom)

local oldOnPopup=AddressList.PopupMenu.OnPopup

AddressList.PopupMenu.OnPopup=function(s)
  if oldOnPopup then
    oldOnPopup(s)
  end

  miConvertTo.Visible=AddressList.SelectedRecord and not AddressList.SelectedRecord.IsGroupHeader
  miConvertFrom.Visible=AddressList.SelectedRecord and AddressList.SelectedRecord.IsGroupHeader
end