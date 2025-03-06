function tdrlocus(reg, varargin)
% tdrlocus v2
% numerator = "1+0.1.*exp(-s)"; denominator = "2.*s+exp(-s)"; Reg = [-10 5 0 50];
% tdrlocus(Reg, numerator, denominator)
% denominator = "2.*s+exp(-s)"
%numP = [1; 0.0183]; numD = [0; 1]; denP = [2 0; 0 1]; denD = [0; 1];



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
    plotNextRoot = [];

    numP = [];
    denP = [];
    numdP = [];
    dendP = [];
    D = [];
    clPoles = [];
    ds = 0.1;

    % Limits of gain on slider
    minSliderLim = 0;
    maxSliderLim = 1e4;
    
    % Logical variables
    movePoles = false;
    movingPolesNow = false;

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

    % Gain slider
    gainSlider = uislider(myLayout, Value=1);
    gainSlider.Limits = [minSliderLim, maxSliderLim];
    gainSlider.Layout.Column = [3 4];
    gainSlider.Layout.Row = [3 4];

    gainSlider.ValueChangingFcn = @sliderMovement;
    gainSlider.ValueChangedFcn = @sliderMoved;

    % Gain edit field
    gainEdit = uieditfield(myLayout, 'numeric',...
        Limits=[minSliderLim, power(10, maxSliderLim)],...
        ValueChangedFcn=@editGain, Value=1, HorizontalAlignment='center');
    gainEdit.Layout.Column = 2;
    gainEdit.Layout.Row = 4;


    %%
    drawRL(varargin{:})
    
    function drawRL(varargin)
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
        
        [numP, denP, D] = create_rl_marix(numP, numD, denP, denD);


        %P = denP + K0*numP; % Current polynomial
        numdP = derivate_quasipolynomial(numP, D);
        dendP = derivate_quasipolynomial(denP, D);

        olZeros = compute_roots(reg, numP, D, ds);
        olPoles = compute_roots(reg, denP, D, ds);
        clPoles = compute_roots(reg, denP+numP, D, ds);

        % Draw root locus
        lines = draw_rl_lines(reg, 1e10, olZeros, olPoles, numP, denP, D,...
            numdP, dendP, ds, 0.01, 0.5);
        numLines = length(lines);
        rlocusLines = cell(2*numLines, 1);
        for i = 1:numLines
            rlocusLines{2*i-1} = plot(hAx, real(lines{i}), imag(lines{i}), Color=RLLineCol, Tag='rlocus', LineWidth=1.5);
            rlocusLines{2*i} = plot(hAx, real(lines{i}), -imag(lines{i}), Color=RLLineCol, Tag='rlocus', LineWidth=1.5);
        end

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

    function updateCLPoles
        plotCLPoles.XData = [real(clPoles), real(clPoles)];
        plotCLPoles.YData = [imag(clPoles), -imag(clPoles)];
    end % function

% Gain slider callback (update after slider movement stopped)
    function sliderMovement(~, event)
        dK = event.Value - gainEdit.Value;
        
        %clPoles = compute_roots(reg, denP+event.Value*numP, D, ds);
        clPoles = iterate_root(clPoles, numP, denP, D, dendP, numdP, ds, gainEdit.Value, dK);
        %clPoles = [poles, conj(poles)];
        gainEdit.Value = event.Value;
        updateCLPoles;
    end

% Gain slider callback (update after slider movement stopped)
    function sliderMoved(~, event)
        clPoles = compute_roots(reg, denP+event.Value*numP, D, ds);
        %clPoles = [poles, conj(poles)];
        gainEdit.Value = event.Value;
        updateCLPoles;
    end

% Edit gain callback
    function editGain(src, ~)
        %dK = src.Value - gainEdit.Value;
        clPoles = compute_roots(reg, denP+src.Value*numP, D, ds);
        %clPoles = [poles, conj(poles)];
        gainSlider.Value = src.Value;
        updateCLPoles;
    end

% Enable changing gain by dragging
    function moveOn(~, ~)
        movePoles= true;
    end

% Disable changing poles by dragging
    function moveOff(~, ~)
        movePoles = false;
        delete(plotNextRoot)
        plotNextRoot = [];
    end

    function mousePushed(~, ~)
        movingPolesNow = true;
        if movePoles
            set(hFig, 'WindowButtonMotionFcn', @holdAndChangeGain);
        end
    end

    function mouseReleased(~, ~)
        movingPolesNow = false;
        disp("a")
        set(hFig, 'WindowButtonMotionFcn', []);
        delete(plotNextRoot);
        drawnow
    end

    function holdAndChangeGain(~, ~)
        cp = get(hAx, 'CurrentPoint');
        
        x = cp(1,1);
        y = cp(1,2);
        activeXReg = diff(hAx.XLim)/10;
        activeYReg = diff(hAx.YLim)/10;
        dists = sqrt(((plotCLPoles.XData - x) / activeXReg).^2 + ((plotCLPoles.YData - y) / activeYReg).^2);
        % xdists = abs(plotCLPoles.XData - x)
        % ydists = abs(plotCLPoles.YData - x)

        [minVal, minIdx] = min(dists);
        % if minVal < (activeXReg + activeYReg)
        %     s0 = clPoles(minIdx);
        %     deltas = x+y*1i - s0;
        %     dK = get_dk(s0, gainEdit.Value, numP, numdP, dendP, D, deltas);
        %     gainEdit.Value = gainEdit.Value + dK;
        %     clPoles = compute_roots(reg, denP+gainEdit.Value*numP, D, ds);
        %     updateCLPoles;
        % end
        if minVal < (activeXReg + activeYReg) && movingPolesNow
            s0 = clPoles(minIdx);
            K0 = gainEdit.Value;
            sVec = (x + y*1i) - s0;
            nextRoot = pole_projection(s0, K0, numP, numdP, dendP, D, sVec);
            plotNextRoot = plot(hAx, real(nextRoot), imag(nextRoot), "bx", Tag="test");
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
end

function rootPos = pole_projection(s0, K0, numP, numdP, dendP, D, sVec)
    num = evaluate_poly(s0, numP, D, 0.1, false);
    den = evaluate_poly(s0, dendP, D, 0.1, false) + K0.*evaluate_poly(s0, numdP, D, 0.1,  false);
    C = -(num./den)
    sVec
    v1 = [real(C); imag(C)];
    v2 = [real(sVec), imag(sVec)];
    
    rProj = dot(v1, v2)/dot(v1, v1)*C;

    rootPos = s0 + rProj;


end