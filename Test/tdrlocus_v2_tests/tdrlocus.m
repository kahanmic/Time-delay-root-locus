function tdrlocus(reg, varargin)
% tdrlocus v2
% numerator = "1+0.1.*exp(-s)"; denominator = "2.*s+exp(-s)"; Reg = [-10 5 0 50];
% tdrlocus(Reg, numerator, denominator)
% denominator = "2.*s+exp(-s)"
%numP = [1; 0.0183]; numD = [0; 1]; denP = [2 0; 0 1]; denD = [0; 1];

    %% Add path to functions
    addpath(fullfile(pwd, 'functions'));

    %% GUI Variables
    screenSize = get(groot, 'ScreenSize');  % Get user's screen size
    figSize = [round(screenSize(3)*0.7), round(screenSize(4)*0.7)];
    figColor = [0.9 0.9 0.9];
    axesColor = [1 1 1];
    figPosition = [(screenSize(3:4) - figSize)/2, figSize];

    % Colors setup
    OLPoleCol = "#FDA6A6"; % Open loop poles
    OLZeroCol = "#8299F6"; % Open loop zeros
    RLLineCol = "#1fdda5"; % Root locus lines
    defaultReg = [-10 5 -50 50];  % Default region of time delay root locus if not specified
    
    %% Variables
    % Plot data
    rlocusLines = {};  % Data of plotted root locus lines
    plotPoles = [];
    plotZeros = [];
    plotCLPoles = [];

    % ___System data___
    % Matrix notation of numerator and denominator quasipolynomial
    numP = 1;
    denP = 1;
    numdP = 0;
    dendP = 0;

    % Matrix notation of: denominator + K*numerator
    P = 2;
    D = 0;

    % Calculated poles of closed loop system for given gain (or poles/zeros of open loop system)
    clPoles = [];
    olPoles = [];
    olZeros = [];

    % Precision data
    ds = 0.1;   % Precision of grid
    maxsStep = 0.5; % Max and min shift of poles for gain change
    minsStep = 0.01;

    % Limits of gain on slider
    minSliderLim = 0;
    maxSliderLim = 1e10;
    
    % Logical variables
    movePoles = false;  % Bool for changing gain by moving poles mode
    movingPolesNow = false; % Bool that indicates if poles are moving

    if nargin > 0
        xLimits = [reg(1) reg(2)];
        yLimits = [reg(3) reg(4)];
    else
        xLimits = [defaultReg(1) defaultReg(2)];
        yLimits = [defaultReg(3) defaultReg(4)];
    end
    %% Icon setup
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
    movePolesIcon = imread('./images/move_poles_icon.png');

    %% GUI Setup
    hFig = uifigure(Position=figPosition, Name='Time delay Root Locus', ...
       Color=figColor);
    hFig.WindowButtonDownFcn = @mousePushed;
    hFig.WindowButtonUpFcn = @mouseReleased;

    myLayout = uigridlayout(hFig, RowHeight={'4x', '16x', '1x', '1x'}, ...
        ColumnWidth={'2x', '4x', '3x', '12x', '1x'}, BackgroundColor=figColor);

    % --- Toolbar setup ---
    hToolbar = uitoolbar(hFig, BackgroundColor=[1 1 1]);

    hTBSelectTDTF = uipushtool(hToolbar, CData=loadIconTDTF, ...
        Tooltip='Edit time delay transfer function', ...
        ClickedCallback=@openTDTFPopupCallback);
    hMovePoles = uitoggletool(hToolbar, CData=movePolesIcon, ...
        Tooltip='Change pole gain', OnCallback=@moveOn, OffCallback=@moveOff);
    
    % Zoom in/out + pan buttons
    hPanBtn = uitoggletool(hToolbar, CData=panIcon, Separator='on', OnCallback=@panOn, OffCallback=@panOff);
    hZoomInBtn = uitoggletool(hToolbar, CData=zoomInIcon, OnCallback=@zoomInOn, OffCallback=@zoomInOff);
    hZoomOutBtn = uitoggletool(hToolbar, CData=zoomOutIcon, OnCallback=@zoomOutOn, OffCallback=@zoomOutOff);

    % Plot axes
    hAx = uiaxes(myLayout, Color=axesColor, Box="on", XGrid="on", YGrid="on", ...
        XLim=xLimits, YLim=yLimits);
    hAx.Layout.Column = [1 5];
    hAx.Layout.Row = [1 2];
    hAx.XLabel.String = 'Real part';
    hAx.YLabel.String = 'Imaginary part';
    hAx.Toolbar.Visible = 'off';
    hold(hAx, 'on');

    % Axis for real = 0 and imag = 0
    hXAxis = plot(hAx, xLimits, [0 0], ':k', 'LineWidth', 1, Tag='axes');
    hYAxis = plot(hAx, [0 0], yLimits, ':k', 'LineWidth', 1, Tag='axes');

    % Gain slider
    gainSlider = uislider(myLayout, Value=1);
    gainSlider.Limits = [minSliderLim, log10(maxSliderLim)];
    gainSlider.MajorTicks = linspace(minSliderLim, log10(maxSliderLim), 10);
    gainSlider.Layout.Column = [3 4];
    gainSlider.Layout.Row = [3 4];

    gainSlider.ValueChangingFcn = @sliderMovement;
    gainSlider.ValueChangedFcn = @sliderMoved;

    % Gain edit field
    gainEdit = uieditfield(myLayout, 'numeric',...
        Limits=[minSliderLim, maxSliderLim],...
        ValueChangedFcn=@editGain, Value=1, HorizontalAlignment='center');
    gainEdit.Layout.Column = 2;
    gainEdit.Layout.Row = 4;

    %% Callbacks

    % Add listeners to update the axis lines when limits change
    addlistener(hAx, 'XLim', 'PostSet', @(~, ~) updateAxes);
    addlistener(hAx, 'YLim', 'PostSet', @(~, ~) updateAxes);

    %% _____Code starts here_____

    % Stack initialization
    undoStack = UndoStack(10);
    helpStack = UndoStack(1);

    if nargin > 0
        setCurrentSystem(varargin{:});
        drawRL;
    end
    
    function setCurrentSystem(varargin)
    % Saves all important info about current system

        % Check for Matrix or string notation
        if isnumeric(varargin{1})
            numP = varargin{1};
            numD = varargin{2};
            denP = varargin{3};
            denD = varargin{4};
        else
            [numP, numD] = string2matrix(varargin{1});
            [denP, denD] = string2matrix(varargin{2});
        end
        
        % Create matrix for denominator + K*numerator
        [numP, denP, D] = create_rl_marix(numP, numD, denP, denD);
        P = denP+gainEdit.Value*numP;
        
        % Compute all poles/zeros of closed/open system
        olZeros = compute_roots(reg, numP, D, ds);
        olPoles = compute_roots(reg, denP, D, ds);
        clPoles = compute_roots(reg, P, D, ds);
        getAdditionalInfo
    end

    function getAdditionalInfo
    % Saves all other not that important info about system

        % Get partial derivatives of "s"
        numdP = derivate_quasipolynomial(numP, D);
        dendP = derivate_quasipolynomial(denP, D);
    end

    function drawRL
    % Draw and saves graphical data

        % Draw root locus
        lines = draw_rl_lines(reg, 1e10, olZeros, olPoles, numP, denP, D,...
            numdP, dendP, ds, minsStep, maxsStep);
        numLines = length(lines);
        rlocusLines = cell(2*numLines, 1);
        for i = 1:numLines
            rlocusLines{2*i-1} = plot(hAx, real(lines{i}), imag(lines{i}), Color=RLLineCol, Tag='rlocus', LineWidth=1.5);
            rlocusLines{2*i} = plot(hAx, real(lines{i}), -imag(lines{i}), Color=RLLineCol, Tag='rlocus', LineWidth=1.5);
            reg(1) = min([reg(1), min(real(lines{i}))]);
            reg(2) = max([reg(2), max(real(lines{i}))]);
            reg(4) = max([reg(4), max(imag(lines{i}))]);
        end
        drawPolesZeros
    end


