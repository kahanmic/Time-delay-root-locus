function tdrlocus(Reg, varargin)
% Time delay root locus
%
% tdrlocus()
%   
%   Opens Time delay root locus GUI without initial root locus
%
% tdrlocus(Reg, Num, Den)
%
%   Opens GUI with time delay root locus of transfer function with
%   numerator 'Num' and denominator 'Den' within specified region 'Reg'
%
%   Reg - region on complex plane where root locus is being plotted
%         Reg = [real_min real_max imag_min imag_max]
%         Reg = 0 to select pre-defined region [-10 5 -100 100]
%   Num - numerator of the transfer function written as string
%         For example: Num = "1+exp(-s-4)"
%   Den - denominator of the transfer function written as string
%         For example: Den = "2.*s+exp(-s)"
%
%   Numerator and denominator can be written with parameters as 
%   capital letters, adjustable through GUI
%   For example: Den = "K.*s+exp(-L.*s+M)"
%
% Created by Michael Kahanek, CTU in Prague
% Using QPmR algorithm created by Tomas Vyhlidal, CTU in Prague
% http://www.cak.fs.cvut.cz/algorithms/qpmr

    %% GUI variables
    
    %fileID = fopen("testtxt.txt", "w");    % Bug fixing

    % Create user adjusted window
    screenSize = get(groot, 'ScreenSize');  % Get user's screen size
    figSize = [round(screenSize(3)*0.7), round(screenSize(4)*0.7)];
    figColor = [0.9 0.9 0.9];
    axesColor = [1 1 1];

    if nargin > 0
        if length(Reg) > 1
            xLimits = [Reg(1) Reg(2)];
            yLimits = [Reg(3) Reg(4)];
        else
            xLimits = [-5 5];
            yLimits = [-5 5];
        end
    else
        xLimits = [-5 5];
        yLimits = [-5 5];
    end
    figPosition = [(screenSize(3:4) - figSize)/2, figSize];
    
    % Hex colors of
    OLPoleCol = "#FDA6A6"; % Open loop poles
    OLZeroCol = "#8299F6"; % Open loop zeros
    RLLineCol = "#1fdda5"; % Root locus lines
    defaultReg = [-10 5 -50 50];  % Default region of time delay root locus if not specified

    %% Variables
    
    % Setup default region if nor specified or function is called w/o
    % arguments
    if nargin == 0
        Reg = defaultReg;
    end
    
    % numerator and denominator of tf (delay and non-delay)
    paramNum = '';
    paramDen = '';
    denominator = '1';    
    numerator = '1';
    
    % Plot data
    rlocusLines = {};  % Data of plotted root locus lines
    plotPoles = [];
    plotZeros = [];
    plotCLPoles = [];
    
    % Transfer function text
    tfText = '';
    paramTfText = '';

    % Variables for time-delay tf with parameters and their values
    TDTFparameters = {};
    paramValues = [];   % scalar values
    paramEdits = {}; % uieditfields
    paramSliders = {}; % uisliders

    samples = 400;  % Precision of root locus lines

    % Gain limits (logarithmic)
    minLogLim = -5;
    maxLogLim = 10;
    %minLinLim = 10e-4;
    %maxLinLim = 10e4;
    
    % Limits of gain on slider
    minSliderLim = 0;
    maxSliderLim = 100;
    
    % Modes for adding poles and zeros by clicking
    selectionModes = {'RealPole', 'ImagPole', 'RealZero', 'ImagZero'};
    selectedMode = selectionModes{1};
    s = tf('s');

    %% Icon setup

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

    %% GUI setup

    % --- Figure setup ---
    hFig = uifigure(Position=figPosition, Name='Time delay Root Locus', ...
       Color=figColor);
    myLayout = uigridlayout(hFig, RowHeight={'4x', '16x', '1x', '1x'}, ...
        ColumnWidth={'2x', '4x', '3x', '12x', '1x'}, BackgroundColor=figColor);

    % --- Toolbar setup ---
    hToolbar = uitoolbar(hFig, BackgroundColor=[1 1 1]);
    
    % Toolbar button (edit time delay transfer function)
    hTBSelectTDTF = uipushtool(hToolbar, CData=loadIconTDTF, ...
        Tooltip='Edit time delay transfer function', ...
        ClickedCallback=@openTDTFPopupCallback);
    hVarParam = uipushtool(hToolbar, CData=varParamIcon, ...
        Tooltip='Change parameters for time delay transfer function', ...
        ClickedCallback=@openSliderWindow);
    hRegSelect = uipushtool(hToolbar, CData=regIcon, Tooltip='Select plot region', ...
        ClickedCallback=@openRegPopupCallback);
    hRegAuto = uipushtool(hToolbar, CData=regAutoIcon, Tooltip='Auto-adjust plot region');
    
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
    for empty = 1:round((figSize(1)- 11*28 - 3*5)/28)
        uipushtool(hToolbar, CData=spacerIcon, Enable='off', Separator='off');
    end
    
    % Toolbar undo button
    hUndo = uipushtool(hToolbar, CData=undoIcon, TooltipString='Undo', ...
        ClickedCallback=@doUndo);

    % --- Axes setup ---
    hAx = uiaxes(myLayout, Color=axesColor);
    hAx.Layout.Column = [1 5];
    hAx.Layout.Row = [1 2];
    hAx.Box = 'on';
    hAx.XLim = xLimits;
    hAx.YLim = yLimits;
    hAx.XGrid = 'on';
    hAx.YGrid = 'on';
    hAx.XLabel.String = 'Real part';
    hAx.YLabel.String = 'Imaginary part';
    hAx.Toolbar.Visible = 'off';
    hold(hAx, 'on');
    
    % Gain slider
    gainSlider = uislider(myLayout, Value=1);
    gainSlider.Limits = [minSliderLim, maxSliderLim];
    gainSlider.Layout.Column = [3 4];
    gainSlider.Layout.Row = [3 4];

    % Gain limit edit
    hGainUp = uibutton(myLayout, Icon='./images/arrow_up.png', Text='', ...
        ButtonPushedFcn=@buttonUp, Tooltip='Higher gain limit');
    hGainUp.Layout.Column = 5;
    hGainUp.Layout.Row = 3;
    hGainDown = uibutton(myLayout, Icon='./images/arrow_down.png', Text='', ...
        ButtonPushedFcn=@buttonDown, Tooltip='Lower gain limit');
    hGainDown.Layout.Column = 5;
    hGainDown.Layout.Row = 4;

    % Gain text
    gainLabel = uilabel(myLayout, Text='Gain', HorizontalAlignment='center');
    gainLabel.Layout.Column = 2;
    gainLabel.Layout.Row = 3;

    % Gain edit field
    gainEdit = uieditfield(myLayout, 'numeric',...
        Limits=[minSliderLim, power(10, maxSliderLim)],...
        ValueChangedFcn=@editGain, Value=1, HorizontalAlignment='center');
    gainEdit.Layout.Column = 2;
    gainEdit.Layout.Row = 4;
    
    hDiscreteRL = uibutton(myLayout, 'state', Value=1, Text='Discrete RL', ValueChangedFcn=@toggleRLMode);
    hDiscreteRL.Layout.Column = 1;
    hDiscreteRL.Layout.Row = 4;
  

    % Transfer text
    tfAx = uiaxes(myLayout, Visible='off');
    %tfAx.Layout.Column = 1;
    %tfAx.Layout.Row = 1;
    cla(tfAx);
    axis(tfAx, 'off');
    tfAx.Toolbar.Visible = 'off';

    hTFText = text(hAx, 0.1, 0.5, '', FontSize=20, Interpreter='latex', ...
                Tag='tftext', Visible='off');
    
    hStableText = text(hAx, 0, 0, '');
    xL = hAx.XLim(2);
    yL = hAx.YLim(1);
    hRunningText = text(hAx, 0.99*xL, 0.99*yL , '', FontSize=16, ...
                HorizontalAlignment='right', VerticalAlignment='bottom', Color=[1 0 0]);
    
    % Axis
    hXAxis = plot(hAx, xLimits, [0 0], ':k', 'LineWidth', 1, Tag='axes');
    hYAxis = plot(hAx, [0 0], yLimits, ':k', 'LineWidth', 1, Tag='axes');
    
    %% Code

    % Stack initialization
    undoStack = UndoStack(10);
    helpStack = UndoStack(1);

    % Plotting initialization
    if nargin > 0
        drawRL(varargin{:});
    end

    %% Callbacks

    % Add listeners to update the axis lines when limits change
    addlistener(hAx, 'XLim', 'PostSet', @(src, evt) updateAxes(hAx, hXAxis, hYAxis));
    addlistener(hAx, 'YLim', 'PostSet', @(src, evt) updateAxes(hAx, hXAxis, hYAxis));
    gainSlider.ValueChangingFcn = @sliderMovement;
    gainSlider.ValueChangedFcn = @sliderMoved;
    hAx.ButtonDownFcn = @mouseClickCallback;
    hRegAuto.ClickedCallback = @(src, event)redrawRegion(src, true);
    hPoleSelect.OnCallback = @(src, event)toggleModeSelect(src, hPolesSelect, ...
        hZeroSelect, hZerosSelect, hPanBtn, hZoomInBtn, hZoomOutBtn);
    hPolesSelect.OnCallback = @(src, event)toggleModeSelect(src, hPoleSelect, ...
        hZeroSelect, hZerosSelect, hPanBtn, hZoomInBtn, hZoomOutBtn);
    hZeroSelect.OnCallback = @(src, event)toggleModeSelect(src, hPoleSelect, ...
        hPolesSelect, hZerosSelect, hPanBtn, hZoomInBtn, hZoomOutBtn);
    hZerosSelect.OnCallback = @(src, event)toggleModeSelect(src, hPoleSelect, ...
        hPolesSelect, hZeroSelect, hPanBtn, hZoomInBtn, hZoomOutBtn);

    %% Functions

