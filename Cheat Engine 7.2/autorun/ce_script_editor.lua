local config = { -- later save/load from registry or from file...
	DEFAULT_SYNTAX 		= 'LuaSyntax'; -- [LuaSyntax,CeaSyntax,TxtSyntax]
	windowCaption 		= 'Script Editor'; -- how to name the window
	windowWidth 		= 1280;
	windowHeight		= 720;
	windowLeft 			= 0;
	windowTop 			= 0;
	bottomPanelHeight	= 280;
	toolbar_icon_size 	= 24; -- modify for your own needs...
	toolbar_auto_size	= false; -- autosize..
	viewLimit 			= 3; -- eh modify if you want more views; can be useful when working on lua scripts with autoassembler, or just text related
	closeTabsOnClose	= true;
	showOnPrint			= true;
	comment_range		= 10; -- related to AA templates
};
local scriptEditorRegistry = getSettings('scriptEditor'); -- load config stored in registry or create new one
if (scriptEditorRegistry) then
	for key,value in pairs(config) do
		local savedValue = scriptEditorRegistry[key]
		if (savedValue and #savedValue > 0) then
			savedValue = tonumber(savedValue) or savedValue; -- try to convert to number...
			if (savedValue == 'true') then
				savedValue = true;
			elseif (savedValue == 'false') then
				savedValue = false;
			end
			if (type(config[key]) == type(savedValue)) then -- make sure we insert boolean to boolean, string to string , number to number(numbers are a bit less important tho)
				config[key] = tonumber(savedValue) or savedValue;
			else
				-- print('incorrect type! -', type(savedValue),savedValue, '\tExpected - ',type(config[key]),config[key]);
				scriptEditorRegistry[key] = tostring(config[key]); -- update registry...
			end
		else
			scriptEditorRegistry[key] = tostring(value);
		end
	end
	scriptEditorRegistry.destroy();
end
local updateKeyInReg = function(key,value)
	local scriptEditorRegistry = getSettings('scriptEditor'); -- load config stored in registry or create new one
	if (scriptEditorRegistry) then
		config[key] = value;
		scriptEditorRegistry[key] = tostring(value);
	end
end
-- base64: http://lua-users.org/wiki/BaseSixtyFour
local a='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
local function base64enc(b)return(b:gsub('.',function(c)local d,a='',c:byte()for e=8,1,-1 do d=d..(a%2^e-a%2^(e-1)>0 and'1'or'0')end;return d end)..'0000'):gsub('%d%d%d?%d?%d?%d?',function(c)if#c<6 then return''end;local f=0;for e=1,6 do f=f+(c:sub(e,e)=='1'and 2^(6-e)or 0)end;return a:sub(f+1,f+1)end)..({'','==','='})[#b%3+1]end;local function base64dec(b)b=string.gsub(b,'[^'..a..'=]','')return b:gsub('.',function(c)if c=='='then return''end;local d,g='',a:find(c)-1;for e=6,1,-1 do d=d..(g%2^e-g%2^(e-1)>0 and'1'or'0')end;return d end):gsub('%d%d%d?%d?%d?%d?%d?%d?',function(c)if#c~=8 then return''end;local f=0;for e=1,8 do f=f+(c:sub(e,e)=='1'and 2^(8-e)or 0)end;return string.char(f)end)end
local function readFile(a,b)local c=io.open(a,'r')if not c then return false end;local d=c:read('*all')c:close()if b then local e,f={},0;for g in d:gmatch('[^\n]+')do e[#e+1]=g end;return function()f=f+1;return e[f]end end;return d end
local function writeFile(a,b,c)if type(b)=='string'then local d=c and'a'or'w'local e=io.open(a,d)e:write(b)e:close()return true end;return false end
local function png_to_bmp(input)if(input)then local stream=createStringStream(base64dec(input));local pic=createPicture();pic.loadFromStream(stream,'png');stream.destroy();return pic.Bitmap;end;return false;end
local close_image,close_image_onHover
local CAPTION_EXTRA_SPACE_COUNT
local selectedTab,selectedView,scriptForm; -- so we could draw an indicator, and current view

local function checkAAScript(script,self)
	local e_status,e_error = autoAssembleCheck(script,false,self);
	local d_status,d_error = autoAssembleCheck(script,true,self);
	return e_status and d_status, e_error or d_error;
end
local function isMemoryViewer(memoryViewerTable,Handle) --:TMemoryBrowser
	-- get all forms and check for ClassName of TMemoryBrowser
	-- compares each form handle with given handle
	-- return object if found
	-- for i=0,getFormCount()-1 do -- interate each time over all forms.... waste
		-- local currentForm = getForm(i);
		-- if (currentForm.Handle == Handle and currentForm.ClassName == 'TMemoryBrowser') then
			-- return currentForm;
		-- end
	-- end
	for id,memoryViewer in pairs(memoryViewerTable) do
		if (memoryViewer.Handle == Handle) then
			return memoryViewer;
		end
	end
end
local function isMultipleMemoryViewers() --:boolean,table
	local mv = {};
	for i=0,getFormCount()-1 do
		local currentForm = getForm(i);
		if (currentForm.ClassName == 'TMemoryBrowser') then
			mv[#mv+1] = currentForm;
		end
	end
	return #mv == 1,mv;
end
local function getRecentMemoryViewer()
	-- if multiple memory viewers are open, we can assume that the top most (z order) memory viwer is the target memory viewer for templates.
	-- returns memoryViewer object.
	local mv_single,mv_t = isMultipleMemoryViewers(); -- is only one memory viewer opened?, memory viewer table (a bit of optimization)
	if (mv_single) then -- only one is opened...
		return mv_t[1];
	end
	local selfProcessId = getCheatEngineProcessID();
	local currentHwnd = getWindow(getForegroundWindow(), GW_HWNDFIRST);
	if (currentHwnd) then
		if (getWindowProcessID(currentHwnd)== selfProcessId) then
			local memoryViewer = isMemoryViewer(mv_t,currentHwnd) -- probably not likely to be top most.. lol
			if (memoryViewer) then
				return memoryViewer; 
			end
		end
		while (currentHwnd and currentHwnd~=0) do
			currentHwnd=getWindow(currentHwnd,GW_HWNDNEXT)
			if (getWindowProcessID(currentHwnd)== selfProcessId) then
				local memoryViewer = isMemoryViewer(mv_t,currentHwnd) -- cha ching $$$
				if (memoryViewer) then
					return memoryViewer; 
				end
			end
		end
	end
end
local function getMemoryViewAddress()
	return (getNameFromAddress(getRecentMemoryViewer().DisassemblerView.SelectedAddress):gsub('(.+)(%+%x+)$','"%1"%2')); -- append quotes...
end
local syntaxRules = {
	GENERAL_ITEM	= 0x00;
	STRICT_AA_ITEM 	= 0x01;
	STRICT_LUA_ITEM = 0x02;
	STRICT_NEW_ITEM = 0x10;
}
syntaxRules.STRICT_NEW_AA_ITEM = syntaxRules.STRICT_AA_ITEM | syntaxRules.STRICT_NEW_ITEM;
syntaxRules.getSyntaxRule = function(classname)return syntaxRules[(classname=='TSynAASyn'and'STRICT_AA_ITEM'or classname=='TSynLuaSyn'and'STRICT_LUA_ITEM'or'GENERAL_ITEM')]; end;
syntaxRules.matchingCurrentSyntax = function(targetSyntax,itemSyntax,secondaryRule) -- targetSyntax:syntaxRules, itemSyntax:object.tag;
	return itemSyntax & 0xF == targetSyntax, itemSyntax & 0xF0 == secondaryRule; -- primary rule, secondary;
end
syntaxRules.getCurrentSyntaxRule = function(obj) -- obj:tsynedit
	local syntax = obj.Highlighter
	return syntaxRules.getSyntaxRule(syntax and syntax.ClassName or '');
end
local function addDrawEvent(object,parent) -- clunky, but I think that's the best I can do with PageControl...
	local temp_bmp = createBitmap(1,1);
	local temp_canvas = temp_bmp.Canvas;
	local tabs = { closeWidth = close_image.width; closeHeight = close_image.height; maxheight = 0;lastTab = nil;}
	local pageControlEvents,parentEvents = {},{};
	local invalidate = function(sender) -- to force full repaint, repaint has less overhead but does not give desired output
		return executeCodeLocalEx('user32.InvalidateRect',sender.Handle,0,0);
	end
	local function drawSelectedTab(sender)
		local pageCount = sender.PageCount-1;
		if (pageCount >= 0) then
			temp_canvas.Handle = sender.dc;
			for i=0,pageCount do
				local tab = tabs[i+1];
				if (sender.Page[i] == selectedTab) then
					temp_canvas.Brush.Color = 0xFF; -- better than pen...
					temp_canvas.fillRect(tab.absX+5,tab.absY+2,tab.absX+tab.absWidth+3,tab.absY+5)
					temp_canvas.Draw(tab.closeX,tab.closeY,bmp);
				end
			end
			return sender.rdc; -- releseDC
		end
	end
	local function drawCloseButton(sender)
		local pageCount = sender.PageCount-1;
		if (pageCount > 0 or sender.canDestroyLastTab) then
			temp_canvas.Handle = sender.dc;
			for i=0,pageCount do
				local tab = tabs[i+1];
				if (tab) then
					local bmp = (tab.highlight_close and close_image_onHover or close_image);
					temp_canvas.Draw(tab.closeX,tab.closeY,bmp);
				end
			end
			return sender.rdc; -- releseDC
		end
	end
	function pageControlEvents.onmousemove(sender,x,y)
		local pageCount = sender.PageCount;
		if (pageCount == 0) then
			return;
		end
		if (x >= 0 and (pageCount > 1 or object.canDestroyLastTab)) then
			local _y = y;
			local y = y + tabs.maxheight;
			for _,tab in ipairs(tabs) do
				if ((x >= tab.closeX and x < tab.closeX + tabs.closeWidth) and (y >= tab.closeY and y < tab.closeY + tabs.closeHeight)) then
					tab.highlight_close = true;
				else
					tab.highlight_close = false;
				end
			end
		end
		tabs.lastTab = sender.Page[sender.TabIndex];
		sender.onResize(sender);
		sender.update(); -- Fix flicker
		drawCloseButton(object); -- we cannot use sender to access DC...
		drawSelectedTab(object);
	end
	function pageControlEvents.onresize(sender)
		local pageCount,maxheight,rects = sender.PageCount,0,{} -- index for array
		for i=0,pageCount-1 do
			local rect = sender.tabRect(i);
			rects[i] = rect; -- less calls == better
			if (rect.Top < maxheight) then
				maxheight = rect.Top; -- first get the max height;
			end
		end
		local maxheight,w,h = math.abs(maxheight),tabs.closeWidth,tabs.closeHeight; -- we just need the bitmap for approx size..
		tabs.maxheight = maxheight;
		if (pageCount < #tabs) then
			for i=pageCount+1,#tabs do
				tabs[i] = nil -- cleanup
			end
		end
		for i=1,pageCount do
			local rect = rects[i-1];
			rect.highlight_close = tabs[i] and tabs[i].highlight_close or false;
			local l,r,t,b = rect.Left,rect.Right,math.abs(rect.Top),math.abs(rect.Bottom);
			local bh = b+h;
			rect.absX = l;
			rect.absWidth = r-l;
			rect.absY = maxheight-t
			rect.absHeight = t-b;
			rect.closeX = r-w-2;
			rect.closeY = maxheight-bh -(t - bh)//2 + 2;
			tabs[i] = rect;
		end
	end
	function pageControlEvents.onmouseleave(sender)
		object.onmousemove(object,0,0);
	end
	function pageControlEvents.onmouseup(sender,button,x,y)
		object.onmousemove(object,x,y);
	end
	function pageControlEvents.onmousedown(sender,button,x,y)
		if (button ~= 0) then
			return;
		end
		local removedTabId;
		for id,tab in ipairs(tabs) do
			if (tab.highlight_close) then
				removedTabId = id;
				break;
			end
		end
		if (removedTabId) then
			if (sender.ActivePage == selectedTab) then
				selectedTab = nil;
			end
			if (selectedTab) then
				sender.ActivePage = selectedTab;
			end
			if (object.onTabDestroy) then
				if(object.onTabDestroy(object,removedTabId-1)) then-- was handled
					return true
				end
			else
				sender.ActivePage.destroy();
			end
			table.remove(tabs,removedTabId);
			if (sender.TabIndex < 0) then
				sender.TabIndex = 0;
			end
		end -- siwtching tabs when multilined is active won't update close positions
		if (selectedTab ~= sender.ActivePage) then
			local previousTab = selectedTab;
			selectedTab = sender.ActivePage;
			if (previousTab and previousTab.Parent~= selectedTab.Parent) then
				previousTab.Parent.repaint();
				previousTab.Parent.onmousemove(previousTab.Parent,0,0);
			end
		end
		object.onmousemove(object,x,y);
	end
	function parentEvents.onmouseenter(sender)
		for i=0,sender.ComponentCount-1 do
			local c = sender.Component[i];
			if (c and c.onmousemove) then
				c.onmousemove(c,-1,-1);
			end
		end
	end
	function parentEvents.onmousemove(sender)
		if (sender.onmouseenter) then
			sender.onmouseenter(sender);
		end
	end
	
	function parentEvents.onmouseleave(sender)
		if (sender.onmouseenter) then
			sender.onmouseenter(sender);
		end
	end
	function parentEvents.onpaint(sender)
		if (sender.onmouseenter) then
			sender.onmouseenter(sender);
		end
	end
	::lazy_repeat::
	local mt = getmetatable(object);
	local __newindex = mt.__newindex;
	mt.__newindex = function(self,key,value)
		local _key = tostring(key):lower();
		if (value == nil) then
			return __newindex(self,pageControlEvents[_key])
		elseif (self[key] and type(value)== 'function') then
			local func = self[key];
			return __newindex(self,key,function(...)
				-- func(...) -- pageControlEvents....
				return func(...) or value(...);
			end);
		end
		return __newindex(self,key,value);
	end
	for k,v in pairs(pageControlEvents) do
		object[k] = v;
	end
	for k,v in pairs(parentEvents) do
		parent[k] = v;
	end
	::end_lazy_repeat::
	object.onresize(object);
end
local function addDCmethod(o)
	local mt = getmetatable(o);
	local __index = mt.__index;
	local handle = o.handle;
	mt.dc,mt.rdc = true,true; -- property that would aquire or release dc
	function mt.getDC() -- function
		if (o.Tag == 0) then -- because of the userdata behavior we cannot store as a property...
			o.Tag = ExecuteCodeLocal('GetDC',handle);
		end
		return o.Tag;
	end
	function mt.releaseDC() -- function
		local status = false;
		if (o.Tag ~= 0) then
			local status = ExecuteCodeLocalEx('releaseDC',handle,o.Tag) == 1;
			o.Tag = 0;
		end
		return status;
	end
	mt.__index = function(self,key)
		if (type(key) == 'string') then
			local lkey = key:lower();
			if (lkey == 'dc' or key == 'getdc') then
				return mt.getDC();
			elseif (lkey == 'rdc' or key == 'releasedc') then
				return mt.releaseDC();
			end
		end
		return __index(self,key);
	end
end
local _createPageControl = createPageControl;
local tabCache = {};
local function getCachedObject(object)
	local hasCached = tabCache[userDataToInteger(object)];
	if (not hasCached) then
		tabCache[userDataToInteger(object)] = object;
	end
	return hasCached
end
local createPageControl = function(parent,NoCloseButton)
	-- workaround for drawing on top of pagecontrol... we cannot access canvas..
	local pc = _createPageControl(parent);
	getCachedObject(pc); -- cache it...
	local function attachPage(o)
		if (o) then
			if (getmetatable(o).getDC) then
				return;
			end
			addDCmethod(o);
			local mt = getmetatable(o);
			local __index = mt.__index;
			local __newindex = mt.__newindex;
			mt.__index = function(self, key)
				local item = __index(self,key);
				if (tostring(key):lower() == 'caption') then
					return item:sub(1,-CAPTION_EXTRA_SPACE_COUNT-1);
				elseif (type(item) == 'userdata' and item.ClassName == 'TTabSheet') then
					if (getCachedObject(item)) then
						return getCachedObject(item); -- use cached object...
					end
					attachPage(item);
				end
				return item;
			end
			if (o.ClassName == 'TTabSheet') then
				-- let's add some space to the caption so we could draw later our desired 'X' buttons;
				mt.__newindex = function(self,key,value)
					if (type(key) == 'string') then
						if (key:lower() == 'caption') then
							local newCaption = ("%s%s"):format(value,string.rep(' ',CAPTION_EXTRA_SPACE_COUNT));
							local status = __newindex(self,key,newCaption);
							if (not NoCloseButton and parent.onpaint) then
								parent.onpaint(parent);
							end
							return status;
						end
					end
					return __newindex(self,key,value);
				end
			end
		end
	end
	addDCmethod(pc);
	local mt = getmetatable(pc)
	local __index = mt.__index;
	mt.__index = function(self,key)
		local lkey = key:lower();
		if (lkey == 'page' or lkey == 'activepage') then
			local page = __index(self,key); -- returns table with all pages
			local int_page = type(page) == 'userdata' and userDataToInteger(page) or page; -- Page is a table... we cannot use userDataToInteger
			if (tabCache[int_page]) then
				return tabCache[int_page]; -- use cached object...
			end
			attachPage(page);--return cache version! either store somewhere using userDataToInteger
			return page;
		end
		return __index(self,key);
	end
	if (not NoCloseButton) then
		pc.canDestroyLastTab = true;
		addDrawEvent(pc,parent); -- workaround for windows;
	end
	return pc; -- only accessing thorugh this object would allow us to obtain and release dc linked..
end
local updateToolbar
local function createView(parent,views) -- creates view, and if nessecary also a splitter...
	local mainWindow = parent;
	while (mainWindow.ClassName ~= "TCEForm") do
		mainWindow = mainWindow.parent;
	end
	if (not views.ContainerPageControl) then
		views.ContainerPageControl = createPageControl(parent.parent);
		local tabsContainer = views.ContainerPageControl
		tabsContainer.visible = false;
		tabsContainer.addTab();
		local tab = tabsContainer.ActivePage;
		local lua = createSynEdit(tab,0); -- just to get highlighters...
		local cea = createSynEdit(tab,1); -- cheat engine assembly
		views.LuaSyntax = lua.Highlighter
		views.CeaSyntax = cea.Highlighter
		views.TxtSyntax = 0 -- none.. removes syntax
	end
	local viewCount = #views;
	if (viewCount == views.viewLimit) then
		return false;
	end
	local viewObj
	if (viewCount == 0) then -- first view;
		viewObj = createPageControl(parent);
		selectedView = viewObj; -- initialize view...
	else
		local newSplitter = createSplitter(parent); -- we cannot link splitter to the view;
		views.splitters[viewCount] = newSplitter;
		viewObj = createPageControl(parent);
		views[#views].width = views[#views].width // 2 -- so we could see the new view
	end
	viewObj.Constraints.MinHeight = 20;
	viewObj.Constraints.MinWidth = 150;
	viewObj.Options = '[nboDoChangeOnSetIndex]' -- call onChange ...
	views[viewCount+1] = viewObj; -- assign new view;
	if (views.icons) then
		viewObj.Images = views.icons;
	end
	local function findView(targetView) -- returns viewObj instead of sender...
		for id,view in ipairs(views) do
			if (view == targetView) then
				return view,id;
			end
		end
	end
	viewObj.OnMouseWheelUp = function()
		local tabIndex = viewObj.ActivePage.TabIndex
		if (tabIndex > 0) then
			viewObj.ActivePage = viewObj.Page[tabIndex-1];
			viewObj.notifyViewChange();
		end
	end
	viewObj.OnMouseWheelDown = function()
		local tabIndex = viewObj.ActivePage.TabIndex
		if (tabIndex < viewObj.PageCount-1) then
			viewObj.ActivePage = viewObj.Page[tabIndex+1];
			viewObj.notifyViewChange();
		end
	end
	viewObj.sortViews = function()
		local viewCount,temp_left = #views,0;
		for i=1,viewCount do
			local view = views[i];
			view.align = i == viewCount and alClient or alLeft;
			view.anchors = i == viewCount and '[akTop,akRight,akBottom]' or '[akTop,akLeft,akRight,akBottom]';
			view.left = temp_left; -- fix conflicts
			temp_left = temp_left + view.width;
			local hasSplitter = views.splitters[i];
			if (hasSplitter) then
				hasSplitter.align = alLeft;
				hasSplitter.left = temp_left;
				temp_left = temp_left + hasSplitter.width;
			end
		end
	end
	-- optimize a bit...
	local execute 	= parent.parent.ComponentByName['toolbar'].ComponentByName['execute'];
	local new_view 	= parent.parent.ComponentByName['toolbar'].ComponentByName['new_view'];
	local next_view = parent.parent.ComponentByName['toolbar'].ComponentByName['next_view'];
	local prev_view = parent.parent.ComponentByName['toolbar'].ComponentByName['prev_view'];
	local function updateToolbar()
		if (new_view) then
			local highlighter = selectedView.ActivePage.synedit.Highlighter
			local smi = mainWindow.SyntaxMI;
			if (smi) then
				if (highlighter) then
					mainWindow.LuaSyntax.Checked = highlighter.ClassName == 'TSynLuaSyn';
					mainWindow.CeaSyntax.Checked = highlighter.ClassName == 'TSynAASyn';
					execute.enabled = true;
				else
					mainWindow.TxtSyntax.Checked = false;
					execute.enabled = false;
				end
			end
			local _,viewId = findView(viewObj);
			if (selectedView.PageCount <= 1) then
				new_view.Enabled = false;
				if (viewId == 1) then
					next_view.Enabled = false;
					prev_view.Enabled = false;
				else
					next_view.Enabled = viewId < #views;
					prev_view.Enabled = viewId > 1;
				end
			else
				new_view.Enabled = #views < views.viewLimit;
				next_view.Enabled = viewId < #views;
				prev_view.Enabled = viewId > 1;
			end
		end
	end
	viewObj.notifyViewChange = function(sender)
		local previousView = selectedView;
		selectedTab = viewObj.ActivePage;
		selectedView = viewObj;
		if (viewObj == selectedView) then -- fix flicker when updating previous 
			updateToolbar();
		end
		if (previousView and previousView ~= viewObj) then
			previousView.repaint();
			previousView.onmousemove(previousView,0,0);
		end
		if (mainWindow.visible) then -- avoid trying to setFocus on hidden object..
			selectedTab.synedit.setFocus(); -- put focus on the new tab...
		end
		viewObj.onmousemove(viewObj,0,0);
	end
	viewObj.createNewTab = function(caption)
		local tabsContainer = views.ContainerPageControl;
		if (tabsContainer) then
			-- we cannot transfer ownership (currently at least), so destroying a view while
			-- its owned component have a different parent will also destroy them (may result in empty pagecontrol...)
			tabsContainer.addTab();
			local page = tabsContainer.Page[tabsContainer.PageCount-1];
			page.Parent = viewObj;
			page.TabVisible = true;
		end
		if (not caption) then
			views.openedTabs = views.openedTabs + 1;
		end
		local id = viewObj.PageCount-1;
		local newTab = viewObj.Page[id];
		newTab.ImageIndex = views.iconsId.file_unchanged
		newTab.Caption = caption or ('Mới %d'):format(views.openedTabs);
		local synedit = createSynEdit(newTab,views[DEFAULT_SYNTAX]);
		synedit.BorderStyle = 'bsNone';
		synedit.onClick = function(sender)
			local isOpenedFile = views.getOpenedTab(newTab);
			if (isOpenedFile and isOpenedFile.MemoryRecord) then
				-- update memoryrecord description (incase it was changed...)
				local caption = isOpenedFile.MemoryRecord.Description
				if (newTab.Caption ~=caption) then
					isOpenedFile.path = '[Memory record] '.. caption;
					newTab.Caption = caption;
					sender.Parent.Parent.onChange();
				end
			end
			if (newTab ~= selectedTab) then
				-- findView(sender.Parent.Parent).notifyViewChange();
				getCachedObject(sender.Parent.Parent).notifyViewChange();
				sender.Parent.Parent.onChange();
			end
		end
		synedit.onChange = function(sender,key)
			if (newTab.ImageIndex == views.iconsId.file_changed) then
				return;
			end
			local isOpenedFile = views.getOpenedTab(newTab);
			if (isOpenedFile) then
				isOpenedFile.modified = true;
			end
			newTab.ImageIndex = views.iconsId.file_changed;
			sender.Parent.Parent.onChange();
		end
		
		synedit.ScrollBars = 6 --ssAutoBoth 
		synedit.Options = views.synedit_options;
		synedit.Options2 = views.synedit_options2;
		synedit.MouseOptions = views.synedit_mouseoptions;
		synedit.name = 'synedit';
		synedit.Lines.Text = '';
		synedit.Parent = newTab;
		synedit.align = alClient;
		synedit.Font.Quality = 'fqCleartype';
		synedit.Font.Size = 10;
		synedit.BlockTabIndent = 1; -- fix tabs
		synedit.BlockIndent = 0;
		synedit.TabWidth = 3; -- finally can tab like a person without having to scroll miles
		synedit.Lines.LineBreak = '\n'; -- fix saving
		viewObj.TabIndex = id;
		selectedTab = newTab;
		viewObj.notifyViewChange();
		-- add popup menu...		
		local isCurrentSyntax = function(itemSyntax,secondaryRule)
			return syntaxRules.matchingCurrentSyntax(syntaxRules.getCurrentSyntaxRule(synedit),itemSyntax,secondaryRule);
		end
		-- @cheat engine source :p
		local rsCodeInjectionTemplate = 'Mẫu tiêm mã';
		local rsOnWhatAddressJump = 'Địa chỉ nào bạn muốn nhảy tới?';
		local rsWhatIdentifierTouse = 'Bạn muốn đặt tên ký hiệu cho điểm tiêm là gì?';
		local comment_range = config.comment_range;
		local syn_popup = createPopupMenu(synedit);
		syn_popup.OnPopup = function(sender)
			-- filter based current syntax...
			-- items based current used syntax
			-- items based new file/existing item
			local isOpenedFile = views.getOpenedTab(newTab); -- let's see if any file/object is assigned
			local syntaxType = syntaxRules.getCurrentSyntaxRule(synedit);
			local items = syn_popup.Items;
			for i=0,items.Count -1 do
				local item = items.Item[i]
				local itemSyntaxRule = item.Tag;
				if (itemSyntaxRule > 0) then -- has any?
					local isMatchingSyntax,isOnlyNewItem = syntaxRules.matchingCurrentSyntax(syntaxType,itemSyntaxRule,syntaxRules.STRICT_NEW_ITEM);
					if (not isMatchingSyntax or (isOpenedFile and isOnlyNewItem)) then
						item.visible = false;
					else
						item.visible = true;
					end
				else
					item.visible = true;
				end
			end
		end
		local createCustomMenuItem = function(itemOwner,caption,func,_type)
			assert(itemOwner,'không có chủ sở hữu được đưa ra');
			-- assert(func,'no function was given');
			-- quick method to set up menu items...
			local item = createMenuItem(itemOwner);
			item.caption = caption;
			item.OnClick = func;
			item.tag = syntaxRules[_type];
			(itemOwner.Items or itemOwner).add(item);
			return item;
		end
		local createSynMenuItem = function(caption,func,_type)
			return createCustomMenuItem(syn_popup,caption,func,_type);
		end
		local mTemplate 	= createSynMenuItem('Khuôn mẫu',nil,'STRICT_AA_ITEM');
		local mCodeInjection = createCustomMenuItem(mTemplate,'Tiêm mã',function()
			local address = inputQuery(rsCodeInjectionTemplate,rsOnWhatAddressJump,getMemoryViewAddress());
			if (not address) then
				return;
			end
			generateCodeInjectionScript(synedit.Lines,address);
			synedit.onchange(synedit);
		end,'STRICT_AA_ITEM');
		local mAOBInjection = createCustomMenuItem(mTemplate,'Tiêm mảng byte',function()
			local address = inputQuery(rsCodeInjectionTemplate,rsOnWhatAddressJump,getMemoryViewAddress());
			if (not address) then
				return;
			end
			local Lines = synedit.Lines;
			local nextAllocNum = getNextAllocNumber(Lines);
			local symbolName = inputQuery(rsCodeInjectionTemplate,rsWhatIdentifierTouse,("%s%s"):format("INJECT",tostring(nextAllocNum > 0 and nextAllocNum or '')));
			generateAOBInjectionScript(Lines,symbolName,address,comment_range);
			synedit.onchange(synedit);
		end,'STRICT_AA_ITEM');
		local mFullCodeInjection 	= createCustomMenuItem(mTemplate,'Tiêm mã đầy đủ',function()
			local address = inputQuery(rsCodeInjectionTemplate,rsOnWhatAddressJump,getMemoryViewAddress());
			if (not address) then
				return;
			end
			generateFullInjectionScript(synedit.Lines,address);
			synedit.onchange(synedit);
		end,'STRICT_AA_ITEM');

		createCustomMenuItem(mTemplate,'-'); -- seperator...
		--[[
		-- isn't yet published.. tho it is documented already ...
		local mAddSnapshotComment = createCustomMenuItem(mTemplate,'Add code snapshot as comment',function()
			local address = inputQuery('Code snapshot comment','From what address you want to take the snapshot?',getMemoryViewAddress());
			if (not address) then
				return;
			end
			local commentRadius = inputQuery('Code snapshot comment','Comment radius',comment_range);
			addSnapshotAsComment(synedit.Lines,address,commentRadius);
		end,'STRICT_AA_ITEM');
		--]]



		local mCTFrameWorkCode = createSynMenuItem('Thêm khung mã bảng cheat',function()
			local enableStr,disableStr = '[ENABLE]','[DISABLE]';
			local enableComment = "//mã từ đây tới '[DISABLE]' sẽ được dùng cho bật cheat";
			local disableComment = "//mã từ đây cho đến kết thúc sẽ dùng cho tắt cheat";
			local hasEnable,hasDisable
			local enableStrEscaped,disableStrEscaped = (enableStr:gsub('([%[%]]+)','%%%1')),(disableStr:gsub('([%[%]]+)','%%%1'));
			local Lines = synedit.Lines;
			for i=0,Lines.Count-1 do
				local line = Lines.String[i]
				if (not hasEnable and line:match(enableStrEscaped)) then 
					hasEnable = true;
				end
				if (not hasDisable and line:match(disableStrEscaped)) then
					hasDisable = true;
				end
				if (hasEnable and hasDisable) then
					return
				end
			end
			local caretPos = synedit.SelStart -- save current
			if (not hasEnable) then
				Lines.insert(0,enableStr);Lines.insert(1,enableComment);
				synedit.SelStart = caretPos+(#enableStr+2)+(#enableComment+2); -- additional newline...
			end
			if (not hasDisable) then
				Lines.add(disableStr);Lines.add(disableComment);
				Lines.add('');	-- one thing I hate is that the caret does not go to the end of the last line.. gotta fix it..
			end
			synedit.onchange(synedit);
		end, 'STRICT_AA_ITEM');
		-- to avoid creation of many many scripts, allow only new tabs to be assigned as an addresslist object;
		local mAddToAddressList = createSynMenuItem('Lưu vào danh sách', function()
			local script = synedit.Lines.Text;
			local status,Err = checkAAScript(script);
			if (not status) then
				print(selectedTab.Caption,'Lỗi: ',Err);
				return;
			end
			-- okay script is good
			local al = AddressList
			local caption = newTab.Caption;
			local path = '[Memory record]'..caption;
			local mr = AddressList.createMemoryRecord();
			mr.Description = caption;
			mr.Type = vtAutoAssembler;
			mr.Script = script;
			views.setOpenedFileTab(newTab,{path = path;MemoryRecord = mr});
			getCachedObject(newTab.parent).saveFile(); -- save file and update...
			
		end, 'STRICT_NEW_AA_ITEM');
		createSynMenuItem('-',nil,'STRICT_AA_ITEM');
		local miCut 			= createSynMenuItem('Cắt',synedit.CutToClipboard);
		local miCopy 			= createSynMenuItem('Chép',synedit.CopyToClipboard);
		local miPaste 			= createSynMenuItem('Dán',synedit.PasteFromClipboard);
		local miUndo 			= createSynMenuItem('Hoàn tác',synedit.Undo);
		local miRedo 			= createSynMenuItem('Làm lại',synedit.Redo);
		local miRedo 			= createSynMenuItem('Chọn tất cả',synedit.SelectAll);
		-- to do....
		-- createSynMenuItem('-');
		-- local miFind 		= createSynMenuItem('Find');
		-- local miFindReplace 	= createSynMenuItem('Find/Replace');
		synedit.PopupMenu = syn_popup;		
		return newTab;
	end
	local function getMaxTabsHeight()
		local maxheight = 0;
		for i=0,viewObj.PageCount-1 do
			local rect = viewObj.tabRect(i);
			if (rect.Top < maxheight) then
				maxheight = rect.Top; -- first get the max height;
			end
		end
		return math.abs(maxheight);
	end
	local middleButtonClick = false -- allow to close with middle button
	viewObj.onmousedown = function(sender,button,x,y)
		if (middleButtonClick) then
			middleButtonClick = false;
			return viewObj.onTabDestroy();
		end
		if (button >= 1) then
			middleButtonClick = button == 2;
			mouse_event(6, getMousePos()); -- as I am uncapable of getting tab under mouse when right clicking
		else
			viewObj.notifyViewChange();
		end
	end
	viewObj.setActivePage = function(page)
		if (page) then
			viewObj.ActivePage = page;
			viewObj.notifyViewChange();
			viewObj.onchange(viewObj);
		end
	end
	viewObj.setTabView = function(tab,view)
		view = view or viewObj;
		tab = tab or viewObj.ActivePage;
		if (tab.Parent == tView) then
			return;
		end
		local tabParent = getCachedObject(tab.parent);
		selectedView = tabParent;
		tab.parent = view;
		tab.TabVisible = true;
		view.TabIndex = view.PageCount-1;
		if (tabParent.PageCount == 0) then
			tabParent.destroyView();
		else
			viewObj.notifyViewChange();
		end
	end
	viewObj.moveToNewView = function(tab)
		local newView = createView(parent,views); -- create a single function for this complete class; to avoid referencing functions.
		if (newView) then
			newView.setTabView(tab or viewObj.ActivePage);
		end
	end
	viewObj.moveToNextView = function(view)
		local _,viewId = findView(viewObj);
		if (viewId == 1 and viewObj.PageCount <= 1) then
			return
		end
		local nextView = views[viewId+1];
		if (nextView) then
			nextView.setTabView(viewObj.ActivePage);
		end
	end
	viewObj.moveToPrevView = function(view)
		local _,viewId = findView(viewObj);
		local nextView = views[viewId-1];
		if (nextView) then
			nextView.setTabView(viewObj.ActivePage);
		end
	end
	viewObj.moveTabRight = function(tab)
		local page = tab or viewObj.ActivePage;
		local TabIndex = page.TabIndex;
		if (page.PageIndex < viewObj.PageCount-1) then
			page.PageIndex = page.PageIndex + 1;
		end
		viewObj.onmousemove(viewObj,0,0);
	end
	viewObj.moveTabLeft = function(tab)
		local page = tab or viewObj.ActivePage;
		local TabIndex = page.TabIndex;
		if (page.PageIndex > 0) then
			page.PageIndex = page.PageIndex - 1;
		end
		viewObj.onmousemove(viewObj,0,0);
	end
	viewObj.destroyView = function(targetView)
		-- find view in array...
		if ((targetView or viewObj) == views[1]) then return end;
		local targetId;
		for id,view in ipairs(views) do
			if (view == (targetView or viewObj)) then
				view.name = nil;
				view.destroy();
				table.remove(views,id);
				local splitter = views.splitters[id-1];
				if (splitter) then
					splitter.destroy(); -- destroy splitter related to view
					table.remove(views.splitters,id-1);
				end
				targetId = id;
				break;
			end
		end
		if (selectedView == viewObj) then
			selectedView = views[targetId] or views[#views]; -- set new view as active;
			selectedTab = selectedView.ActivePage;
		end
		selectedView.sortViews();
		selectedView.notifyViewChange();
	end
	viewObj.closeTab = function(tab) -- addCloseButton dependency
		if (viewObj.PageCount > 1) then
			tab = tab or viewObj.ActivePage;
            tab.synedit.destroy();
			tab.destroy();
			selectedTab = viewObj.ActivePage;
			selectedView.notifyViewChange();
		else
			local synedit = viewObj.ActivePage.synedit;
			if (viewObj == views[1]) then
				if (synedit.Lines.Text == '') then
					return
                end
				synedit.destroy();
				viewObj.ActivePage.destroy();
				viewObj.createNewTab();
				viewObj.onchange(viewObj);
				return
            end
			synedit.destroy();
			viewObj.ActivePage.destroy();
			viewObj.destroyView();
			return true;
		end
	end
	viewObj.onTabDestroy = function(sender,id)
		local tab = type(id)=='number' and viewObj.Page[id] or type(id)=='userdata' and id or viewObj.ActivePage;
		local isOpenedFile = views.getOpenedTab(tab);
		local synedit = tab.synedit;
		local text = synedit.Lines.Text:gsub('%s','');
		if ((not isOpenedFile and #text > 0) or (isOpenedFile and isOpenedFile.modified)) then
			if (not mainWindow.visible) then
				mainWindow.show();
			end
			local mr = messageDialog(('Lưu kịch bản - %s'):format(tab.Caption),('Bạn có muốn lưu các thay đổi đối với "%s" ?'):format(isOpenedFile and isOpenedFile.path or tab.Caption),mtInformation,mbYes,mbNo,mbCancel);
			if (mr == mrCancel) then
				return true, 'người dùng đã hủy';
			end
			if (mr == mrYes) then
				if (not viewObj.saveFile()) then
					return true, 'không thể ghi';
				end;
			end
		end
		if (isOpenedFile) then
			views.setOpenedFileTab(tab,nil);
		end
		return viewObj.closeTab(tab);
	end
	local function createSpecificFileDialog(owner,dialogFunc)
		local fileDialog = (dialogFunc or createOpenDialog)(owner);
		fileDialog.Filter = 'Tệp lua (*.lua)|*.lua|Tệp kịch bản cheat engine (*.cea)|*.cea|Tệp văn bản thường (*.txt)|*.text|Tất cả (*.*)|*'
		fileDialog.options = 'ofPathMustExist'
		fileDialog.InitialDir = config.openDialogPath;
		fileDialog.FilterIndex = 4;
		return fileDialog;
	end
	viewObj.openFile = function(file)
		if (type(file)=='string') then
			local path,fileName,fileExtension = file:match('^(.+\\)(.+%.(.+))$'); -- path full filename, and extension can be whatever after the last dot
			local isOpened = views.getOpenedTabFromPath(file); -- searches all cached tabs for path == file
			if (not isOpened) then
				local source = readFile(file);
				assert(source,'đọc tệp thất bại! :'..file);
				local tab = viewObj.createNewTab(fileName);
				local synedit = tab.synedit;
				synedit.Lines.Text = source;
				synedit.Highlighter = views.getSyntaxFromExtension(fileExtension);
				views.setOpenedFileTab(tab,{path = file, fileName = fileName, fileExtension = fileExtension});
			else
				local parentView = getCachedObject(isOpened.Parent); -- get main pagecontrol parent;
				if (parentView) then -- set active page;
					return parentView.setActivePage(isOpened);
				end
			end
		elseif(type(file)=='userdata') then
			local path = '[Memory record] '..file.Description;
			local isOpened = views.getOpenedTabMR(file);
			if (not isOpened) then
				local tab = viewObj.createNewTab(file.Description);
				local synedit = tab.synedit;
				synedit.Lines.Text = file.Script;
				synedit.Highlighter = views.CeaSyntax;
				views.setOpenedFileTab(tab,{path = path;MemoryRecord = file});
			else
				local parentView = getCachedObject(isOpened.Parent);
				if (parentView) then
					return parentView.setActivePage(isOpened);
				end
			end
		else
			local fileDialog = createSpecificFileDialog(viewObj)
			fileDialog.options = fileDialog.options..'ofAllowMultiSelect';
			if (fileDialog.execute()) then
				local files = fileDialog.Files;
				for i=0,files.Count-1 do
					local pathToFile = files[i];
					local isOpened = views.getOpenedTabFromPath(pathToFile);
					if (not isOpened) then
						local path,fileName,fileExtension = pathToFile:match('^(.+\\)(.+%.(.+))$');
						local source = readFile(pathToFile);
						local tab = viewObj.createNewTab(fileName);
						local synedit = tab.synedit;
						synedit.Lines.Text = source;
						synedit.Highlighter = views.getSyntaxFromExtension(fileExtension);
						views.setOpenedFileTab(tab,{path = pathToFile, fileName = fileName, fileExtension = fileExtension});
					else
						-- open existing tab!
						-- viewObj.ActivePage = isOpened -- can have different parent...
						local parentView = getCachedObject(isOpened.Parent);
						if (parentView) then
							return parentView.setActivePage(isOpened);
						end
					end
				end
			end
			fileDialog.destroy();
		end
		viewObj.notifyViewChange();
		viewObj.onchange(viewObj);
	end
	viewObj.saveFile = function(saveAs)
		local tab = viewObj.ActivePage;
		local isOpenedFile = views.getOpenedTab(tab);
		local synedit = tab.synedit;
		local data = synedit.Lines.Text;
		if (isOpenedFile and isOpenedFile.MemoryRecord) then
			if (not mainWindow.CeaSyntax.Checked) then
				print(selectedTab.Caption,'Lỗi: sai cú pháp!');
				return false;
			end
			local status,Err = checkAAScript(data);
			if (status) then
				isOpenedFile.MemoryRecord.Script = data;
			else
				print(selectedTab.Caption,'Lỗi: ',Err,self and '(Mục tiêu bản thân)');
				return false;
			end
		elseif (not isOpenedFile or saveAs) then
			local fileDialog = createSpecificFileDialog(mainView,createSaveDialog);
			fileDialog.options = fileDialog.options..'ofOverwritePrompt';
			fileDialog.FileName = tab.Caption;
			fileDialog.DefaultExt = synedit.Highlighter and (synedit.Highlighter.ClassName == 'TSynLuaSyn' and '.lua' or synedit.Highlighter.ClassName == 'TSynAASyn' and '.cea') or '.txt';
			if(not fileDialog.execute()) then
				return false;
			end
			if (not writeFile(fileDialog.FileName,data)) then
				messageDialog('Không thể ghi vào tệp!',mtError,mbOK);
				return false;
			end
			local path,fileName,fileExtension = fileDialog.FileName:match('^(.+\\)(.+%.(.+))$');
			tab.Caption = fileName;
			views.setOpenedFileTab(tab,{path = fileDialog.FileName, fileName = fileName, fileExtension = fileExtension});
			fileDialog.destroy();
			viewObj.onchange(viewObj);
		elseif (isOpenedFile) then
			if (not writeFile(isOpenedFile.path,data)) then
				messageDialog('Không thể ghi vào tệp!',mtError,mbOK);
				return false;
			end
		end
		if (isOpenedFile) then
			isOpenedFile.modified = false;
		end
		synedit.MarkTextAsSaved();
		tab.ImageIndex = views.iconsId.file_unchanged;
		viewObj.onChange();
		return true;
	end
	viewObj.onChange = function(sender)
		if (viewObj.PageCount > 0 and viewObj.ActivePage) then
			local tab = viewObj.ActivePage;
			local isOpenedFile = views.getOpenedTab(tab);
			if (isOpenedFile) then
				mainWindow.Caption = ('%s%s - %s'):format(isOpenedFile.modified and '*' or '',isOpenedFile.path,config.windowCaption);
			else
				local text = tab.synedit.Lines.Text
				mainWindow.Caption = ("%s%s - %s"):format(#tab.synedit.Lines.Text > 0 and '*' or '',tab.Caption,config.windowCaption);
			end
		end
	end
	viewObj.sortViews();
	local popupMenu 			= createPopupMenu(viewObj);
	local popupItems 			= popupMenu.Items;
		local closeTabsRight		= createMenuItem(popupMenu);
		local closeTabsLeft			= createMenuItem(popupMenu);
		local closeTabsUnchanged	= createMenuItem(popupMenu);
		local moveNewView 			= createMenuItem(popupMenu);
		local moveToNextView 		= createMenuItem(popupMenu);
		local moveToPrevView 		= createMenuItem(popupMenu);
	closeTabsLeft.Caption		= 'Đóng tất cả sang trái';
	closeTabsRight.Caption		= 'Đóng tất cả sang phải';
	closeTabsUnchanged.Caption	= 'Đóng tất cả không thay đổi';
	moveNewView.Caption 		= 'Chuyển sang chế độ xem mới';
	moveToNextView.Caption 		= 'Chuyển sang chế độ xem tiếp';
	moveToPrevView.Caption 		= 'Chuyển sang chế độ xem trước';
	-- user may switch view only if he has more than one tab in current view....
	moveNewView.onClick = function(sender)
		viewObj.moveToNewView();
	end
	closeTabsRight.onClick = function(sender)
		local pageId = viewObj.ActivePage.TabIndex+1;
		for i=pageId,viewObj.PageCount-1 do
			local status,cancelMsg = viewObj.onTabDestroy(viewObj,pageId);
			if (cancelMsg) then
				break;
			end
		end
		-- while viewObj.PageCount-1 > pageId do
			-- viewObj.onTabDestroy(viewObj,pageId);
		-- end
	end
	closeTabsLeft.onClick = function(sender)
		local pageId = viewObj.ActivePage.TabIndex;
		for i=0,pageId-1 do
			local status,cancelMsg = viewObj.onTabDestroy(viewObj,0);
			if (cancelMsg) then
				break;
			end
		end
	end
	closeTabsUnchanged.onClick = function(sender)
		for i=viewObj.PageCount-1,0,-1 do
			if (viewObj.Page[i].ImageIndex == views.iconsId.file_unchanged) then
				viewObj.onTabDestroy(viewObj,i);
			end
		end
	end
	moveToNextView.onClick = function(sender)
		viewObj.moveToNextView();
	end
	moveToPrevView.onClick = function(sender)
		viewObj.moveToPrevView();
	end
	popupMenu.OnPopup = function(sender)
		local PageCount = viewObj.PageCount
		local tabIndex = viewObj.ActivePage.TabIndex;
		-- local _,viewId = findView(viewObj);
		local _,viewId = getCachedObject(viewObj);
		if (PageCount <= 1 ) then
			moveNewView.Enabled = false;
			if (views[1] == viewObj) then
				moveToNextView.Enabled = false;
				moveToPrevView.Enabled = false;
				closeTabsLeft.Enabled = false;
				closeTabsRight.Enabled = false;
				closeTabsUnchanged.Enabled = false;
			else
				moveToNextView.Enabled = viewId ~= #views;
				moveToPrevView.Enabled = viewId ~= 1;
			end
		else
			moveNewView.Enabled = viewId ~= views.viewLimit;
			if (#views > 1) then
				moveToNextView.Enabled = viewId ~= #views;
				moveToPrevView.Enabled = viewId ~= 1;
			else
				moveToNextView.Enabled = false;
				moveToPrevView.Enabled = false;
			end
			closeTabsLeft.Enabled = tabIndex ~= 0;
			closeTabsRight.Enabled = tabIndex ~= PageCount-1;
			closeTabsUnchanged.Enabled = true;
		end
	end
	popupItems.add(closeTabsLeft);
	popupItems.add(closeTabsRight);
	popupItems.add(closeTabsUnchanged);
	popupItems.add(seperator);
	popupItems.add(moveNewView);
	popupItems.add(moveToNextView);
	popupItems.add(moveToPrevView);
	viewObj.PopupMenu = popupMenu;
	return viewObj;
end
CAPTION_EXTRA_SPACE_COUNT = 5; -- so we could draw the close buttons if necessary
-- modify the pictures if you want to use different close buttons
close_image 			= png_to_bmp("iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAABUElEQVQ4T6XSTcuCQBAA4OnD/kJR3S0pD0G3QCQkgv5viIgI3r0E4iWKuqT2YbcK25cZcVWKPLwDsrPjPu7KTg3+EbXMNhoNNplMoNVqgSAINOLzfD7h8XjQ+Hq9wHVdSJKEXIbZarWC9/sNjLHS+K3mOA5ZwrIss36/D/V6vfInLpcLnM9n8H0/x71eD2rp9Gdcr1c4nU6w3W7T1ePxmHW7XcLr9ZrwcrnkHynWEIdhmOPRaEQ4C13XKV0sFlDMsXa73SAIAtjtdunOiDudTum4hmHwuaZpPEccRVGOJUn6wKZpcjCfz3kexzHh/X6f7jwcDgnjNWFYlkWjqqqlHGsZPhwOKR4MBqzdbhO2bZugoih8t2INMV4Xx6IoEsaGqIr7/U74eDzyi2Wz2Yx3VrHLinmSJLRms9ngHnlXNJtNNp1OK1vU87yP3q467df3fwxz9xCrlragAAAAAElFTkSuQmCC");
close_image_onHover 	= png_to_bmp("iVBORw0KGgoAAAANSUhEUgAAAA8AAAAPCAYAAAA71pVKAAABNElEQVQ4T6XSPUtcQRTG8d8NwUIsBMXOzs7KLp9BRCKI2IhfwNbawkIQhAgLhi2CYGGdRiJBCxHfEBXBzi6dBrHKghEnzO4MjIuyCzkwzLkz83/OuTNP5T+iymwvYRsDaQym+Q73+I0HzOEPTS7D4Rl/28bTO9+fWhWrJvyVMI+eLn7hCPtYynCdMIuPXcDH2MFahjcIM/iA/hCaEo+tpppRrp3iB75kuEaYLi5gKAncVZUyj0Jn2EUtw+uEqbaWh5NAXP5VdHGOn9jI8BrhM14KgZECvi3gC+yhnuFVwiTic8UYTeBNVb3K495Vuu1vGV4hTKQ3HUvgZVGtXIvwATYzvEwYRzRFp7jGIbYyjHCSKkeB7LY4l85rpDMLpcNi3kf4/oZFo2VLmy6i0ebtTt2+uf8P9UNwEGbDzMIAAAAASUVORK5CYII=");

local views = {
			splitters = {};
			fileTabs = {};
			viewLimit = config.viewLimit;
			openedTabs = 0;
			-- synedit_options = '[eoAutoIndent,eoBracketHighlight,eoGroupUndo,eoKeepCaretX,eoSmartTabs,eoTabIndent,eoTabsToSpaces,eoTrimTrailingSpaces,eoHideRightMargin]';
			synedit_options 	= '[eoEnhanceHomeKey,eoAutoIndent,eoBracketHighlight,eoGroupUndo,eoKeepCaretX,eoTabIndent,eoTrimTrailingSpaces,eoHideRightMargin]';
			synedit_options2 	= '[eoFoldedCopyPaste,eoOverwriteBlock,eoEnhanceEndKey]';
			--synedit_mouseoptions= '[emAltSetsColumnMode,emDragDropEditing,emCtrlWheelZoom]';
			synedit_mouseoptions= '[emAltSetsColumnMode,emDragDropEditing,emShowCtrlMouseLinks,emCtrlWheelZoom]';
			getSyntaxFromExtension=function(ext)return views[("%sSyntax"):format(ext:lower():gsub("^%l",string.upper))]or views.TxtSyntax;end; -- Lua,LUA,lUa,luA... --> LuaSyntax
};
views.getOpenedTabFromPath = function(path) -- opened tab object
	for tab,file in pairs(views.fileTabs) do
		if (file.path == path) then
			return integerToUserData(tab);
		end
	end
end
views.getOpenedTabMR = function(mr) -- opened tab object
	for tab,file in pairs(views.fileTabs) do
		if (file.MemoryRecord == mr) then
			return integerToUserData(tab);
		end
	end
end
views.getOpenedTab = function(obj) -- opened tab data
	return views.fileTabs[userDataToInteger(obj)];
end
views.setOpenedFileTab = function(obj,data)
	views.fileTabs[userDataToInteger(obj)] = data;
end
scriptForm = createForm(false);
scriptForm.DoubleBuffered = true;
scriptForm.PopupMode = 'pmNone'; -- fix the 'always on top' behavior
scriptForm.KeyPreview = true; -- so we could open new tab ffs
scriptForm.name = 'ScriptEditor';
scriptForm.setSize(config.windowWidth,config.windowHeight);
scriptForm.setPosition(config.windowLeft,config.windowTop);
scriptForm.borderStyle = bsSizeable;
scriptForm.Caption = config.windowCaption;
local previousWidth = scriptForm.width;
scriptForm.onresize = function(sender)
	local totalWidth = 0;
	for _,view in ipairs(views) do
		totalWidth = totalWidth + view.width;
	end
	local width = sender.width;
	if (totalWidth > width) then
		for _,view in ipairs(views) do
			view.width = math.floor(view.width / previousWidth * width);
		end
	end
end
local mainMenu 			= createMainMenu(scriptForm);
local FileItem 			= createMenuItem(scriptForm);
	local new 				= createMenuItem(scriptForm);
	local open 				= createMenuItem(scriptForm);
	local save	 			= createMenuItem(scriptForm);
	local saveAs 			= createMenuItem(scriptForm);
	local seperator_1 		= createMenuItem(scriptForm);
	local close				= createMenuItem(scriptForm);
	local closeAll 			= createMenuItem(scriptForm);
local EditItem			= createMenuItem(scriptForm);
	local ZoomIn			= createMenuItem(scriptForm);
	local ZoomOut			= createMenuItem(scriptForm);
	local ZoomRestore 		= createMenuItem(scriptForm);
	local seperator_2 		= createMenuItem(scriptForm);
	local Syntax	 		= createMenuItem(scriptForm);
		local Txt	 		= createMenuItem(scriptForm);
		local Lua	 		= createMenuItem(scriptForm);
		local Asm	 		= createMenuItem(scriptForm);
	local seperator_3 		= createMenuItem(scriptForm);
	local execute 		= createMenuItem(scriptForm);
	local execute2 		= createMenuItem(scriptForm);
local SettingsItem 			= createMenuItem(scriptForm);
	local closeTabsOnCloseItem 	= createMenuItem(scriptForm);
	local showOnPrintItem 		= createMenuItem(scriptForm);
FileItem.Caption 	= 'Tập tin';
EditItem.Caption 	= 'Chỉnh sửa';
SettingsItem.Caption= 'Cài đặt';

new.Caption 		= 'Mới';
open.Caption 		= 'Mở tệp';
save.Caption 		= 'Lưu';
saveAs.Caption 		= 'Lưu thành';
seperator_1.Caption = '-';
close.Caption 		= 'Đóng';
closeAll.name		= 'closeAll'; -- so when closing MainForm user may save all files...
closeAll.Caption	= 'Đóng tất cả';
new.Shortcut 		= "CTRL+E";	--- can't figure out yet how to override tsynedit hotkeys ffs
open.Shortcut 		= "CTRL+O";
save.Shortcut 		= "CTRL+S";
saveAs.Shortcut 	= "CTRL+ALT+S";
close.Shortcut 		= "CTRL+W";
closeAll.Shortcut	= "CTRL+ALT+W";
ZoomIn.Caption 		= 'Phóng ra (ctrl + lăn chuột lên)';
ZoomOut.Caption 	= 'Thu vào (ctrl + lăn chuột xuống)';
ZoomRestore.Caption = 'Khôi phục thu phóng mặc định';
seperator_2.Caption	= '-';
Syntax.Name			= 'SyntaxMI';
Syntax.Caption		= 'Cú pháp';
	Txt.Name 			= 'TxtSyntax';
	Txt.Caption 		= 'Không';
	Txt.Shortcut 		= "ALT+3";
	Lua.Name 			= 'LuaSyntax';
	Lua.Caption 		= 'Lua';
	Lua.Shortcut 		= "ALT+2";
	Asm.Name 			= 'CeaSyntax';
	Asm.Caption 		= 'Kịch bản cheat engine';
	Asm.Shortcut 		= "ALT+1";
seperator_3.Caption	= '-';
execute.name		= 'executeMI';
execute.Caption		= 'Thực thi kịch bản';
execute.Shortcut	= "F5";
execute2.Caption	= 'Thực thi kịch bản (mục tiêu bản thân)';
execute2.Shortcut	= "SHIFT+F5";


showOnPrintItem.Caption 	= "Hiển thị cửa sổ in";
closeTabsOnCloseItem.Caption= "Đóng tất cả tab khi đóng cửa sổ";
showOnPrintItem.Checked = config.showOnPrint;
closeTabsOnCloseItem.Checked = config.closeTabsOnClose;
-- ZoomIn.Shortcut 		= "CTRL+Num +";
-- ZoomOut.Shortcut 		= "CTRL+Num -";
-- ZoomRestore.Shortcut 	= "CTRL+Num /";
new.OnClick = function(sender)
	selectedView.createNewTab();
end
open.OnClick = function(sender)
	selectedView.openFile();
end
save.onClick = function(sender)
	selectedView.saveFile();
end
saveAs.onClick = function(sender)
	selectedView.saveFile(true);
end
close.OnClick = function(sender)
	selectedView.onTabDestroy();
end
closeAll.OnClick = function(sender)
	-- for _,view in ipairs(views) do
	for i=#views,1,-1 do	-- reversed... as we are modifiying views table when a view is destroyed..
		local view = views[i];
		for pageId=view.PageCount-1,0,-1 do
			local status,err = view.onTabDestroy(view,pageId);
			if (err) then
				return err;
			end
		end
	end
end
ZoomRestore.onClick = function(sender)
	selectedTab.synedit.Font.Size = 10;
end
ZoomIn.onClick = function(sender)
	local font = selectedTab.synedit.Font;
	font.size = font.size+1;
end
ZoomOut.onClick = function(sender)
	local font = selectedTab.synedit.Font;
	font.size = font.size-1;
end
local setSyntax = function(sender)
	local synedit = selectedTab.synedit;
	local hl
	for i=0,Syntax.Count-1 do
		if (Syntax.Item[i] == sender) then
			sender.Checked = true;
			hl = i== 0 and views.TxtSyntax or (i == 1 and views.LuaSyntax or views.CeaSyntax);
		else
			Syntax.Item[i].Checked = false;
		end
	end
	synedit.Highlighter = hl;
end
Txt.Onclick = setSyntax
Lua.Onclick = setSyntax
Asm.Onclick = setSyntax
execute.onClick = function(sender)
	local text = selectedTab.synedit.Lines.Text;
	if (scriptForm.LuaSyntax.Checked) then
		local status,Function,ErrorMessage = pcall(loadstring,text);
		if (Function) then
			Function();
		elseif(ErrorMessage) then
			print(selectedTab.Caption,'Lỗi kịch bản:'..ErrorMessage,0);
		end
	elseif(scriptForm.CeaSyntax.Checked) then
		self = sender == execute2;
		local status,Err = checkAAScript(text,self);
		if (status) then
			if (autoAssemble(text,self)) then -- forgot to activate scripts.
				print(selectedTab.Caption,': kịch bản được kích hoạt thành công',self and '(mục tiêu bản thân)');
			else
				print(selectedTab.Caption,': không thể bật kịch bản',self and '(mục tiêu bản thân)');
			end
		else
			print(selectedTab.Caption,': ',Err,self and '(mục tiêu bản thân)');
		end
	end
end
closeTabsOnCloseItem.onClick = function(sender)
	local active = not sender.Checked;
	updateKeyInReg('closeTabsOnClose',active);
	sender.Checked = active;
end
showOnPrintItem.onClick = function(sender)
	local active = not sender.Checked;
	updateKeyInReg('showOnPrint',active);
	sender.Checked = active;
end
execute2.Onclick = execute.onClick
FileItem.add(new);
FileItem.add(open);
FileItem.add(save);
FileItem.add(saveAs);
FileItem.add(seperator_1);
FileItem.add(close);
FileItem.add(closeAll);
EditItem.add(ZoomIn);
EditItem.add(ZoomOut);
EditItem.add(ZoomRestore);
EditItem.add(seperator_2);
	Syntax.add(Txt);
	Syntax.add(Lua);
	Syntax.add(Asm);
EditItem.add(Syntax);
EditItem.add(seperator_3);
EditItem.add(execute);
EditItem.add(execute2);
SettingsItem.add(showOnPrintItem);
SettingsItem.add(closeTabsOnCloseItem);
mainMenu.Items.add(FileItem);
mainMenu.Items.add(EditItem);
mainMenu.Items.add(SettingsItem);
scriptForm.Menu = mainMenu;
-- bottom panel with buttons and options;
local bottomPanel = createPanel(scriptForm);
bottomPanel.align = alBottom;
bottomPanel.height = config.bottomPanelHeight;
if (not _LUAENGINE_STRIPPED) then
	local luaEngine = getLuaEngine();
	luaEngine.parent = getMainForm();
	luaEngine.top = -10000;
	luaEngine.show(); -- can't fix menu items if it won't show up..
	-- newLuaEngine.sendToBack(); --behind everything
	luaEngine.cbShowOnPrint.Checked=false; -- avoid popup bs
	local newLuaEngine = createLuaEngine()
	luaEngine.OnShow = function(sender)
		sender.hide();
		newLuaEngine.show();
	end
	luaEngine.onenter = luaEngine.OnShow
	_LUAENGINE_STRIPPED = true;
	luaEngine.hide();
	processMessages();
	local mOutput = luaEngine.mOutput;
	mOutput.Parent = bottomPanel;
	mOutput.align = alClient;
	mOutput.Visible = true;
	local mPopup = createPopupMenu(mOutput);
	local menu_items,undo_text = {};
	local mOutputPopupItems = { {name='Copy', 				func=function()writeToClipboard(mOutput.Lines.Text);end},
								{name='Clear',				func=function()undo_text=mOutput.Lines.Text;mOutput.Lines.Text = '';menu_items['Undo'].enabled=true;end},
								{name='ClearSlected',	func=function()undo_text=mOutput.Lines.Text;mOutput.clearSelection();menu_items['Undo'].enabled=true;end},
								{name='Undo',enabled=false,	func=function()if(undo_text)then mOutput.Lines.Text=undo_text;undo_text=false;menu_items['Undo'].enabled=false;end;end},
							};
	for _,itemData in pairs (mOutputPopupItems) do
		local item = createMenuItem(mPopup);
		item.Caption = itemData.name;
		item.OnClick = itemData.func
		if (itemData.enabled ~= nil) then
			item.enabled = itemData.enabled;
		end
		mPopup.Items.add(item);
		menu_items[itemData.name] = item;
	end
	menu_items['Undo'].enabled = false;
	mOutput.onchange = function(sender)
		if (not scriptForm.visible and config.showOnPrint) then
			scriptForm.show();
		end
	end
	mOutput.PopupMenu = mPopup;
	local calculateTextOffsetLength = function(synEdit,lineY)
		local lines = synEdit.Lines;
		local length,count = 1,lines.Count;
		local lineY = (lineY < count and lineY or count)-1;
		for i=0,lineY do -- exclude target line
			length = length + #lines.String[i] + 2; -- ffs new line aren't included, emptyline (newline) are 2 chars long
		end
		return length;
	end
	-- mOutput.OnMouseUp = function(sender)
	mOutput.OnDblClick = function(sender)
		local currentLineY = mOutput.CaretPos.y;
		local line = mOutput.Lines.String[currentLineY]:lower();
		local errorLine = line:match('lỗi trong dòng (%d+) %(.-%).-:'); -- assm error match
		if (not errorLine) then
			errorLine = line:match('^lỗi:.-%.%.%."%]:(%d+):'); -- lua script;
			if (not errorLine) then
				local LuaTagPattern = 'lỗi lua trong kịch bản tại dòng (%d+):%[';
				local LuaBodyPattern= '^%.%.%."%]:(%d+):';	
				local LuaTagLine	= line:match(LuaTagPattern);
				local LuaBodyLine 	= line:match(LuaBodyPattern); -- {$LUA} script part.. error line actually starts at the next line ffs.
				local SecondLine 	= mOutput.Lines.String[currentLineY+(LuaTagLine and 1 or -1)]:lower();
				errorLine = SecondLine:match(LuaTagLine and LuaBodyPattern or LuaTagPattern);
				if (errorLine) then
					errorLine = errorLine + (LuaTagLine or LuaBodyLine) -1;
				end
			end
		end
		if (not errorLine) then
			return;
		end
		if (errorLine) then
			local syn = getCurrentSynEdit();
			local distance = calculateTextOffsetLength(syn,tonumber(errorLine)-1);  -- line starts from 0, in editor from 1..
			syn.SelStart = distance;
			syn.setFocus();
		end
	end
end
local splitter = createSplitter(scriptForm);
splitter.align = alBottom;
local icon_list = createImageList(scriptForm);
icon_list.width = config.toolbar_icon_size;
icon_list.height = config.toolbar_icon_size;
views.icons = icon_list;
views.iconsId = { -- encoded images, might be better to simply load from table file or directory.. but for portability this suits. source: https://www.iconarchive.com/show/blue-bits-icons-by-icojam.1.html
	file_changed 	= icon_list.add(png_to_bmp("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"));
	file_unchanged 	= icon_list.add(png_to_bmp("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"));
	new_file 		= icon_list.add(png_to_bmp("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"));
	open_file		= icon_list.add(png_to_bmp("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"));
	close_file 		= icon_list.add(png_to_bmp("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"));
	save_file 		= icon_list.add(png_to_bmp("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"));
	move_left 		= icon_list.add(png_to_bmp("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"));
	move_right 		= icon_list.add(png_to_bmp("iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAJlklEQVR42tWaf1BU1xXHz31vd/khCjTGHzV2jDj4IzGtJvpHnKROMsYxtdam2klagY6ZScdM82c6nU47ceyMM52pk+igBhtpQJCoSGMFhUVYQAURwd/xFzRaozERCuyD3WXfj9Nz7nu7rCRtUwHdPubOvXvfvrfn88733HvfuQj4Pz/Ef/vC2EWrBXiSARQVhBCgKArVVBRBRZF98k/wzTB6U4EWgGUAGmFZQNYDgDq1TR2SXQA3TvpwVAEmLFq5cGDyk5ul0VQUhpC181l1YIRjNNgQzCQB2Gg9BBgOOXUQLGpbVCcIS8ycMK7dbYQ2lZftbRsVgMnPvfKS/szqKkVVQaXCANz+SnEgFIGONxAU9oZJHggHwBroBytIJdQnixnkolFfH/xx3av638+35fZ0d6//06ZN/hEFmPL9VS8NzF9VqbpUeuAqUhGKS0EJZMMIocp+ghOsKuQbKraiUErK1IUVDiCGJIAwQ31oSQBqBzV8c8VisWbJs3j8+PGzVVVVOR/s3HluxABmLv3ZS11zVlQqBKBGAahWlcjTj4A5bTEIQNYrtqQEQaD0QqhfWAxge0FYBPDLlxeJt15Zgl2dndDR0dFTUFCwdsLEiQc2btz4jeLjPwK89fuNL7yW83oNtxH5fghoIcg/5AJOPdhnmRYYhiGLaXKty3Y4FIJ+zQ99VGTt75X1C889C6tW/AB0XYfOu3fh9u3bev5f8n+dlpa+hSCsYQFs3/HnxW+8vrbWsixBBWNqcIr8jDFt7jdMU5BBNOCE2TC7TQYGgwHh7/Wjn4z39/YKv9+P8+Y/LZYsXSqfNoEKgsA7d+5YJSUl79A1G9/bvBnvGyA/P39xTk7O/wzAbYKQRhOEDWBwWxcEQQB+AvATTA9Oz8gQ859+BsM0vPL5QCCA3d3dEB4YwMKiol8VFhZuHy6AL8bgewobbjq17JMSMqNtlo6EYON0Q9ZGmD0RBAlhe8Iumkby0kDjus+uM2fOClz85NLCuoaGiw/cA9Qr2ybJIkweMGwQR04GBAMkJ43k5EhJIyAqQuvT0AERfVofdnb35Jw+e3bXQwPgNkHYcoqJB4YJBIKoaSylXikrCUAwfX19wP0aAVzr6Mj55PKVYQHct4Riv2vySESG257Qo9IiCDZcysmu/Ww8yYkgSEokoeyz5y88XA9ERyeSkxH1QNQbMnA123A5SjEAt1lCp8+ey2lpbX34AI63vk5OsqaYoEC2JWTDaCQhDU+2nMo53tT0cCUUOR/57uDoZEsq7LR5dHKCWcpI82twrLExy1dfXxQ3HsAYOcV6gOcJg+eBYNCWEAc0ecBXV59d5fUOC2DEPRDpH+oJ3bDniiAHthxK/eD1Vmf9rbw8/jwQ6Y/xRKxX5LKDg7i8oiK7dP/++AWQy46YwLbbcuamZUcQD5aXZ+/atSs+JWT9Oznxuolmaz7Kysqy6B0hvj1gDQlsB0C43W7cs3dvdl5eXvwD8PKBltHisSlTkIOZLhculwt3l5Rkb9++Pb4lxMbv99bDlWAivDp3PEyfngFkvHxBKi4uztq6bVv8eoCMF/sqfXjENRdC7jFihv8SrnkiDWbNni1MeqfYVVSUnZubG58APFGVVvqE1zUXA2oSZzcEvVtjZu8FWPPUeJExIwMLPizIzt26Nf4kxBPV3kM1UO16EvqVZJlrAifnpFLJ7DkHPyc5eWt9WR/siMMgPtpQL4rujMMvE7/N+RhOg5ExnJtRkCFcqiIyu9rQ33r47erDFZviDiAUConyatK+Mkf0etKk0fT2LnTDki/xggDcJKepN49q132lq8+3NHnjSkIOBFQcqYO6pHmguVOlfLgM6CaYdD1nytz0eep1n7+9tnTlhVMnfHHjgUg/e6KipgGbUxcQRBoFsYKcdw2FDWGipAA3eWNKu7fnWm3Zj8+3NNY9MAB+wpcvXZJGy6QXMgDabYaR2TKk9Y+JTWcuwGezfyQCCekoVFXa1h8KoyGvE8JNcTLpyuHuG83elafqvEcfiIQ6OzthfeFhuJvyHSkNl0ul4FTlKKOqduH+RI9HnhPJ4yCU9AjolswUQ9gwQedMHye6qVZVARMvHOi60XZ0+cnqgydG3QMM8JuPjourY2YgG57gdtPyQEW3DSLctFRISU6USwZH/3IUsvP1iqBHg8EBAywhSE4CDbo3wYtHT+/r/LS1YXlLTUXzqAP8dm+juDYmUxrtcbvIaAIgGBe1U5ISMcHjpgGHdM/eEDLFLXWPQibsMTAQBouITOC0rACd1kge+k76qY++/LSpavmoA/yu9IToSGEAF5DxwkNP2+0mb3gIIDkJXZzxVu2xn9PbdCBvmnB+G8nQQEgHE2wP8Fxhsn8I+NHLlYHr3pJVox4D75Q1Q8fYWWy8LB4bBMYkJUBigocnLBkTg7tA0njygJwXIDBAAJyhpz6uiRHSL3n7O6r3vNZUW3lw1D2w4eMW8Y/0ObaEWPduF3psAEHyQZ5xWUKq4wGTs/Q2gOBMfoBjQEpIcBekXjkSunq4mIyvOjDqo1BvTw/sLjsIFm8SRjcCwdkslAsH+Ts8mvZo/ZC0aDV0QxI4ADQKWTBg0D35GgIce60udPHjnVnN9UdKR3ceQLlRI+PQikxe9kZIdE6QbTr4Pbi61oc3Jy2E/tTHOIJptqDrqBHSLTRRGi/GXK0LtZZs/kVbc9OeWBtHFiCybcMBiPdOWPKU047AcJqRjBfXx8/DYNpUOYySXOTkFSbBc+Cy25Lbj+ltu99be7LxWPFQG0dGQvZek7zGsg0FK7L15Jy3Z+LBz/wS762phWupT0AgfZoMZg5gkx69TreyQM4FkNTRqLcWv/vGiWMNH36djcPyQEQGOEQe1pAnPbiUGPz+0fp60WxOxt5HZsihVc7EvEvoDJccJCk3WvDKX9//g0gat/5Q6W4cMYDoxh79WkRCsi2ttgYNjW0PkVBXZ6fYX9OIXbOXiaDwoFxa0JzAm8y8A5pys1XMd3ViU/PJnG1bc+8vuUvvoovXrVvni3nigLHLZKcd23+PfGIkYw2REzrzRFlNI/zzqRUQBLfc9WeQ1Ftn4HvKF7BgwQJ4Py8va8uWLff3RrZhw4ZpdKzlDEHkiPw4yK3VyPYr3GNYbIHoNix85TMnsW5+dkv5ImD9NHnZmzOCSqJI+/yM8XlVQeH8efNu0RQB7e3tpXk7dpy7L4AHdbz4w588PmVaxqH07z6feX7ftrfHjp/07oHi/OFvdD/I4/klyx5X9NCLnm9N2uktK/nG/8XyL4Jiv/3AjQ+5AAAAAElFTkSuQmCC"));
	prev_view 		= icon_list.add(png_to_bmp("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"));
	next_view 		= icon_list.add(png_to_bmp("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"));
	new_view 		= icon_list.add(png_to_bmp("iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAANQklEQVR42u1ZCXCV1RU+57/vf2teXhIIayCgIBULtorEhlUUrIiMgMqiTsWxy4zS6XSkgErRoAI6joodlVZZC9U6VdlkBxFrFkSBYICQkMRAyEJCdt7LW27Pvff/33shL4HMFLEz/Yc///3vO3f5zvnOuef8IPyPX3itN/B/ANd6A1cNwKAB1+kWiyVJp0vDa4MzxDkEAgF/KBisycsv8F8RgJ7JXeOtNuu8RI9nlsvl7EkgtGuye+MiAKHm5uZz1Rdq11P7lbKKqvp2AfTunpxAat+FwIfhVdD6hIn3wY1pY6Cu/Hv455r3gDYGffr2hUkzZ4PFaoO9n34A3+UeBafTBQ88OhsSe/eHEzn7YefWzRAKhYADHmzxByaUVVbVxgTQt1ePDAgFn5M/0MXpim5H97Un01578rSHoHnE44i6lftRh2G+E/jei3/iv3plHR6q07nVboebku24ZcFMPunxP8Ah60B0u5zcbrcC3/Ymbv7Xh3JKjiyj9Fz58zEBpPRI/oL4MvJqAHji5RWwqT4Zb+jVlXs1HW7u7sSWrW/yL1MmYZInnjvj4qCyRcOJ5Vv4mT4jIbc6gN26eHhVC4O7WBEuf2qGWB+QWQ6UnD03JiaAnl2Tsqy6Je2/TR2B5Xd/fhU+aEgBl8MKzO6EKYMS4dt3FoD/7j9CUa0XhAW6JSfDgKx3wDXiQdhY0AgOpx2YywP3hY7BW8/MEcoAjVmyaL704rPneEwAuoUNvxoWSO3XD6bNfw3zGi28X5c4+H7j27ht48f8N3MXYk2fNB7UGAzwleIb85/kd0y4B1Im/RrLmjkfmojwYcYcLC4qkvMxi55Nj/SiM2U/LADRttlseP3Agbz83Dmoqa4Wa4t+7Juayq1WK5wuLERyVimblNQFe/bqxQtO5YPP5zNlJYDkbt3Sc7453BbAE7Mfy0pN7ZumzA5qjPwX9TQoYb6H25wbchx4eEykfekYOX+rMWr2tnKR+UXjfHV1ltVqS1+34R9tAezduzd79OjRtwlh0oTUnAxfpHyhGXrBEJcXtOo35aktDp+wHMnQs3V/lLwh01Y21tzGurlHj2bX1NSkL1y0qH0Aol3Z4MXqJp+hckDjr4gDPGoIho1FAc40c7if3sTi0f2mfk0ZQbIoWoZl5Q/G3AlWDRsqSnl9fb0EIHzgyTlz2gUgfeDPmw7Du/tPgqZpgHQzxsBGh43GNOojGOR0IsUQT6R3ISdlkW4hg6ovSJSmw4fgoSGv5pOyYLwb/eHxWvQ7wowbE2CcvVz4jQCQdTkA0gKLNh/BFV/kc40m1CwM7Vad02ZpXo2boOimtTQuF2Oa9FfN7Cc5VCCE3bjX51daNfqFjCEvnwqIMU7OIbpVe/pPPDjOWsaJOldugec3H4UVB/LlRu02G7DIpiPaNjSkCWsws62evOkC8MNbQW9pUu80ZzAYkiui/CP/gkW3yPF+v59SCKdML1wuFzQEEfS0aaAn9xEA4A5rWecs8PyWo/jXAwVcpwUsFl0oX1jD0KBmUCmiPU1ax2iTXN3audx/5ngrXl/aZkzjkxevQT0hmVdmboWu42ah98AGbkl7AGr+/TFmbv+U95r/ETxEFrhDP3vFFpAAXtiaKwHYbDptziI3TnsMU0aCEFQhYLItwDGDXnRdeOsxHqw/3+H5QCP42LlvojWhK6//Zg9owyaj8+gm3jD4Hggd2Y45G9fzPi/vhemDk3Cs5UznKPTC1mPw3leFYNV1gy5tnVX1Y5hOWpQDjy3bAvagl8JIyAy5IM4o+a5CqnxqBr38LX4Q1vZ6vfTUxeEFAWBQOP5ZePDGRBhrOds5CmV8dgxXZhZzqgdAMUdSh3CEtQwYTRvDcYW/2G1WXD+5L+8W75Dx3IzhPPpMiPSrpxn7DVnK/TE37zhfUtUfpg1KwDGstHMUytj2Ha7KKuaMCSdDRSHDB5QVzEii3olq6LDbw/JrJ6XwngmudikkXhsbGyWAWD4S8Psx+9C3/LW6G2DqIA+O0a4cgKTQ4m15sDq7hJw1Rpw3AJjUcVImabfbZGSRcvRcNykFeigAEOtqamqCp5/LgApuyLSKTggs6IPh/ZLgs5SpZAEPjNZKO0ehxdvzkABIjQrNGQ4acWIFAJ0OO5cHnFC7oJM6sJAA8B4dWIDCJT6+6A2e474lHO/VHKqd4K/FB+2FfEe/h2DqDR4cjSWdo9Di7cdxdY4AwCBMHYZhyghLkNYlAEBzcTAikgDQm/fwdAzgiReW84PuWwm1GocGABEMEgK1+ICtgO/sPx2mDozHUZ0AICn04o7jsIooxMiJGUalCCadCFg8VVHmASZ/lwWHeq67tzf08Dg7pNCTS96Bw11ulzIiiQ6QIweCXM6fGKiFqXo+7LpuBkwZGA8EoHMUenHHCSQAMgqFqcMUTcQCpHmRG4Vp0yqtIAxrJ/a6rAWeWvouP9zlF8acLJJ2UEiN91Xj/ewk3339TLh/gBtHQXHnKPTSzhP4flYJF+eAGUY1xSEBBBLccTKMqpMYjVNZ5TkC5xoJwNkhgDkCQHK6QG9ENo1OZ6YU1FSBdweO8T0DZhGAOBzJizpHoZd2noSVWcWUq+iUiUblQEQVkb/EuRQ9aMlw9iiDiZGlrp3Y87IU+v2yFXAkeURkbsbC0S6JKDSq4SDsG/QITL7OBQQgTKGKysr0jMWLO7bAy7vy8f1sOgdoMl23KqoYNLFR+ecgCpnng8F/aSUQ1iApYYFkp4pgseI8AcCnX1/Jj3UfJWljbN60NAG4gLfXZvP9gx6Ge1MdOCJ0WlkgNzdn1/4vRxYXl3BdZMjtAtidjyuJQigBWIg1TPkALWansOmguG++t44gik7LbmX87+//Dfy6QxVBKvsUf7jZqkIPL+mZJgEIRZG/IVlcRr4k3oCubz/hjcwNDlrazv08EAyIFMNbfb66ROih4uSRT9ul0JLdp2AlRSHTvHo4J0IQBbjT7lDUkRsWG2JGfqTeX7qZQ8bKjVCYOERSgxRA1KObiVsVSKJNQYfm08FOczKVtggegs5Uik5/QDi1VxRFhDoocioa48Qg1L81e027Fliy5xSuyvk+rF2R+oq0Wmhc+oDTeQltlEODCqX421QfX/vJNshz/5QMpam0nDHULTSP2jxaLIy7nHbUmS7OGFnQgEFJMAoaLg4XglTf7KU0UJhPE4twJ7RA/fLH1nYAoABXHYwAkBtnRCWLihLxcS4j7GlGFBJcj5yoWn05txdmwXECQNQgAFKrSBvnuoVJurhddjmnTBAxUuFxTYGhyVQ1TsppvOglEsnCHEO0TpwWgJrXH2kDIMuk0NK9hW0AiEmF1mhRcmKboJLQtwQAmlErqJoWtYYK7iAAJz1DSevGpskyOoERH7zdLidaqW2GzkgoRnmyK16CsgB1elsC3BsIKQAkE0cUqnptVmsA+/btyxo1alSaAQBWf10KgJcU4KLAp1vw1kWhVJzSasFIOSll6svBeTobTiYMBavUOKOnRT6dNvIhh036BQuf7kY4NpJFQUUuawVxa+ALBskXAhCkNhWmEKcFoeLVmWtiAZAWWLbvNK76utQIkVEFuGZUYLQIWQHtlEJrpgwzDjVqaHXlPK44hwAMQatOFCLek/apzbjb6ZBtsgQXnmPWGOZhCFL54nimc48AEGXQHwzy5pYgARAUQu5mQShbOr19Cyz7/DRZ4GzrPCeqkDdTalHAiKhkHkLMIqxFv9WVQ0JJFlR2/zlVdRbDAsIPLEQfh4xA5E/QHIqu7jQjtUZwUMRiXHyO0aQVfIEg+PwSAAhn1nkLFCx9tAMLfF6Eq78+E3YuQ/PhCszkutCYjSghzgqZSsgYTzbw1fPEgs8li0HyGtR3MeWHpMMQ9nBq3HvLFHWQoQibQopJ2XjveTyzcz0PJKZAapyG3UN13OvzQlVlVdnxEyc+E1/tGpq9me0C+KKoFg+drTM2hIYTS3NwjBQfZr/QsAqp5k7Fpo2GOcYYIAH4vc2Yv+dj3jz0PjGADi9FPTIehUuKcher0HYuj/cfMxkGJ1DdUX5cnsSZmZl75s2fP97cc0wKmR9VzWLcLMBb9Zn9ZsHe3pjo36P6xPefDbu+goab75e0sajPNJIe4nZfrII+p3fDbcPT5Hjx3ShIjkwAdncEIFOE0eiNyGco1GYDoVjALicXBbiJstEP92RB48+mGGeMcmLhoILn8RcrsdepnfzWYbdFf0yGr4QF5s2bEBPAwoULB1BMdokawKy9w9o2P3WD+Qk88jn80veOfhN3S0sLlFdWuXoPSdvhGz49TgBgBgBxykoKeSsw791nlsfHx690UdQSVgqQBWhsw+rVq0/HBPBDXuPvmeQenH5nqS9tuoejFv4YAOrgAk9zBRx+e96CbVs2Le1onmsG4M67J7pvGnFX6cW0GQQAzTpbOrxI1uKbyzFvxbMEYOOPE8CYcePdQ8b8slQb+bAHwl+npQnE/2WBvaEcD/9l7oId27b+OAGMHjvOmZTg+YjZXXGxdsFDQaiurFyxf9+eDR3N8x9rIFDje/P3yQAAAABJRU5ErkJggg=="));
	zoom_out 		= icon_list.add(png_to_bmp("iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAEY0lEQVR42u2WS48UVRTH7zn3Vs+YiAQ1M4ZXfDAM4oxRJJ34AXyC+gGAiMygX2J8RY2JJq74AMaETtwrAYGIbpqNmjBuXLhl6UKcftXUPZ7Hre6auKhZmFRI6oaaunW66Pr/zvmfUw3uPl/QtIAWoGkBLUDTAlqApgW0AE0LaAGaFtACNC2gBWhaQAvQtID/HeDQS+dg/sGHvtyzePAYAjjE8kC92QOf0TmUM/CWPwO5j6+DR+f5Wj8ASA+A9JRZjPgoiNxosk12DSSbKAdNpRARcIz0/w7u/nnr12+++Koe4OVzsHf55G13cLXrEUkEee+BzxTk7IEEgj/jOAqAxN1cFniPhEoFsggMRBhIHwVKRwIogXuDIbFgiBIzAIgEHCOncf4OIZPvK+7cuPzz5++drQU4/NoF2Lf03O3t/Std71WkZbbMsO4ZKqBmvROC62TBqpQqBoC6d+ic6Ud9EjmrjgEAV2DixnnhRGS0Sugh+yKWMfsO+v1m79ZnF8/UAjz++hoyQD8/sNINUgG1BQKLlz1YVQykEzwwgFYJvaadvNlJ/qQK6D92AyQlTvfyYREjbQ0nnHVlEPGadbGRJL5IcU4IxM0bvR8/Xa8HeOLUGj589Pl+vl8sBArAIGwdFV6COLHNfCdjIEfSHyJa7k89IVUnqUQqAUESyEG1kwCwP+jvwVgCFCWmdjJAthIU2gfSb6AANz9Zqwd48vS6AkwOrHaDWMUqwIJBRZfZf2Ausz1aA0ustJA1ujUtpAYm873tBYbvkfPWcOy2o3o+3QPTZo5ke3mGAFz/+EI9wFNvrKcKPNtFbtiAlQp4qQBQJ2Tqe3GNF9tIBWSfml72DKWuSRTltLEMm9e1GoPhGPJIaQqBNnTqCW1oKZ1UgDav9659tAuAI29exEcYYMQWkh4IklFWrfvUA/Oc/YBeAVBtpllXC6WqaD9g6XuYTRmSKZOmkIzP4XgCOc/UlHWNxTS2ijRexZ60+UPv6ofv1AMsvfUuPnr0RH/w2PFuxhMmJMt4tRC6DMX7HW5aFo0u2QindvLJQjqVPDgoLVNaw7xu1wwyHI1dbmWZTqIE4Ip0Fos6Brjywfl6gGUBOPZC/97C012e7eXEmVYgC546WVaKheq7gierviNYuMW1ApZVEVhYKSiWDc3xrdGEpxHtiEWDNTsJgGTjzrXe9+/vAmDp1HlcXH2x/8/C8W7gEalZ1xeWAbD3uQd8mfXp5AlqJ9SeMTCeTmkKVd60aWRK9lHH6Gic67SRhiWYWWhmJ60yEAN8t/H2Lnrg1bOwZ/HQ13sPLz+jwnjyVF9Sch0QK7HyZ4VcO4ulnxKq35V+r0yg0iIMkBdxNp1k6kD1PptEsv7645erP13a2KgFUIhXzjB6ASHrJGE2Dmdv2opIc0ll73aMz/TzZ8cI1Wv1vL2pIlG6B/5zrx7bufPZHP327SXaFcD9tFqAplcL0PRqAZpeLUDTqwVoerUATa8WoOnVAjS9/gUOwMdAqwR6twAAAABJRU5ErkJggg=="));
	zoom_in 		= icon_list.add(png_to_bmp("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"));
	search_file 	= icon_list.add(png_to_bmp("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"));
	execute 		= icon_list.add(png_to_bmp("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"));
}
local toolbar = createPanel(scriptForm);
toolbar.name = 'toolbar';toolbar.Caption = '';
-- toolbar.AutoSize = true;
toolbar.height = 38;
toolbar.align = alTop;
toolbar.BevelInner = 0;
toolbar.BevelOuter = 0;
local function createBitBtn(owner)
	local b = createComponentClass('TBitBtn',owner);
	b.parent = owner;
	return b;
end
local function createNewToolBarIcon(owner,name)
	local b = createBitBtn(owner);
	b.DoubleBuffered = true;
	b.GlyphShowMode = 0; -- gsmAlways; show glyph
	b.Images = icon_list;b.ImageIndex = views.iconsId[name];
	b.Layout = 3; -- blGlyphBottom ; 4 = Buttons
	b.setSize(38,38);
	b.AutoSize = tostring(config.toolbar_auto_size) == 'true'; -- not sure how registry returns booleans...
	b.align = alLeft;
	b.margin = 6; -- fix center
	b.name = name;b.Caption = '';
	b.ShowHint = true;
	return b;
end
local function createSeperator(owner,w,h,lineWidth) -- quite useless, easier to use splitter and disable it, but hey it looks fine
	local container = createPanel(owner);container.setSize(w,h);
	container.BevelInner,container.BevelOuter,container.BevelWidth = 0,0,0;
	local sep = createImage(container); sep.align = alClient;
	local bmp = sep.Picture.Bitmap;bmp.Width,bmp.height = container.getSize();
	bmp.TransparentColor = 0;bmp.Transparent = true;
	local c = bmp.Canvas;
	c.Pen.Width = lineWidth or 1;c.Pen.Color = 0xA0A0A0;
	c.Line(container.Width//2,4,container.Width//2,container.Height-4);
	sep.Transparent = true;
	container.align = alLeft;
	return container;
end
-- let's create in reversed order because of the alignment ..
local execute		= createNewToolBarIcon(toolbar,'execute');
createSeperator(toolbar,5,toolbar.height);
local new_view		= createNewToolBarIcon(toolbar,'new_view');
local next_view		= createNewToolBarIcon(toolbar,'next_view');
local prev_view		= createNewToolBarIcon(toolbar,'prev_view');
createSeperator(toolbar,5	,toolbar.height);
local move_right 	= createNewToolBarIcon(toolbar,'move_right');
local move_left 	= createNewToolBarIcon(toolbar,'move_left');
createSeperator(toolbar,5,toolbar.height);
local zoom_out 		= createNewToolBarIcon(toolbar,'zoom_out');
local zoom_in 		= createNewToolBarIcon(toolbar,'zoom_in');
createSeperator(toolbar,5,toolbar.height);
local save 			= createNewToolBarIcon(toolbar,'save_file');
local close 		= createNewToolBarIcon(toolbar,'close_file');
local open 			= createNewToolBarIcon(toolbar,'open_file');
local new 			= createNewToolBarIcon(toolbar,'new_file');
new_view.Enabled = false;
next_view.Enabled = false;
prev_view.Enabled = false;
local removeFocus = function () executeCodeLocal('SetFocus',0); end;
-- local getCurrentSynEdit = function() return selectedTab.synedit; end;
getCurrentSynEdit = function() return selectedTab.synedit; end;
execute.Hint 	= 'Thực thi kịch bản hiện tại (giữ chuyển sang mục tiêu)';
new_view.Hint 	= 'Chuyển kịch bản sang chế độ xem mới';
next_view.Hint 	= 'Chuyển kịch bản sang chế độ xem tiếp';
prev_view.Hint 	= 'Chuyển kịch bản sang chế độ xem trước';
move_right.Hint = 'Chuyển tab sang bên phải';
move_left.Hint 	= 'Chuyển tab sang bên trái';
zoom_out.Hint	= 'Thu vào';
zoom_in.Hint	= 'Phóng ra';
save.Hint		= 'Lưu kịch bản vào tệp';
close.Hint		= 'Đóng kịch bản';
open.Hint		= 'Mở kịch bản từ tệp';
new.Hint		= 'Kịch bản mới';
new.onClick = function(sender)
	selectedView.createNewTab();
end
close.onClick = function(sender)
	selectedView.onTabDestroy();
end
zoom_in.onClick = function(sender)
	local font = getCurrentSynEdit().Font
	font.Size = font.size+1;
end
zoom_out.onClick = function(sender)
	local font = getCurrentSynEdit().Font
	font.Size = font.size-1;
end
move_left.onClick = function(sender)
	selectedView.moveTabLeft();
end
move_right.onClick = function(sender)
	selectedView.moveTabRight();
end
execute.onClick = function(sender,self) -- a bit copypasta... could just access menu items and doClick...
	local tabName = selectedTab.Caption;
	local text = getCurrentSynEdit().Lines.Text;
	if (scriptForm.LuaSyntax.Checked) then
		local status,Function,ErrorMessage = pcall(loadstring,text);
		if (Function) then
			Function();
		elseif(ErrorMessage) then
			print(tabName.Caption,'Lỗi kịch bản:'..ErrorMessage,0);
		end
	elseif(scriptForm.CeaSyntax.Checked) then
		self = self or isKeyPressed(VK_SHIFT);
		local status,Err = autoAssembleCheck(text,true,self);
		if (status) then
			autoAssemble(text,self); -- forgot to activate scripts here too..
			print(tabName,'Tiêm mã thành công',self and '(mục tiêu bản thân)');
		else
			print(tabName,'Lỗi: ',Err,self and '(mục tiêu bản thân)');
		end
	end
end
new_view.onClick = function(sender)
	selectedView.moveToNewView();
end
next_view.onClick = function(sender)
	selectedView.moveToNextView();
end
prev_view.onClick = function(sender)
	selectedView.moveToPrevView();
end
open.onClick = function(sender)
	selectedView.openFile();
end;
save.onClick = function(sender)
	selectedView.saveFile();
end
local mainPanel = createPanel(scriptForm); --scriptForm.Component[25]..
mainPanel.align = alClient;
mainPanel.BevelInner = 0;
mainPanel.BevelOuter = 0;
mainView = createView(mainPanel,views);
mainView.canDestroyLastTab = false;
mainView.createNewTab(); -- we could just leave blank and let user choose what to open..



local function isMemoryRecordDestroyed(mr)
	local al = AddressList;
	local mr_array = al.MemoryRecord;
	for i=0,al.Count-1 do
		if (mr_array[i] == mr) then
			return false;
		end
	end
	return true;
end

local function removeOrphanTabs()
	-- when destroying a tab, it's page index can get shifted! so in order to properly remove a tab we need to fetch tab parent 
	for tab,data in pairs(views.fileTabs) do
		local hasMemoryRecord = data.MemoryRecord
		if (hasMemoryRecord) then
			if (isMemoryRecordDestroyed(hasMemoryRecord)) then
				local targetTab = getCachedObject(integerToUserData(tab));
				views.setOpenedFileTab(targetTab,nil); -- clean up;
				local mr = messageDialog(('Đóng kịch bản - %s'):format(targetTab.Caption),('[Memory Record] - "%s" đã xóa.\nBạn có muốn đóng kịch bản'):format(targetTab.Caption),mtInformation,mbYes,mbNo,mbCancel);
				if (mr == mrYes) then
					local view = getCachedObject(targetTab.parent);
					view.closeTab(targetTab);
				else
					local synedit = targetTab.synedit;
					synedit.onchange(synedit); -- mark is modified...
				end
			end
		end
	end
end
local OnActivate_timer = createTimer(scriptForm,false);
OnActivate_timer.Interval = 1;
OnActivate_timer.OnTimer = function(sender)
	sender.Enabled = false;
	scriptForm.sendToBack();
	scriptForm.bringToFront();
end
scriptForm.OnActivate = function(sender)
	removeOrphanTabs();
	OnActivate_timer.Enabled = true; -- fix that OnActivate bug causing the window to disappear..
end

scriptForm.onClose = function(sender)
	-- honestly can use saveFormPosition, but for upcoming session feature gotta use registry either way..
	if (config.closeTabsOnClose) then
		scriptForm.closeAll.doClick();
	end
	local scriptEditorRegistry = getSettings('scriptEditor');
	scriptEditorRegistry.windowWidth = scriptForm.Width;
	scriptEditorRegistry.windowHeight = scriptForm.Height;
	scriptEditorRegistry.windowLeft = scriptForm.Left;
	scriptEditorRegistry.windowTop = scriptForm.Top;
	scriptEditorRegistry.bottomPanelHeight = bottomPanel.height;
	scriptEditorRegistry.destroy();
	scriptForm.hide();
end
local MainForm_Close = MainForm.OnClose
MainForm.OnClose = function(sender)
	local closeAll = scriptForm.findComponentByName('closeAll')
	if (closeAll) then
		-- if (not scriptForm.visible) then
			-- scriptForm.show();
		-- end
		if (closeAll.OnClick()) then -- user probably canceled...
			return;
		end
		scriptForm.onClose(scriptForm); -- so we could save size and position..
	end
	if (MainForm_Close) then
		-- return MainForm_Close(sender); -- seems that it halts somewhere...
		MainForm_Close(sender);
	end
	return closeCE();
end
-- @DB : https://forum.cheatengine.org/viewtopic.php?p=5567408#5567408
local al = getAddressList();
if (al.PopupMenu) then
	local popMenu = al.PopupMenu;
	local ItemExists = popMenu.open_in_script_editor;
	if (ItemExists) then
		ItemExists.name = '';
		ItemExists.destroy();
	end
	local Item = createMenuItem(popMenu);
	Item.Name = 'open_in_script_editor';
	Item.Shortcut = "CTRL+SPACE";
	Item.Caption = 'Mở trong trình sửa kịch bản';
	Item.OnClick = function(sender)
		local selectedItems = al.getSelectedRecords();
		if (selectedItems) then
			for k,memrecord in pairs(selectedItems) do
				if (memrecord.Type == vtAutoAssembler) then -- onyl autoassemble scripts
					if (not scriptForm.visible) then
						scriptForm.show();
					end
					selectedView.openFile(memrecord);
				end
			end
		end
	end
	local _onpopup = popMenu.OnPopup;
	if (_onpopup) then
		popMenu.OnPopup = function(sender)
			Item.Visible = al.SelCount > 0;
			_onpopup(sender);
		end
	else
		popMenu.OnPopup = function(sender)
			Item.Visible = al.SelCount > 0;
		end
	end
	popMenu.Items.add(Item);
end
if (not MainForm.scriptEditor) then
	local item = createMenuItem(MainForm);
	item.name = 'ScriptEditor';
	item.Caption = 'Script Editor';
	item.Shortcut = 'CTRL+L';
	item.onClick = function() scriptForm.show(); end;
	MainForm.miTable.insert(0,item); -- adds to 'Table' menu
end