function updateCLPoles
% Draw all the poles of closed loop system corresponding to given gain

    plotCLPoles.XData = [real(clPoles), real(clPoles)];
    plotCLPoles.YData = [imag(clPoles), -imag(clPoles)];
end

function drawPolesZeros
    % Draw poles and zeros
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
function saveToStack
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
    stackGain = gainEdit.Value;
    % stackParNum = paramNum;
    % stackParDen = paramDen;
    
    % saves to undo stack from temporary stack
    if helpStack.getSize() > 0
        [stackRLtmp, stackOLPoletmp, stackOLZerotmp, stackCLPoletmp, ...
            stackTFTexttmp, stackNumtmp, stackDentmp, stackGaintmp, ...
            stackParNumtmp, stackParDentmp, stackParTexttmp] = helpStack.pop();
        undoStack.push(stackRLtmp, stackOLPoletmp, stackOLZerotmp, ...
            stackCLPoletmp, stackTFTexttmp, stackNumtmp, stackDentmp, ...
            stackGaintmp, stackParNumtmp, stackParDentmp, stackParTexttmp);
    end
    helpStack.push(stackRL, stackOLPole, stackOLZero, stackCLPole, ...
        stackTFText, stackNum, stackDen, stackGain, stackParNum, ...
        stackParDen, stackParText);