% Draw rootlocus of transfer function
    function drawRL(varargin)
        
        % varargin{1} – numerator, varargin{2} – denominator
        tmpNum = char(varargin{1});
        tmpDen = char(varargin{2});

        % Check if parametrically written
        [isPar, numPar] = hasParam(tmpNum, tmpDen);
        
        if isPar
            % Written text saved
            paramNum = tmpNum;
            paramDen = tmpDen;
            % New parameter values to be set
            if length(paramValues) ~= numPar
                paramValues = ones(1, numPar);
            end
            setNewParameterEq;
            updateParameters;   % sets new numerator and denominator
        else
            numerator = tmpNum;
            denominator = tmpDen;
        end
        
        % Plot OL poles if denominator contains 's'
        if contains(denominator, 's')
            FunPoles = str2num(strcat('@(s)(', denominator, ')'));
            delOLPoles = QPmR(Reg, FunPoles, varargin{3:end});
            plotPoles = plot(hAx, real(delOLPoles), imag(delOLPoles), 'x', ...
                MarkerFaceColor=OLPoleCol, MarkerEdgeColor=OLPoleCol, ...
                MarkerSize=10, LineWidth=1.5, Tag='olpole');
        else
            plotPoles = [];
        end
        
        % Plot OL zeros if numerator contains 's'
        if contains(numerator, 's')
            FunZeros = str2num(strcat('@(s)(', numerator, ')'));
            delOLZeros = QPmR(Reg, FunZeros, varargin{3:end});
            plotZeros = plot(hAx, real(delOLZeros), imag(delOLZeros), 'o', ...
                MarkerEdgeColor=OLZeroCol, MarkerSize=10, LineWidth=1.5, ...
                Tag='olzero');
        else 
            plotZeros = [];
        end
        
        % Plot root locus
        
        if contains(numerator, 's') || contains(denominator, 's')
            % Calculate poles for different gains
            delPoles = []; % M x N matrix of M poles (rows) and N gains (columns)
            %delGain = linspace(minLinLim, maxLinLim, samples);
            delGain = logspace(minLogLim, maxLogLim, samples);
            discreteRL = hDiscreteRL.Value;
            
            for K = delGain
                funStr = strcat('@(s)(', denominator, '+', num2str(K),'.*','(' ,numerator, ')', ')');
                Fun = str2num(funStr);
                if width(delPoles) > 0
                    if discreteRL
                        delPoles = [delPoles; QPmR(Reg, Fun, varargin{3:end})];
                    else
                        delPoles = enlargePoleMatrix(delPoles, QPmR(Reg, Fun, varargin{3:end}));
                    end
                else
                    delPoles = QPmR(Reg, Fun, varargin{3:end});
                end
            end
            
            % Plot root locus, each row corresponds to line in root
            % locus
            if discreteRL
                rlocusLines = {plot(hAx, real(delPoles), imag(delPoles), ...
                    LineStyle='none', Marker='.', MarkerFaceColor=RLLineCol, MarkerEdgeColor=RLLineCol)};
            else
                rlocusLines = cell([1 height(delPoles)]);
                for i = 1:height(delPoles)
                    currRow = delPoles(i,:);
                    currPoles = currRow(currRow ~= 0); % deletes invalid data
                    rlocusLines{i} = plot(hAx, real(currPoles), imag(currPoles), Color=RLLineCol, Tag='rlocus', LineWidth=1.5);
                end
            end
        
            
            % Initiate CL poles for gain = 1; init for gain = gainEdit.Value
            cpoleFun = str2num(strcat('@(s)(', denominator, '+', ...
                num2str(gainEdit.Value),'.*', '(', numerator, ')', ')'));
            TDCLpoles = QPmR(Reg, cpoleFun, varargin{3:end});
            plotCLPoles = plot(hAx, real(TDCLpoles), imag(TDCLpoles), ...
                'x' ,Tag='clpole', MarkerSize=10, LineWidth=1.5, ...
                MarkerFaceColor='red', MarkerEdgeColor='red');

            stabilityTest(cpoleFun); % Tests if closed loop is stable
        else
            rlocusLines = [];
            plotCLPoles = [];
        end
            
        % Transfer function text
        tfText = sprintf('Transfer function \\ $$\\frac{%s}{%s}$$', ...
            numerator, denominator);
        hTFText.String = tfText;
        if isPar
            paramTfText = sprintf('Transfer function \\ $$\\frac{%s}{%s}$$', ...
            paramNum, paramDen);
        else
            paramTfText = '';
        end

        axis(hAx, [Reg(1) Reg(2) Reg(3) Reg(4)]);   % adjust plot
        % Saves for undo
        if ~isempty(plotPoles)  
            saveToStack();
        end
    end
    
