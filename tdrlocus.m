function tdrlocus(Reg, varargin)
% tdrlocus v2
% numerator = "1+0.1.*exp(-s)"; denominator = "2.*s+exp(-s)"; Reg = [-10 5 0 50];
% tdrlocus(Reg, numerator, denominator)
% denominator = "2.*s+exp(-s)"
% numP = [1; 0.0183]; numD = [0; 1]; denP = [2 0; 0 1]; denD = [0; 1];
% tdrlocus(Reg, "1+exp(-s)", "(s^2+6*s+5)+(s+1)*exp(-5*s)+(5+s)*exp(-2*s)+exp(-7*s)") 
%

    %% Add path to functions
    addpath(fullfile(pwd, 'functions'));

    %% GUI Variables

    % GUI window setup
    screenSize = get(groot, 'ScreenSize');  
    figSize = [round(screenSize(3)*0.7), round(screenSize(4)*0.7)];
    figColor = [0.9 0.9 0.9];
    axesColor = [1 1 1];
    figPosition = [(screenSize(3:4) - figSize)/2, figSize];

    % Colors setup
    OLPoleCol = "#FDA6A6"; % Open loop poles
    OLZeroCol = "#8299F6"; % Open loop zeros
    RLLineCol = "#1fdda5"; % Root locus lines

    reg = [-10 5 0 50];  % Default region of time delay root locus if not specified
    
    %% Variables
    % Plot data
    rlocusLines = {};  % Data of plotted root locus lines
    poleDirections = {};
    plotPoles = [];
    plotZeros = [];
    plotCLPoles = [];

    % ___System data___
    % Matrix notation of numerator and denominator quasipolynomial
    numP = 1;
    denP = 1;
    numdP = 0;
    dendP = 0;

    % Parameters
    paramInfo = dictionary();
    paramNum = '';
    paramDen = '';

    % Matrix notation of: denominator + K*numerator
    P = 2;  % num+K*den
    D = 0;  % Delay matrix

    % Calculated poles of closed loop system for given gain (or poles/zeros of open loop system)
    clPoles = [];
    olPoles = [];
    olZeros = [];

    % Precision data
    ds = 0.1;   % Precision of grid
    maxStep = 0.5; % Max and min shift of poles for gain change
    minsStep = 0.01;
    currGain = 1; % Initial gain

    % Limits of gain on slider
    minSliderLim = 1e-4;
    maxSliderLim = 1e8;

    % Modes for adding poles and zeros by clicking
    selectionModes = {'RealPole', 'ImagPole', 'RealZero', 'ImagZero'};
    selectedMode = selectionModes{1};
    
    % Logical variables
    movePoles = false;  % Bool for changing gain by moving poles mode
    movingPolesNow = false; % Bool that indicates if poles are moving
    
    % Region setup
    if nargin > 0
        reg = Reg;
        reg(3) = max([reg(3), 0]);
    end
    xLimits = [reg(1) reg(2)];
    yLimits = [reg(3) reg(4)];

    %% Icon for toolbar setup
    % Undo button icon
    [img, ~, alpha] = imread('./images/undo_icon.png');
    undoIcon = setWhiteBackground(img, alpha);

    % Pan button icon 
    [img, ~, alpha] = imread('./images/pan_icon.png');
    panIcon = setWhiteBackground(img, alpha);
    
    % Zoom in icon
    [img, ~, alpha] = imread('./images/zoom_in_icon.png');
    zoomInIcon = setWhiteBackground(img, alpha);
    
    % Zoom out icon
    [img, ~, alpha] = imread('./images/zoom_out_icon.png');
    zoomOutIcon = setWhiteBackground(img, alpha);
    
    poleIcon = imread('./images/pole_icon.png');    % Single pole icon
    polesIcon = imread('./images/poles_icon.png');  % Double pole icon
    zeroIcon = imread('./images/zero_icon.png');    % Single zero icon
    zerosIcon = imread('./images/zeros_icon.png');  % Double zero icon
    regIcon = imread('./images/region_icon_16px.png');  % Manual region icon
    regAutoIcon = imread('./images/region_auto_icon_18px.png'); % Auto region icon
    loadIconTDTF = imread('./images/fraction2_icon.png');   % Time delay tf icon
    varParamIcon = imread('./images/var_param_icon.png');   % Parameter slider icon
    movePolesIcon = imread('./images/move_poles_icon.png'); % Gain change by dragging icon

    %% GUI Setup

    % Figure
    hFig = uifigure(Position=figPosition, Name='Time delay Root Locus', ...
       Color=figColor);
    hFig.WindowButtonDownFcn = @mousePushed;
    hFig.WindowButtonUpFcn = @mouseReleased;
    
    rowLayout = {'1x', '1x', '1x', '1x', '16x', '1x', '1x'};
    columnLayout = {'3x', '3x', '3x', '12x', '1x'};

    numRows = length(rowLayout);
    numCols = length(columnLayout);

    myLayout = uigridlayout(hFig, RowHeight=rowLayout, ...
        ColumnWidth=columnLayout, BackgroundColor=figColor);

    % _____________________Toolbar_____________________

    hToolbar = uitoolbar(hFig, BackgroundColor=[1 1 1]);

    hTBSelectTDTF = uipushtool(hToolbar, CData=loadIconTDTF, ...
        Tooltip='Edit time delay transfer function', ...
        ClickedCallback=@openTDTFPopupCallback);

    hVarParam = uipushtool(hToolbar, CData=varParamIcon, ...
        Tooltip='Change parameters for time delay transfer function', ...
        ClickedCallback=@openSliderWindow);

    hMovePoles = uitoggletool(hToolbar, CData=movePolesIcon, ...
        Tooltip='Change pole gain', OnCallback=@moveOn, OffCallback=@moveOff);

    hRegSelect = uipushtool(hToolbar, CData=regIcon, ...
        Tooltip='Select plot region', ClickedCallback=@openRegPopupCallback);

    hRegAuto = uipushtool(hToolbar, CData=regAutoIcon, ...
        Tooltip='Auto-adjust plot region');

    % Manual pole/zero selection
    hPoleSelect = uitoggletool(hToolbar, CData=poleIcon, Tooltip='Add real pole', Separator='on', Tag='1');
    hPolesSelect = uitoggletool(hToolbar, CData=polesIcon, Tooltip='Add imaginary pole', Tag='2');
    hZeroSelect = uitoggletool(hToolbar, CData=zeroIcon, Tooltip='Add real zero', Tag='3');
    hZerosSelect = uitoggletool(hToolbar, CData=zerosIcon, Tooltip='Add imaginary zero', Tag='4');
    
    % Zoom in/out + pan buttons
    hPanBtn = uitoggletool(hToolbar, CData=panIcon, Separator='on', OnCallback=@panOn, OffCallback=@panOff);
    hZoomInBtn = uitoggletool(hToolbar, CData=zoomInIcon, OnCallback=@zoomInOn, OffCallback=@zoomInOff);
    hZoomOutBtn = uitoggletool(hToolbar, CData=zoomOutIcon, OnCallback=@zoomOutOn, OffCallback=@zoomOutOff);

    % Shifting undo icon to the right hand side
    spacerIcon = NaN(16, 16, 3); % A completely transparent image
    uipushtool(hToolbar, CData=spacerIcon, Enable='off', Separator='on');
    for empty = 1:round((figSize(1)- 12*28 - 3*5)/28)
        uipushtool(hToolbar, CData=spacerIcon, Enable='off', Separator='off');
    end
    
    % Undo button
    hUndo = uipushtool(hToolbar, CData=undoIcon, TooltipString='Undo', ...
        ClickedCallback=@doUndo);

    % _____________________Toolbar end_____________________

    % Plot axes
    hAx = uiaxes(myLayout, Color=axesColor, Box="on", XGrid="on", YGrid="on", ...
        XLim=xLimits, YLim=yLimits);
    hAx.Layout.Column = [2 numCols];
    hAx.Layout.Row = [1 numRows-2];
    hAx.XLabel.String = 'Real part';
    hAx.YLabel.String = 'Imaginary part';
    hAx.Toolbar.Visible = 'off';
    hold(hAx, 'on');

    % Axis for real = 0 and imag = 0
    hXAxis = plot(hAx, xLimits, [0 0], ':k', 'LineWidth', 1, Tag='axes');
    hYAxis = plot(hAx, [0 0], yLimits, ':k', 'LineWidth', 1, Tag='axes');

    % Gain slider (logarithmic scale)
    gainSlider = uislider(myLayout, Value=log10(currGain));
    gainSlider.Limits = [log10(minSliderLim), log10(maxSliderLim)];
    gainSlider.MajorTicks = linspace(log10(minSliderLim), log10(maxSliderLim), 11);
    gainSlider.Layout.Column = [3 numCols];
    gainSlider.Layout.Row = [numRows-1 numRows];
    
    % Export system
    hExportSys = uibutton(myLayout, 'push', Text='Export to Workspace', ...
        ButtonPushedFcn=@exportSys);
    hExportSys.Layout.Row = 2;
    hExportSys.Layout.Column = 1;

    % Step response
    hStepRes = uibutton(myLayout, 'push', Text='Step response', ...
        ButtonPushedFcn=@stepResponse);
    hStepRes.Layout.Row = 3;
    hStepRes.Layout.Column = 1;

    % Bode plot
    hBodePlot = uibutton(myLayout, 'push', Text='Bode plot', ...
        ButtonPushedFcn=@bodePlot);
    hBodePlot.Layout.Row = 4;
    hBodePlot.Layout.Column = 1;    

    % Gain edit field
    gainEdit = uieditfield(myLayout, 'numeric',...
        Limits=[0, maxSliderLim],...
        ValueChangedFcn=@editGain, Value=currGain, HorizontalAlignment='center');
    gainEdit.Layout.Column = 2;
    gainEdit.Layout.Row = numRows-1;
    
    % Show pole shift direction for added gain
    hPoleDir = uicheckbox(myLayout, Value=0, Text='Toggle pole direction', ...
        ValueChangedFcn=@togglePoleDirection);
    hPoleDir.Layout.Column = 1;
    hPoleDir.Layout.Row = numRows-1;

    %% Callbacks

    % Add listeners to update the axis lines when limits change
    addlistener(hAx, 'XLim', 'PostSet', @(~, ~) updateAxes);
    addlistener(hAx, 'YLim', 'PostSet', @(~, ~) updateAxes);

    % Redraw Root locus for given region
    hRegAuto.ClickedCallback = @(src, event)redrawRegion(src, true);

    % Changing Poles with gain
    gainSlider.ValueChangingFcn = @sliderMovement;
    gainSlider.ValueChangedFcn = @sliderMoved;

    % Choosing pole/zero adding mode
    hPoleSelect.OnCallback = @(src, event)toggleModeSelect(src, hPolesSelect, ...
        hZeroSelect, hZerosSelect, hPanBtn, hZoomInBtn, hZoomOutBtn, hMovePoles);
    hPolesSelect.OnCallback = @(src, event)toggleModeSelect(src, hPoleSelect, ...
        hZeroSelect, hZerosSelect, hPanBtn, hZoomInBtn, hZoomOutBtn, hMovePoles);
    hZeroSelect.OnCallback = @(src, event)toggleModeSelect(src, hPoleSelect, ...
        hPolesSelect, hZerosSelect, hPanBtn, hZoomInBtn, hZoomOutBtn, hMovePoles);
    hZerosSelect.OnCallback = @(src, event)toggleModeSelect(src, hPoleSelect, ...
        hPolesSelect, hZeroSelect, hPanBtn, hZoomInBtn, hZoomOutBtn, hMovePoles);

    %% ____________________ Algorithm start _______________________

    % Stack initialization
    undoStack = UndoStack(10);
    helpStack = UndoStack(1);

    if nargin > 0
        setCurrentSystem(varargin{:});
        drawRL;
    end
    
    % Saves all important info about current system
    function setCurrentSystem(varargin)

        % Check for Matrix or string notation
        if isnumeric(varargin{1})
            numP = varargin{1};
            numD = varargin{2};
            denP = varargin{3};
            denD = varargin{4};
        else
            params = regexp(strcat(varargin{1}, '_', varargin{2}), 'K\d+', 'match');

            if isempty(params) % Check for parametric notation
                paramInfo = dictionary();
                paramNum = '';
                paramDen = '';
                [numP, numD] = string2matrix(varargin{1});
                [denP, denD] = string2matrix(varargin{2});
            else
                saveAndSetParams(params)
                paramNum = char(varargin{1});
                paramDen = char(varargin{2});
                num = substituteParams(paramNum);
                den = substituteParams(paramDen);
                [numP, numD] = string2matrix(num);
                [denP, denD] = string2matrix(den);
            end
        end
        
        % Create matrix for denominator + K*numerator
        [numP, denP, D] = create_rl_matrix(numP, numD, denP, denD);
        P = denP+currGain*numP;
        
        % Compute all poles/zeros of closed/open system
        olZeros = compute_roots(reg, numP, D, ds);
        olPoles = compute_roots(reg, denP, D, ds);
        clPoles = compute_roots(reg, P, D, ds);

        % Adjust max step depending on number of poles/zeros
        maxStep = reg(4)/(10*(length(olPoles) + length(olZeros)));
        getAdditionalInfo
    end
    
    % Saves all other not that important info about system
    function getAdditionalInfo
        % Get partial derivatives of "s"
        numdP = derivate_quasipolynomial(numP, D);
        dendP = derivate_quasipolynomial(denP, D);
    end
    
    % Draw and saves graphical data
    function drawRL
        set(hFig, "Pointer", "watch"); % Waiting cursor
        drawnow

        % Draw root locus
        lines = draw_rl_lines(reg, 1e10, olZeros, olPoles, numP, denP, D,...
            numdP, dendP, ds, minsStep, maxStep);
        numLines = length(lines);
        rlocusLines = cell(2*numLines, 1);
        for i = 1:numLines
            rlocusLines{2*i-1} = plot(hAx, real(lines{i}), imag(lines{i}), ...
                Color=RLLineCol, Tag='rlocus', LineWidth=1.5);
            rlocusLines{2*i} = plot(hAx, real(lines{i}), -imag(lines{i}), ...
                Color=RLLineCol, Tag='rlocus', LineWidth=1.5);
            reg(1) = min([reg(1), min(real(lines{i}))]);
            reg(2) = max([reg(2), max(real(lines{i}))]);
            reg(4) = max([reg(4), max(imag(lines{i}))]);
        end
        drawPolesZeros
        saveToStack(true)
        set(hFig, "Pointer", "arrow");
    end
    
    % Load new parameters and assign values to them (1 by default)
    function saveAndSetParams(params)
        if paramInfo.numEntries == 0
            paramInfo(params) = ones(1, length(params));  
        elseif ~all(isKey(paramInfo, params)) % Add new, remove old, keep these param from params that are already in paramInfo
            newParams = params(~isKey(paramInfo, params));
            allKeys = paramInfo.keys;
            oldKeys = allKeys(~ismember(allKeys, params));
            paramInfo = paramInfo.remove(oldKeys);
            paramInfo(newParams) = ones(1, length(newParams));
        end
    end
    
    % Substitute values to parameters
    function subStr = substituteParams(parStr)
        subStr = replace(parStr, paramInfo.keys, string(paramInfo(paramInfo.keys)));
    end
    
    % Draw all the poles of closed loop system corresponding to given gain
    function updateCLPoles
        plotCLPoles.XData = [real(clPoles), real(clPoles)];
        plotCLPoles.YData = [imag(clPoles), -imag(clPoles)];
        
        % Direction arrows
        if hPoleDir.Value
            updatePoleDirection
        end
    end
    
    % Draw poles and zeros of open loop system
    function drawPolesZeros
        plotPoles = plot(hAx, [real(olPoles), real(olPoles)], [imag(olPoles), -imag(olPoles)], 'x', ...
                MarkerFaceColor=OLPoleCol, MarkerEdgeColor=OLPoleCol, ...
                MarkerSize=10, LineWidth=1.5, Tag='olpole');
        plotZeros = plot(hAx, [real(olZeros), real(olZeros)], [imag(olZeros), -imag(olZeros)], 'o', ...
                MarkerEdgeColor=OLZeroCol, MarkerSize=10, LineWidth=1.5, ...
                Tag='olzero');
        plotCLPoles = plot(hAx, [real(clPoles), real(clPoles)], [imag(clPoles), -imag(clPoles)], ...
                'x' ,Tag='clpole', MarkerSize=10, LineWidth=1.5, ...
                MarkerFaceColor='red', MarkerEdgeColor='red');
    end
    
    % Adds state of root locus to the stack
    function saveToStack(newState)
        stackRL = cell([2 length(rlocusLines)]);
        for idx = 1:length(rlocusLines)
            stackRL{1, idx} = rlocusLines{idx}.XData;
            stackRL{2, idx} = rlocusLines{idx}.YData;
        end
    
        stackOLPole = olPoles;
        stackOLZero = olZeros;
        stackCLPole = clPoles;
    
        stackNumP = numP;
        stackDenP = denP;
        stackD = D; 
        stackGain = currGain;
        stackParNum = paramNum;
        stackParDen = paramDen;
        stackReg = reg;
        stackParamInfo = paramInfo;
        
        % saves to undo stack from temporary stack
        if helpStack.getSize() > 0
            [stackRLtmp, stackOLPoletmp, stackOLZerotmp, stackCLPoletmp, ...
                stackNumPtmp, stackDenPtmp, stackDtmp, stackGaintmp, ...
                stackParNumtmp, stackParDentmp, stackParamInfotmp, stackRegtmp] = helpStack.pop();
            if newState
                undoStack.push(stackRLtmp, stackOLPoletmp, stackOLZerotmp, ...
                    stackCLPoletmp, stackNumPtmp, stackDenPtmp, stackDtmp, ...
                    stackGaintmp, stackParNumtmp, stackParDentmp, stackParamInfotmp, stackRegtmp);
            end
        end
        helpStack.push(stackRL, stackOLPole, stackOLZero, stackCLPole, ...
            stackNumP, stackDenP, stackD, stackGain, stackParNum, ...
            stackParDen, stackParamInfo, stackReg);
        end
    
    % Redraw root locus for updated system
    function redraw(varargin)
        clearCanvas
        if isnumeric(varargin{1}) % Matrix notation
            newNumP = varargin{1};
            newNumD = varargin{3};
            newDenP = varargin{2};
            newDenD = varargin{3};
            setCurrentSystem(newNumP, newNumD, newDenP, newDenD);
        else % string notation
            newNum = varargin{1};
            newDen = varargin{2};
            setCurrentSystem(newNum, newDen);
        end
       
        drawRL
        if hPoleDir.Value
            clearPolesDirection
            drawPoleDirection
        end
    end
    
    % Clears complex plane
    function clearCanvas
        % Delete each line and sets it to empty 
        for i = 1:length(rlocusLines)
            data = rlocusLines{i};
            delete(data);
        end
        delete(plotPoles);
        delete(plotZeros);
        delete(plotCLPoles);
        setEmptyData
    end
    
    % Clears plot data
    function setEmptyData
        rlocusLines = [];
        plotPoles = [];
        plotZeros = [];
        plotCLPoles = [];
    end
    
    %% Callback functions
    
    % Undo action callback
    function doUndo(~, ~)
        if undoStack.getSize() > 0
            % Pop from stack
            [rlocusLinesData, olPolesData, olZerosData, clPolesData, ...
                numPData, denPData, DData, gainData, parNumData, parDenData,...
                paramInfoData, regData] = undoStack.undo();
            
            % Draw if any data poped from the stack
            if ~isempty(rlocusLinesData)
                clearCanvas();
                % Plot root locus
                for idx = 1:length(rlocusLinesData)
                    rlocusLines{idx} = plot(hAx, rlocusLinesData{1, idx}, ...
                        rlocusLinesData{2, idx}, Color=RLLineCol , ...
                        Tag='rlocus', LineWidth=1.5);
                end
                
                olPoles = olPolesData;
                olZeros = olZerosData;
                clPoles = clPolesData;
                numP = numPData;
                denP = denPData;
                D = DData;
                currGain = gainData;
                gainEdit.Value = currGain;
                gainSlider.Value = log10(currGain);
                gainSlider.Value = log10(currGain);
                paramNum = parNumData;
                paramDen = parDenData;
                paramInfo = paramInfoData;
                reg = regData;
    
                drawPolesZeros
                setCurrentSystem(numP, D, denP, D);
                saveToStack(false);
            end
        end 
    end 
    
    % Axis callback function
    function updateAxes
    % Update the x and y axis line
        set(hXAxis, XData=hAx.XLim, YData=[0 0]);
        set(hYAxis, XData=[0 0], YData=hAx.YLim);
    end
    
    % Export system to workspace
    function exportSys(~,~)
        s = tf('s');
        charNum = char(strcat("(", matrix2string(numP, D), ")"));
        charDen = char(strcat("(", matrix2string(denP, D), ")"));
        sys = currGain*eval(charNum)/eval(charDen);
        assignin('base', 'tdsys', sys);
        clear s
    end

    function stepResponse(~, ~)
        s = tf('s');
        charNum = char(strcat("(", matrix2string(numP, D), ")"));
        charDen = char(strcat("(", matrix2string(denP, D), ")"));
        sys = eval(charNum)/eval(charDen);
        step(feedback(sys, currGain));
        clear s
    end

    function bodePlot(~, ~)
        s = tf('s');
        charNum = char(strcat("(", matrix2string(numP, D), ")"));
        charDen = char(strcat("(", matrix2string(denP, D), ")"));
        sys = currGain*eval(charNum)/eval(charDen);
        bode(sys)
        clear s
    end

    % Load new Time delay transfer function
    function openTDTFPopupCallback(~, ~)

        % Set up figure
        pixelWidth = 7;
        strnum = matrix2string(numP, D);
        strden = matrix2string(denP, D);
        fieldWidth = max([length(strnum), length(strden), 16]);
        hTDTFPopupFig = uifigure(Name='Edit Time delay transfer function', ...
            Position=[500, 300, fieldWidth*2*pixelWidth+50, 150]);
        hTDTFLabel = uilabel(hTDTFPopupFig, Text='Choose time delay transfer function', ...
            Position=[round(fieldWidth*pixelWidth/4) 125 250 22]);
        hNumEditField = uieditfield(hTDTFPopupFig, ...
            Position=[round(fieldWidth*pixelWidth/4) 90 fieldWidth*pixelWidth 22]);
        hFraction = uilabel(hTDTFPopupFig, Text=repmat('_', 1, fieldWidth), ...
            Position=[round(fieldWidth*pixelWidth/4) 75 fieldWidth*(pixelWidth+1) 22]);
        hDenEditField = uieditfield(hTDTFPopupFig, ...
            Position=[round(fieldWidth*pixelWidth/4) 45 fieldWidth*pixelWidth 22]);
        hEditButton = uibutton(hTDTFPopupFig, Text='Edit', ...
            Position=[round(fieldWidth*pixelWidth) 12 50 22], ButtonPushedFcn=@generateNewTDRL);
        hLoadNumButton = uibutton(hTDTFPopupFig, Text='Load Numerator', ...
            Position=[round(fieldWidth*pixelWidth*4/3) 90 120 22], ButtonPushedFcn=@(~,~)loadPD(true));
        hLoadDenButton = uibutton(hTDTFPopupFig, Text='Load Denominator', ...
            Position=[round(fieldWidth*pixelWidth*4/3) 45 120 22], ButtonPushedFcn=@(~,~)loadPD(false));
    
        hNumEditField.Value = strnum;
        hDenEditField.Value = strden;
    
        function generateNewTDRL(~, ~)
            redraw(string(hNumEditField.Value), string(hDenEditField.Value));
            close(hTDTFPopupFig);
        end
        
        % Load P and D matrices from workspace
        function loadPD(isNum)
            Pmat = 1;
            Dmat = 0;
            nameP = '';
            nameD = '';
            hPDPopupFig = uifigure(Name='Choose P and D matrix', Position=[500, 300, 350, 300]);
            vars = evalin('base', 'whos');
            numVars = vars({vars.class}=="double");
            varNames = {numVars.name};
            hChooseP = uilabel(hPDPopupFig, Text='Choose P matrix', Position=[50 260 250 22]);
            hChooseD = uilabel(hPDPopupFig, Text='Choose D matrix', Position=[200 260 250 22]);
            hListboxP = uilistbox(hPDPopupFig, Position=[50, 100, 100, 150], ...
                Items=varNames, ClickedFcn=@listboxCallback, Tag='Plistbox');
            hListboxD = uilistbox(hPDPopupFig, Position=[200, 100, 100, 150], ...
                Items=varNames, ClickedFcn=@listboxCallback, Tag='Dlistbox');        
    
            hChoosenP = uilabel(hPDPopupFig, Text=strcat('Choosen P matrix:', nameP), Position=[50 60 250 22]);
            hChoosenD = uilabel(hPDPopupFig, Text=strcat('Choosen D matrix:', nameD), Position=[200 60 250 22]);
            hSavePDButton = uibutton(hPDPopupFig, Text='Choose matrices', Position=[50 20 150 22], ButtonPushedFcn=@(~,~)savePD);
            
            function listboxCallback(src, event)
                idx = event.InteractionInformation.Item;
                selectedMat = src.Items{idx};
                newMat = evalin('base', selectedMat);
                if src.Tag == 'Plistbox'
                    nameP = selectedMat;
                    hChoosenP.Text = strcat('Choosen P matrix:', nameP);
                    Pmat = newMat;
                elseif src.Tag == 'Dlistbox'
                    nameD = selectedMat;
                    hChoosenD.Text = strcat('Choosen D matrix:', nameD);
                    Dmat = newMat; 
                end   
            end
    
            function savePD
                if isNum
                    hNumEditField.Value = matrix2string(Pmat, Dmat);
                else
                    hDenEditField.Value = matrix2string(Pmat, Dmat);
                end
                close(hPDPopupFig)
            end
        end
    end
    
    % Gain slider callback (update during changing slider value)
    function sliderMovement(~, event)
        currGain = 10^event.Value;
        dK = currGain - gainEdit.Value;
        
        newPoles = iterate_root(clPoles, numP, denP, D, dendP, numdP, ds, gainEdit.Value, dK);

        % If shift is too big, compute poles directly
        if max(abs(newPoles - clPoles)) > maxStep*4
            clPoles = compute_roots(reg, denP+currGain*numP, D, ds);
        else
            clPoles = newPoles;
        end
        gainEdit.Value = currGain;
        updateCLPoles;
    end
    
    % Gain slider callback (update after slider movement stopped)
    function sliderMoved(~, event)
        currGain = 10^event.Value;
        P = denP+currGain*numP;
        clPoles = compute_roots(reg, P, D, ds);
        gainEdit.Value = currGain;
    
        updateCLPoles;
        saveToStack(true);
    end
    
    % Edit gain callback
    function editGain(src, ~)
        clPoles = compute_roots(reg, denP+src.Value*numP, D, ds);
        if src.Value < minSliderLim
            gainSlider.Value = log10(minSliderLim);
        else
            gainSlider.Value = log10(src.Value);
        end
        updateCLPoles;
    end
    
    % Togle visibility mode pole change directions
    function togglePoleDirection(src, ~)
        if src.Value
            drawPoleDirection
        else
            clearPolesDirection
        end
    end
    
    % Clear directions
    function clearPolesDirection
        for i = 1:length(poleDirections)
            data = poleDirections{i};
            delete(data);
        end
        poleDirections = {};        
    end
    
    % Draw directions
    function drawPoleDirection
        if ~isempty(clPoles)
            num = evaluate_poly(clPoles, numP, D, 0.1, false);
            den = evaluate_poly(clPoles, dendP, D, 0.1, false) + currGain.*evaluate_poly(clPoles, numdP, D, 0.1, false);
            C = -(num./den);
            C = C./abs(C);
            scaleRatio = 1/2;
            for i = 1:length(clPoles)
                poleDirections{2*i-1} = quiver(hAx, real(clPoles(i)), imag(clPoles(i)), ...
                    scaleRatio*real(C(i)), scaleRatio*imag(C(i)), 'b', 'LineWidth', 1.2, 'MaxHeadSize', 2);
                
                poleDirections{2*i} = quiver(hAx, real(clPoles(i)), -imag(clPoles(i)), ...
                    scaleRatio*real(C(i)), -scaleRatio*imag(C(i)), 'b', 'LineWidth', 1.2, 'MaxHeadSize', 2);
            end
        end
    end

    % Update directions while moving poles
    function updatePoleDirection
        num = evaluate_poly(clPoles, numP, D, 0.1, false);
        den = evaluate_poly(clPoles, dendP, D, 0.1, false) + currGain.*evaluate_poly(clPoles, numdP, D, 0.1, false);
        C = -(num./den);
        C = C./abs(C);
        scaleRatio = 1/2;
        for i = 1:length(clPoles)
            poleDirections{2*i-1}.XData = real(clPoles(i));
            poleDirections{2*i}.XData = real(clPoles(i));
            poleDirections{2*i-1}.YData = imag(clPoles(i));
            poleDirections{2*i}.YData = -imag(clPoles(i)); 
            poleDirections{2*i-1}.UData = scaleRatio*real(C(i));
            poleDirections{2*i}.UData = scaleRatio*real(C(i));
            poleDirections{2*i-1}.VData = scaleRatio*imag(C(i));
            poleDirections{2*i}.VData = -scaleRatio*imag(C(i));  
        end
    end

    % Parameter slider window callback   
    function openSliderWindow(~, ~)   
        numSliders = paramInfo.numEntries;
        textWidth = max([length(paramNum), length(paramDen), 16])*7;
        
        hSliderFig = uifigure(Name='Slider Window', ...
                Position=[500, 300, max([400, textWidth+120]), numSliders*60+100]);
        
        hNumText = uilabel(hSliderFig, Position=[50, numSliders*60+70, textWidth, 20], Text=paramNum, ...
                FontSize=14, HorizontalAlignment="right");
        hLineText = uilabel(hSliderFig, Position=[50, numSliders*60+62, textWidth, 20], Text=repmat('_', 1, textWidth/7), ...
            FontSize=14, HorizontalAlignment="right");
        hLineText.WordWrap = 'on';
        hDenText = uilabel(hSliderFig, Position=[50, numSliders*60+45, textWidth, 20], Text=paramDen, ...
                FontSize=14, HorizontalAlignment="right");
    
        paramEdits = dictionary();
        paramSliders = dictionary();
        
        if paramInfo.numEntries > 0
            keys = paramInfo.keys;
            for i = 1:length(keys)
                paramKey = keys(i);
                uilabel(hSliderFig, Text=paramKey, ...
                    Position=[20, numSliders*60-(i-1)*50-20, 120, 20]);
                
                % Create edit field
                paramEdits(paramKey) = uieditfield(hSliderFig, 'numeric', Value=paramInfo(paramKey), ...
                    Position=[60, numSliders*60-(i-1)*50-20, 80, 20], Tag=paramKey, ...
                    ValueChangedFcn=@editParamValue, ValueDisplayFormat='%.3f');
            
                % Create the slider
                paramSliders(paramKey) = uislider(hSliderFig, Position=[160, numSliders*60-(i-1)*50, 200, 3], ...
                    Limits=[-10 10], Value=paramInfo(paramKey), ... 
                    Tag=paramKey, ValueChangedFcn=@editParamValue); % Tag the slider for future reference
            end
        end
    
        function editParamValue(src, ~)
            parKey = src.Tag;
            paramEdits(parKey).Value = src.Value;
            paramSliders(parKey).Value = src.Value;
            paramInfo(parKey) = src.Value;
            redraw(paramNum, paramDen);
        end
    end
    
    % Manual region callback
    function openRegPopupCallback(src, ~)
        hRegPopupFig = uifigure(Name='Select region limits', Position=[500, 300, 250, 160]);
        hRegLabel = uilabel(hRegPopupFig, Text='Select plot region limits', Position=[60 135 250 22]);
        uilabel(hRegPopupFig, Text='Real limits:', Position=[5 90 90 22]);
        uilabel(hRegPopupFig, Text='Min', Position=[125 112 90 22]);
        uilabel(hRegPopupFig, Text='Max', Position=[200 112 90 22]);
        hMinReal = uieditfield(hRegPopupFig, 'numeric', Position=[110 90 50 22], Value=reg(1));
        hMaxReal = uieditfield(hRegPopupFig, 'numeric', Position=[185 90 50 22], Value=reg(2));
        uilabel(hRegPopupFig, Text='Imaginary limits:', Position=[5 45 90 22]);
        uilabel(hRegPopupFig, Text='Min', Position=[125 67 50 22]);
        uilabel(hRegPopupFig, Text='Max', Position=[200 67 50 22]);
        hMinImag = uieditfield(hRegPopupFig, 'numeric', Position=[110 45 50 22], Value=reg(3));
        hMaxImag = uieditfield(hRegPopupFig, "numeric", Position=[185 45 50 22], Value=reg(4));
        hPlotButton = uibutton(hRegPopupFig, Text="Plot", Position=[100 10 50 22], ButtonPushedFcn=@setNewReg);
        
    
        function setNewReg(~, ~)
            reg = [hMinReal.Value hMaxReal.Value min([hMinImag.Value, 0]) hMaxImag.Value];
            redrawRegion(src, false);
            close(hRegPopupFig);
        end
    
    end
    
    % Automatic region callback
    function redrawRegion(~, auto)
        if auto == true
            xMin = hAx.XLim(1);
            xMax = hAx.XLim(2);
            yMin = max([hAx.YLim(1), 0]);
            yMax = hAx.YLim(2);
            reg = [xMin xMax yMin yMax];
        end
        
        redraw(numP, denP, D)
    end
    
    % Enable changing gain by dragging
    function moveOn(src, ~)
        toggleOffOthers(src, hPoleSelect, hPolesSelect, ...
                hZeroSelect, hZerosSelect, ...
                hZoomOutBtn, hZoomInBtn, hPanBtn);
        set(hFig, Pointer='custom', PointerShapeCData=moveCursorMat, ...
            PointerShapeHotSpot=[10, 9]);
        movePoles= true;
    end
    
    % Disable changing poles by dragging
    function moveOff(~, ~)
        set(hFig, Pointer='arrow');
        movePoles = false;
    end
    
    % Add poles/zeros or drag poles when mouse pushed
    function mousePushed(~, ~)
        addingPZ = (hPoleSelect.State == "on") | (hPolesSelect.State == "on") ...
            | (hZeroSelect.State == "on") | (hZerosSelect.State == "on");

        % Adding poles/zeros
        if addingPZ
            cp = get(hAx, 'CurrentPoint');
            x = cp(1,1);
            y = cp(1,2);
            newDen = 1;
            newNum = 1;
            if selectedMode == "RealPole"
                newDen = poly(x);
            elseif selectedMode == "ImagPole"
                newDen = poly([x+y*1i, x-y*1i]);
            elseif selectedMode == "RealZero"
                newNum = poly(x);
            elseif selectedMode == "ImagZero"
                newNum = poly([x+y*1i, x-y*1i]);
            end
            
            orderNum = size(numP, 2) + size(newNum, 2) - 1;
            orderDen = size(denP, 2) + size(newDen, 2) - 1;
    
            if max([orderNum, orderDen]) < 8
                convNum = zeros(size(D, 1), orderNum);
                convDen = zeros(size(D, 1), orderDen);
                for i = 1:size(numP, 1)
                    convNum(i, :) = conv(numP(i,:), newNum);
                end
                for i = 1:size(denP, 1)
                    convDen(i, :) = conv(denP(i,:), newDen);
                end
                redraw(convNum, convDen, D);
            end
        
        % Moving poles by dragging
        elseif movePoles
            movingPolesNow = true;
            set(hFig, WindowButtonMotionFcn=@holdAndChangeGain);
        end
    end
    
    % Stop dragging poles
    function mouseReleased(~, ~)
        movingPolesNow = false;
        if movePoles
            set(hFig, Pointer='custom', PointerShapeCData=moveCursorMat, ...
                PointerShapeHotSpot=[10, 9]);
            saveToStack(true);
        end
        set(hFig, WindowButtonMotionFcn=[]);
    end
    
    % Changing poles by draging
    function holdAndChangeGain(~, ~)
        currPoint = get(hAx, 'CurrentPoint');
        set(hFig, Pointer='custom', PointerShapeCData=holdCursorMat, ...
            PointerShapeHotSpot=[10, 9]);
        x = currPoint(1,1);
        y = currPoint(1,2);
        activeXReg = diff(hAx.XLim)/10;
        activeYReg = diff(hAx.YLim)/10;
        dists = sqrt(((plotCLPoles.XData - x) / activeXReg).^2 +...
            ((plotCLPoles.YData - y) / activeYReg).^2);
    
        [minVal, minIdx] = min(dists);
        if minVal < (activeXReg + activeYReg) && movingPolesNow
            if minIdx > length(clPoles) % conjurates
                minIdx = minIdx - length(clPoles);
                y = -y;
            end
            s0 = clPoles(minIdx);
            K0 = currGain;
            sVec = (x + y*1i) - s0;
            rProj = pole_projection(s0, K0, numP, denP, numdP, dendP, D, sVec);
            
            
            dK = get_dk(s0, K0, numP, numdP, dendP, D, rProj);
            K = K0 + dK;
            K = min([abs(K), maxSliderLim]);
            currP = denP + K*numP;
            clPoles = compute_roots(reg, currP, D, ds);
            %clPoles = iterate_root(clPoles, numP, denP, D, dendP, numdP, K0, dK, 0.01, 0.1);
            currGain = K;
            gainEdit.Value = currGain;
            gainSlider.Value = log10(currGain);
            if K < minSliderLim
                gainSlider.Value = log10(minSliderLim);
            else
                gainSlider.Value = log10(K);
            end
            updateCLPoles
            pause(0.05)
        end
    end
    
    % Toggle of other toolbar buttons
    function toggleOffOthers(src, varargin)
        for i = 1:length(varargin)
            if isa(varargin{i}, class(src)) % Checks if varargin is ToggleTool
                varargin{i}.State = "off";
            end
        end
    end
    
    % Toggle pole/zero adding mode callback
    function toggleModeSelect(src, varargin)
        toggleOffOthers(src, varargin{:});
        idx = str2num(src.Tag);
        selectedMode = selectionModes{idx};
    end
    
    % ___________________________Pan/Zoom___________________________ %
    % Pan on callback
    function panOn(src, ~)
        toggleOffOthers(src, hPoleSelect, hPolesSelect, ...
                hZeroSelect, hZerosSelect, ...
                hMovePoles, hZoomInBtn, hZoomOutBtn);
        pan(hAx.Parent, 'on');
    end
    
    % Pan off callback
    function panOff(~, ~)
        pan(hAx.Parent, 'off');
    end
    
    % Zoom in enabled callback
    function zoomInOn(src, ~)
        toggleOffOthers(src, hPoleSelect, hPolesSelect, ...
                hZeroSelect, hZerosSelect, ...
                hMovePoles, hPanBtn, hZoomOutBtn);
        z = zoom(hAx);
        z.Direction = "in";
        z.Enable = "on";
    end
    
    % Zoom in disabled callback
    function zoomInOff(~, ~)
        z = zoom(hAx);
        z.Direction = "in";
        z.Enable = "off";
    end
    
    % Zoom out enabled callback
    function zoomOutOn(src, ~)
        toggleOffOthers(src, hPoleSelect, hPolesSelect, ...
                hZeroSelect, hZerosSelect, ...
                hMovePoles, hZoomInBtn, hPanBtn);
        z = zoom(hAx);
        z.Direction = "out";
        z.Enable = "on";
    end
    
    % Zoom out disabled callback
    function zoomOutOff(~, ~)
        z = zoom(hAx);
        z.Direction = "out";
        z.Enable = "off";
    end
    
end