end

function redraw(varargin)
    clearCanvas
    newNum = varargin{1};
    newDen = varargin{2};
    setCurrentSystem(newNum, newDen);
    drawRL;
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

% Clears data
function setEmptyData
    rlocusLines = [];
    plotPoles = [];
    plotZeros = [];
    plotCLPoles = [];
end

%% Callback functions

% Axis callback function
function updateAxes
% Update the x and y axis line
    set(hXAxis, XData=hAx.XLim, YData=[0 0]);
    set(hYAxis, XData=[0 0], YData=hAx.YLim);
end

function openTDTFPopupCallback(~, ~)
    pixelWidth = 7;
    strnum = matrix2string(numP, D);
    strden = matrix2string(denP, D);
    fieldWidth = max([length(strnum), length(strden)]);
    hTDTFPopupFig = uifigure(Name='Edit Time delay transfer function', Position=[500, 300, fieldWidth*2*pixelWidth+50, 150]);
    hTDTFLabel = uilabel(hTDTFPopupFig, Text='Choose time delay transfer function', Position=[round(fieldWidth*pixelWidth/4) 125 250 22]);
    hNumEditField = uieditfield(hTDTFPopupFig, Position=[round(fieldWidth*pixelWidth/4) 90 fieldWidth*pixelWidth 22]);
    hFraction = uilabel(hTDTFPopupFig, Text=repmat('_', 1, fieldWidth), Position=[round(fieldWidth*pixelWidth/4) 75 150 22]);
    hDenEditField = uieditfield(hTDTFPopupFig, Position=[round(fieldWidth*pixelWidth/4) 45 fieldWidth*pixelWidth 22]);
    hEditButton = uibutton(hTDTFPopupFig, Text='Edit', Position=[round(fieldWidth*pixelWidth) 12 50 22], ButtonPushedFcn=@generateNewTDRL);
    hLoadNumButton = uibutton(hTDTFPopupFig, Text='Load Numerator', Position=[round(fieldWidth*pixelWidth*4/3) 90 120 22], ButtonPushedFcn=@(~,~)loadPD(true));
    hLoadDenButton = uibutton(hTDTFPopupFig, Text='Load Denominator', Position=[round(fieldWidth*pixelWidth*4/3) 45 120 22], ButtonPushedFcn=@(~,~)loadPD(false));

    hNumEditField.Value = strnum;
    hDenEditField.Value = strden;

    function generateNewTDRL(~, ~)
        redraw(hNumEditField.Value, hDenEditField.Value);
        close(hTDTFPopupFig);
    end

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
        end
    end