% Move CL poles by changing gain
% newGain: int -> new gain value
% addToStack: bool -> if saving to stack wanted
    function updateCLPoles(newGain, addToStack)
        Fun = [];
        funUpdate = strcat('@(s)(', denominator, '+', num2str(newGain),'.*','(', numerator,')', ')');
        Fun = str2num(funUpdate);
        currPoles = QPmR(Reg, Fun, varargin{3:end}); 
        
        plotCLPoles.XData = real(currPoles);
        plotCLPoles.YData = imag(currPoles);
        
        % Saves canvas to undo stack
        if addToStack && ~isempty(rlocusLines)
            saveToStack();
            % check stability
            stabilityTest(Fun);
        end % if
    end % function
    
% Update pole order for right rootlocus
    function reassembledVec2 = reassembleVectors(vec1, vec2)
        % Ensure the input vectors are column vectors
        vec1 = vec1(:);
        vec2 = vec2(:);
        reassembledVec2 = zeros(size(vec1));
        usedIdx = [];

        % compare previous and current roots
        for i = 1:length(vec1)
            idxFound = false;
            cntr = 1;
            [~, newIdx] = sort(abs(vec1(i) - vec2));
            
            % Preventing duplicating roots while reassambling
            while ~idxFound  
                if ismember(newIdx(cntr), usedIdx)
                    cntr = cntr + 1;
                else
                    reassembledVec2(i) = vec2(newIdx(cntr));
                    usedIdx(end+1) = newIdx(cntr);
                    idxFound = true;
                end        
            end      
        end 
    end
    
% Adds poles for new gain to rootlocus
% newVector: vector of N CL poles for new gain of N row and 1 column
    function newMat = enlargePoleMatrix(oldMat, newVector)
        % Reorder vector so that negative complex conjurates are first
        matV = formatVector(oldMat(:,end));
        newV = formatVector(newVector);
        hv1 = height(matV);
        hv2 = height(newV);
        largerMat = true;
        
        if hv1 ~= hv2   % Different computation appearing/disappearing lines
            tmpMat = [];
            tmpVec = [];

            if hv1 > hv2
                lv = matV;
                sv = newV;
                largerMat = true;
            else
                lv = newV;
                sv = matV;
                largerMat = false;
            end
            hlv = height(lv);
            hsv = height(sv);
            
            if length(lv(lv ~= 0)) == hsv   % works only for disappearing poles
                idxs = find(lv); % indexes of non zero values
                lv2 = lv(lv ~= 0);
                sv = reassembleVectors(lv2, sv);
                tmp = zeros(hlv, 1);
                tmp(idxs) = sv;
                tmpMat = oldMat;
                tmpVec = tmp;

            else
                vdiff = hlv - hsv;
                bestShiftInd = 0;
                bestShiftDiff = inf;
    
                for i = 0:vdiff   % shift down
                    currShiftDiff = sum(abs(sv - lv(1+i:hsv+i)));
                    if currShiftDiff < bestShiftDiff
                        bestShiftInd = i;
                        bestShiftDiff = currShiftDiff;
                    end
                end
                    
                % zeros to be added to the top or the bottom of the vector
                if largerMat    % Vector enlarged
                    for i1 = 1:bestShiftInd
                        tmpVec = [tmpVec;0];
                    end
                    for i1 = 1:length(sv)
                        tmpVec = [tmpVec; sv(i1)];
                    end
                    for i1 = 1:(hlv - (hsv + bestShiftInd))
                        tmpVec = [tmpVec; 0];
                    end
                    tmpMat = oldMat;
                else    % Matrix enlarged
                    for i1 = 1:bestShiftInd
                        tmpMat = [tmpMat; zeros(1, width(oldMat))];
                    end
                    for i1 = 1:length(sv)
                        tmpMat = [tmpMat; oldMat(i1, :)];
                    end
                    for i1 = 1:(hlv - (hsv + bestShiftInd))
                        tmpMat = [tmpMat; zeros(1, width(oldMat))];
                    end
                end     
            end
        else    % New vector and old matrix of same poles
            tmpMat = oldMat;
            tmpVec = reassembleVectors(oldMat(:, end), newVector);
        end
        newMat = [tmpMat, tmpVec];
    end
    