end

% Gain slider callback (update after slider movement stopped)
function sliderMovement(~, event)
    val = event.Value^10;
    dK = val - gainEdit.Value;
    
    %clPoles = compute_roots(reg, denP+event.Value*numP, D, ds);
    newPoles = iterate_root(clPoles, numP, denP, D, dendP, numdP, ds, gainEdit.Value, dK);
    if max(abs(newPoles - clPoles)) > maxsStep
        clPoles = compute_roots(reg, denP+val*numP, D, ds);
    else
        clPoles = newPoles;
    end
    %clPoles = [poles, conj(poles)];
    gainEdit.Value = val;
    updateCLPoles;
end

% Gain slider callback (update after slider movement stopped)
function sliderMoved(~, event)
    val = event.Value^10;
    P = denP+val*numP;
    clPoles = compute_roots(reg, P, D, ds);
    gainEdit.Value = val;
    updateCLPoles;
end

% Edit gain callback
function editGain(src, ~)
    %dK = src.Value - gainEdit.Value;
    clPoles = compute_roots(reg, denP+src.Value*numP, D, ds);
    %clPoles = [poles, conj(poles)];
    gainSlider.Value = log10(src.Value);
    updateCLPoles;
end

% Enable changing gain by dragging
function moveOn(~, ~)
    set(hFig, "Pointer", "custom", "PointerShapeCData", moveCursorMat, "PointerShapeHotSpot", [10, 9]);
    movePoles= true;
end

% Disable changing poles by dragging
function moveOff(~, ~)
    set(hFig, "Pointer", "arrow");
    movePoles = false;
end

function mousePushed(~, ~)
    movingPolesNow = true;
    if movePoles
        set(hFig, 'WindowButtonMotionFcn', @holdAndChangeGain);
    end
end

function mouseReleased(~, ~)
    movingPolesNow = false;
    if movePoles
        set(hFig, "Pointer", "custom", "PointerShapeCData", moveCursorMat, "PointerShapeHotSpot", [10, 9]);
    end
    set(hFig, 'WindowButtonMotionFcn', []);
end

function holdAndChangeGain(~, ~)
    cp = get(hAx, 'CurrentPoint');
    set(hFig, "Pointer", "custom", "PointerShapeCData", holdCursorMat, "PointerShapeHotSpot", [10, 9]);
    x = cp(1,1);
    y = cp(1,2);
    activeXReg = diff(hAx.XLim)/10;
    activeYReg = diff(hAx.YLim)/10;
    dists = sqrt(((plotCLPoles.XData - x) / activeXReg).^2 + ((plotCLPoles.YData - y) / activeYReg).^2);

    [minVal, minIdx] = min(dists);
    if minVal < (activeXReg + activeYReg) && movingPolesNow
        if minIdx > length(clPoles) % conjurates
            minIdx = minIdx - length(clPoles);
            y = -y;
        end
        s0 = clPoles(minIdx);
        K0 = gainEdit.Value;
        sVec = (x + y*1i) - s0;
        rProj = pole_projection(s0, K0, numP, denP, numdP, dendP, D, sVec);

        dK = get_dk(s0, K0, numP, numdP, dendP, D, rProj);
        K = K0 + dK;
        K = min([abs(K), maxSliderLim]);
        currP = denP + K*numP;
        clPoles = compute_roots(reg, currP, D, ds);
        %clPoles = iterate_root(clPoles, numP, denP, D, dendP, numdP, K0, dK, 0.01, 0.1);
        gainEdit.Value = K;
        updateCLPoles
        pause(0.1)
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