% Format vector so that negative complex conjurates are before positive
    function formatedVec = formatVector(vec)
        if ~isempty(vec)    % Error handling
            formatedVec = zeros(size(vec));
            formatedVec(1) = vec(1);
            for i = 2:length(vec)
                delta = 1e-3;
                closeReal = isClose(real(vec(i)), real(vec(i-1)), delta);
                closeImag = isClose(imag(vec(i)), -imag(vec(i-1)), delta);
                if closeReal && closeImag
                    if imag(vec(i)) < 0
                        formatedVec(i-1) = vec(i);
                        formatedVec(i) = vec(i-1);
                    else
                        formatedVec(i) = vec(i);
                    end
                else
                    formatedVec(i) = vec(i);
                end
            end
        else
            formatedVec = vec;
        end
    end
    
% Comparison of similar numbers
    function trueFalse = isClose(n1, n2, dlt)
        trueFalse = abs(n1- n2) < dlt;
    end

% Adds poles for new gain to rootlocus
% newVector: vector of n CL poles for new gain of n row and 1 column
    function newMat = enlargePoleMat(oldMat, newVector)
        hMat = height(oldMat);
        hVec = height(newVector);
        if hMat ~= hVec
            if hVec < hMat
                newVector = [newVector; zeros(hMat - hVec, 1)];
            else
                oldMat = [oldMat; zeros(hVec - hMat, width(oldMat))];
            end    
        end
        newVector = reassembleVectors(oldMat(:, end), newVector);
        newMat = [oldMat, newVector];
    end

% Adds state of root locus to the stack
    function saveToStack()
        stackRL = cell([2 length(rlocusLines)]);
        for idx = 1:length(rlocusLines)
            stackRL{1, idx} = rlocusLines{idx}.XData;
            stackRL{2, idx} = rlocusLines{idx}.YData;
        end
        stackOLPole = {plotPoles.XData, plotPoles.YData};
        if ~isempty(plotZeros)
            stackOLZero = {plotZeros.XData, plotZeros.YData};
        else
            stackOLZero = {};
        end
        stackCLPole = {plotCLPoles.XData, plotCLPoles.YData};
        stackTFText = tfText;
        stackNum = numerator;
        stackDen = denominator;
        stackGain = gainEdit.Value;
        stackParNum = paramNum;
        stackParDen = paramDen;
        stackParText = paramTfText;
        
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
    
% Clears complex plane
    function clearCanvas()
        % Delete each line and sets it to empty 
        for data = rlocusLines
            delete(data{1});
        end
        delete(plotPoles);
        delete(plotZeros);
        delete(plotCLPoles);
        tfText = '';
        %hTFText.String = '';
        setEmptyData();
    end
    
% Clears data
    function setEmptyData()
        rlocusLines = [];
        plotPoles = [];
        plotZeros = [];
        plotCLPoles = [];
    end
    
% Redraw root locus
    function redraw(varargin)
        updateRunningText('Running');
        pause(0.1)
        clearCanvas();
        newNum = varargin{1};
        newDen = varargin{2};
        drawRL(newNum, newDen);
        updateRunningText('');
    end

% Convert roots to polynomial string
    function poly_str = rootsToPoly(myRoots)
        coefs = poly(myRoots);
        poly_str = '';
        n = length(coefs) - 1;
        for i = 1:length(coefs)
            coef = coefs(i);
            if coef ~= 0
          
                if coef > 0 && i > 1
                    poly_str = strcat(poly_str, '+');
                elseif coef < 0
                    poly_str = strcat(poly_str, '-');
                end
        
                abs_coef = abs(coef);
        
                if abs_coef ~= 1 || i == length(coefs)
                    poly_str = strcat(poly_str, num2str(abs_coef));
                end
        
                if n > 1
                    if i > 1
                       poly_str = strcat(poly_str, '.*'); 
                    end
                    poly_str = strcat(poly_str, 's.^', num2str(n));
                elseif n == 1
                    poly_str = strcat(poly_str, '.*s');
                end
            end
            n = n-1;
        end 
    end
    
% Add save parameters
    function setNewParameterEq
        TDTFparameters = cell(0);
        if (length(paramDen) + length(paramNum)) > 0 
            % indexes of capital letters
            numIdxs = [];
            denIdxs = [];
            numUpper = isstrprop(paramNum, 'upper');
            denUpper = isstrprop(paramDen, 'upper');
            % Adds indexes of capital letters
            numIdxs(end+1:end+sum(numUpper)) = find(numUpper); 
            denIdxs(end+1:end+sum(denUpper)) = find(denUpper);
            
            % Gets char of parameters ('ABC')
            charNum = char(paramNum(numIdxs));
            charDen = char(paramDen(denIdxs));
             
            TDTFparameters(end+1:end+length(charNum)) = num2cell(charNum(:));
            TDTFparameters(end+1:end+length(charDen)) = num2cell(charDen(:));
        end
    end
    
% Update parametric to numbers
    function updateParameters
        tmpNum = paramNum;
        tmpDen = paramDen;
        
        for i = 1:length(TDTFparameters)
            if contains(paramNum, TDTFparameters{i})
                tmpNum = strrep(tmpNum, TDTFparameters{i}, num2str(paramValues(i)));
            else
                tmpDen = strrep(tmpDen, TDTFparameters{i}, num2str(paramValues(i)));
            end
        end
        numerator = tmpNum;
        denominator = tmpDen;
    end
  
% Check for parametric notation
    function [isParam, numParams] = hasParam(strNum, strDen)
        isParam = any(isstrprop(strNum, 'upper')) | any(isstrprop(strDen, 'upper'));
        numParams = sum(isstrprop(strNum, 'upper')) + sum(isstrprop(strDen, 'upper'));
    end

% Loads png image
    function newImg = setWhiteBackground(img, alpha)
        bgcolor = [1 1 1]; 
        img = im2double(img);
        alpha = im2double(alpha);
        newImg = img.*alpha + permute(bgcolor,[1 3 2]).*(1-alpha);
    end

% Toggle of other toolbar buttons
    function toggleOffOthers(src, varargin)
        for i = 1:length(varargin)
            if isa(varargin{i}, class(src)) % Checks if varargin is ToggleTool
                varargin{i}.State = "off";
            end
        end
    end

% Checks if closed loop is not stable
    function stabilityTest(Fun)
        stabReg = [0 100 -1000 1000];
        stabPoles = QPmR(stabReg, Fun, varargin{3:end});        
        if ~isempty(stabPoles)
            updateStabilityText('Not stable');
        else
            updateStabilityText('');
        end 
    end

% Updates stability text
    function updateStabilityText(str)
        delete(hStableText)
        xL = hAx.XLim(2);
        yL = hAx.YLim(2);
        hStableText = text(hAx, 0.99*xL, 0.99*yL , str, FontSize=16, ...
            HorizontalAlignment='right', VerticalAlignment='top', Color=[1 0 0]);
    end

    function updateRunningText(str)
        delete(hRunningText)
        xL = hAx.XLim(2);
        yL = hAx.YLim(1);
        hRunningText = text(hAx, 0.99*xL, 0.99*yL , str, FontSize=16, ...
                HorizontalAlignment='right', VerticalAlignment='bottom', Color=[1 0 0]);
    end

    %% Callback functions

% Gain slider callback (real-time update)
    function sliderMovement(~, event)
        gainEdit.Value = event.Value;
        updateCLPoles(event.Value, false);
    end

% Gain slider callback (update after slider movement stopped)
    function sliderMoved(~, event)
        gainEdit.Value = event.Value;
        updateCLPoles(event.Value, true);
    end
    
% Gain up callback
    function buttonUp(~, ~)
        if 10*maxSliderLim < power(10, maxLogLim)
            maxSliderLim = 10*maxSliderLim;
            gainSlider.Limits = [minSliderLim, maxSliderLim];
            gainEdit.Limits = [minSliderLim, maxSliderLim];
            updateCLPoles(gainEdit.Value, true);
        end        
    end
    
% Gain down callback
    function buttonDown(~, ~)
        if maxSliderLim/10 > power(10, minLogLim)
            maxSliderLim = maxSliderLim/10;
            gainSlider.Limits = [minSliderLim, maxSliderLim];
            gainEdit.Limits = [minSliderLim, maxSliderLim];
            updateCLPoles(gainEdit.Value, true);
        end
    end

% Edit gain callback
    function editGain(src, ~)
        gainSlider.Value = src.Value;
        updateCLPoles(src.Value, true);
    end