% ------------------------- Pan/Zoom-----------------------------
% Pan on callback
function panOn(src, ~)
    toggleOffOthers(src, hZoomInBtn, hZoomOutBtn);
    pan(hAx.Parent, 'on');
end

% Pan off callback
function panOff(~, ~)
    pan(hAx.Parent, 'off');
end

% Zoom in enabled callback
function zoomInOn(src, ~)
    toggleOffOthers(src, hPanBtn, hZoomOutBtn);
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
    toggleOffOthers(src, hZoomInBtn, hPanBtn);
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

function cursMat = moveCursorMat
    cursMat = [ones(1,16)*NaN;
        ones(1,6)*NaN, ones(1, 5), ones(1, 5)*NaN;
        ones(1,5)*NaN, 1, 2, 1, 2, 1, 2, 1, ones(1, 4)*NaN;
        ones(1,5)*NaN, 1, 2, 1, 2, 1, 2, 1, 1, ones(1, 3)*NaN; %4
        ones(1,5)*NaN, 1, 2, 1, 2, 1, 2, 1, 2, 1, ones(1, 2)*NaN;
        ones(1,5)*NaN, 1, 2, 1, 2, 1, 2, 1, 2, 1, ones(1, 2)*NaN;
        ones(1,5)*NaN, 1, 2, 1, 2, 1, 2, 1, 2, 1, ones(1, 2)*NaN;
        ones(1,3)*NaN, 1, NaN, 1, 2*ones(1,7), 1, ones(1, 2)*NaN; %8
        ones(1,2)*NaN, 1, 2, 1, 1, 2*ones(1,7), 1, ones(1, 2)*NaN;
        ones(1,2)*NaN, 1, 2, 2, 1, 2*ones(1,7), 1, ones(1, 2)*NaN;
        ones(1,3)*NaN, 1, 2*ones(1,9), 1, ones(1, 2)*NaN;
        ones(1,3)*NaN, 1, 1, 2*ones(1,8), 1, ones(1, 2)*NaN;%12
        ones(1,4)*NaN, 1, 2*ones(1,7), 1, 1, ones(1, 2)*NaN;
        ones(1,4)*NaN, 1, 1, 2*ones(1,6), 1, ones(1, 3)*NaN;
        ones(1,5)*NaN, ones(1,7), ones(1, 4)*NaN;
        ones(1, 16)*NaN;];
end

function cursMat = holdCursorMat
    cursMat = [ones(1,16)*NaN;
        ones(1,16)*NaN;
        ones(1,16)*NaN;
        ones(1,16)*NaN; %4
        ones(1,7)*NaN, ones(1,3), ones(1, 6)*NaN;
        ones(1,5)*NaN, 1, 1, 1, 2, 1, 1, 1, ones(1, 4)*NaN;
        ones(1,5)*NaN, 1, 2, 1, 2, 1, 2, 1, 1, ones(1, 3)*NaN;
        ones(1,5)*NaN, 1, 2, 1, 2, 1, 2, 1, 2, 1, ones(1, 2)*NaN; %8
        ones(1,4)*NaN, 1, 1, 2*ones(1,7), 1, ones(1, 2)*NaN;
        ones(1,4)*NaN, 1,  2*ones(1,8), 1, ones(1, 2)*NaN;
        ones(1,3)*NaN, 1, 1, 2*ones(1,8), 1, ones(1, 2)*NaN; 
        ones(1,3)*NaN, 1, 2*ones(1,9), 1, ones(1, 2)*NaN;%12
        ones(1,4)*NaN, 1, 2*ones(1,7), 1, ones(1, 3)*NaN;
        ones(1,5)*NaN, 1, 2*ones(1,6), 1, ones(1, 3)*NaN;
        ones(1,5)*NaN, ones(1,7), ones(1, 4)*NaN;
        ones(1, 16)*NaN;];
    end
end