% Axis callback function
    function updateAxes(hAx, hXAxis, hYAxis)
        % Update the x-axis line
        set(hXAxis, XData=hAx.XLim, YData=[0 0]);
        % Update the y-axis line
        set(hYAxis, XData=[0 0], YData=hAx.YLim);
        updateStabilityText(hStableText.String);
        updateRunningText(hRunningText.String);
    end

% Undo action callback
    function doUndo(~, ~)
        if undoStack.getSize() > 0
            [rlocusLinesData, plotPolesData, plotZerosData, plotCLPolesData, ...
                tfText, numerator, denominator, gainData, paramNum, paramDen, ...
                paramTfText] = undoStack.pop();
            clearCanvas();
    
            if ~isempty(rlocusLinesData)
                % Plot root locus
                if hDiscreteRL.Value
                    rlocusLines{1} = plot(hAx, rlocusLinesData{1}, ...
                            rlocusLinesData{2},Tag="rlocus", LineStyle='none', ...
                            Marker='.', MarkerFaceColor=RLLineCol, MarkerEdgeColor=RLLineCol);
                else
                    for idx = 1:width(rlocusLinesData)
                        rlocusLines{idx} = plot(hAx, rlocusLinesData{1, idx}, ...
                            rlocusLinesData{2, idx}, Color=RLLineCol ,Tag="rlocus");
                    end
                end
                
                % Plot OL poles
                plotPoles = plot(hAx, plotPolesData{1}, plotPolesData{2}, "x", ...
                    MarkerFaceColor=OLPoleCol, MarkerEdgeColor=OLPoleCol, ...
                    MarkerSize=10, LineWidth=1.5, Tag="olpole");
                
                
                if ~isempty(plotZerosData)
                % Plot OL zeros
                plotZeros = plot(hAx, plotZerosData{1}, plotZerosData{2}, "o", ...
                    MarkerEdgeColor=OLZeroCol, MarkerSize=10, LineWidth=1.5, ...
                    Tag="olzero");
                end
        
                % Plot CL poles
                plotCLPoles = plot(hAx, plotCLPolesData{1},  plotCLPolesData{2}, "x" ,Tag="clpole", ...
                        MarkerSize=10, LineWidth=1.5, MarkerFaceColor="red", ...
                        MarkerEdgeColor="red");
        
                hTFText.String = tfText;
                gainEdit.Value = gainData;
                gainSlider.Value = gainData;
            end
        end 
    end 


% New time delay transfer function update
    function openTDTFPopupCallback(~, ~)
        hTDTFPopupFig = uifigure(Name='Edit Time delay transfer function', Position=[500, 300, 250, 150]);
        hTDTFLabel = uilabel(hTDTFPopupFig, Text='Choose time delay transfer function', Position=[30 125 250 22]);
        hNumEditField = uieditfield(hTDTFPopupFig, Position=[50 90 150 22]);
        hFraction = uilabel(hTDTFPopupFig, Text='______________________', Position=[50 75 150 22]);
        hDenEditField = uieditfield(hTDTFPopupFig, Position=[50 45 150 22]);
        hEditButton = uibutton(hTDTFPopupFig, Text='Edit', Position=[100 12 50 22], ButtonPushedFcn=@generateNewTDRL);

        if isempty(TDTFparameters) > 0
            hNumEditField.Value = numerator;
            hDenEditField.Value = denominator;
        else
            hNumEditField.Value = paramNum;
            hDenEditField.Value = paramDen;
        end

        function generateNewTDRL(~, ~)
            redraw(hNumEditField.Value, hDenEditField.Value); 
            close(hTDTFPopupFig);
        end
    end
    
% Slider window callback
    function openSliderWindow(~, ~)
        numSliders = length(TDTFparameters);
        hSliderFig = uifigure(Name='Slider Window', Toolbar='none', ...
                Position=[500, 300, 400, numSliders * 60+100]);
        uilabel(hSliderFig, Position=[50 numSliders*60 + 10 400 80], Text=paramTfText, ...
                FontSize=20, Interpreter="latex");
       
        % set new handles
        paramEdits = cell(0);
        paramSliders = cell(0);
        for i = 1:numSliders
             uilabel(hSliderFig, Text=TDTFparameters(i), ...
                 Position=[20, numSliders*60-i*50, 120, 20]);
            
             paramEdits{i} = uieditfield(hSliderFig, 'numeric', Value=paramValues(i), ...
                 Position=[60, numSliders*60-i*50, 80, 20], Tag=['edit_' num2str(i)], ...
                 ValueChangedFcn=@editParamValue);

            
             % Create the slider
             paramSliders{i} = uislider(hSliderFig, Position=[160, numSliders*60-i*50+20, 200, 3], ...
                 Limits=[-10 10], Value=paramValues(i), ... 
                 Tag=['slider_' num2str(i)], ValueChangedFcn=@editParamValue); % Tag the slider for future reference
        end
        
        % Parameter update callback
        function editParamValue(src, ~)
            idx = str2double(src.Tag(end));
            paramValues(idx) = src.Value;
            paramEdits{idx}.Value = src.Value;
            paramSliders{idx}.Value = src.Value;
            
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
        hMinReal = uieditfield(hRegPopupFig, 'numeric', Position=[110 90 50 22], Value=Reg(1));
        hMaxReal = uieditfield(hRegPopupFig, 'numeric', Position=[185 90 50 22], Value=Reg(2));
        uilabel(hRegPopupFig, Text='Imaginary limits:', Position=[5 45 90 22]);
        uilabel(hRegPopupFig, Text='Min', Position=[125 67 50 22]);
        uilabel(hRegPopupFig, Text='Max', Position=[200 67 50 22]);
        hMinImag = uieditfield(hRegPopupFig, 'numeric', Position=[110 45 50 22], Value=Reg(3));
        hMaxImag = uieditfield(hRegPopupFig, "numeric", Position=[185 45 50 22], Value=Reg(4));
        hPlotButton = uibutton(hRegPopupFig, Text="Plot", Position=[100 10 50 22], ButtonPushedFcn=@setNewReg);
        
   
        function setNewReg(~, ~)
            Reg = [hMinReal.Value hMaxReal.Value hMinImag.Value hMaxImag.Value];
            redrawRegion(src, false);
            close(hRegPopupFig);
        end

    end

% Automatic region callback
    function redrawRegion(~, auto)
        if auto == true
            xMin = hAx.XLim(1);
            xMax = hAx.XLim(2);
            yMin = hAx.YLim(1);
            yMax = hAx.YLim(2);
            Reg = [xMin xMax yMin yMax];
        end
        
        redraw(numerator, denominator)
    end


    function toggleRLMode(~, ~)
        if contains(numerator, 's') || contains(denominator, 's')
            redraw(numerator, denominator);
        end
    end


% Mouse click event callback 
    function mouseClickCallback(~, ~)
        % Get the current point in the figure
        cp = get(hAx, 'CurrentPoint');
        x = cp(1,1);
        y = cp(1,2);
        addingPZ = (hPoleSelect.State == "on") | (hPolesSelect.State == "on") ...
            | (hZeroSelect.State == "on") | (hZerosSelect.State == "on");
        if addingPZ
            if selectedMode == "RealPole"
                newDen = strcat('(', denominator, ')', '.*', '(s-',num2str(x), ')' );
                newParDen = strcat('(', paramDen, ')', '.*', '(s-',num2str(x), ')' );
                newNum = numerator;
                newParNum = paramNum;
            elseif selectedMode == "ImagPole"
                newPoly = rootsToPoly([x+y*1i x-y*1i]);
                newDen = strcat('(', denominator, ')', '.*', '(',newPoly,')' );
                newParDen = strcat('(', paramDen, ')', '.*', '(',newPoly,')' );
                newNum = numerator;
                newParNum = paramNum;
            elseif selectedMode == "RealZero"
                newDen = denominator;
                newParDen = paramDen;
                newNum = strcat('(', numerator, ')', '.*', '(s-',num2str(x), ')' );
                newParNum = strcat('(', paramNum, ')', '.*', '(s-',num2str(x), ')' );
            elseif selectedMode == "ImagZero"
                newPoly = rootsToPoly([x+y*1i x-y*1i]);
                newDen = denominator;
                newParDen = paramDen;
                newNum = strcat('(', numerator, ')', '.*', '(',newPoly,')' );
                newParNum = strcat('(', paramNum, ')', '.*', '(',newPoly,')' );
            end
            if isempty(paramValues)
                redraw(newNum, newDen);
            else
                    redraw(newParNum, newParDen);
            end
        end
    end

% Toggle pole/zero adding mode callback
    function toggleModeSelect(src, varargin)
        toggleOffOthers(src, varargin{:});
        idx = str2num(src.Tag);
        selectedMode = selectionModes{idx};
    end

% Pan on callback
    function panOn(src, ~)
        toggleOffOthers(src, hPoleSelect, hPolesSelect, ...
            hZeroSelect, hZerosSelect, hZoomInBtn, hZoomOutBtn);
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
            hPanBtn, hZoomOutBtn);
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
            hZoomInBtn, hPanBtn);
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

end %tdrlocus
