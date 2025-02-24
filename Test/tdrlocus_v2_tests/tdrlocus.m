function tdrlocus(reg, varargin)
% tdrlocus v2

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
    minLogLim = -5;
    maxLogLim = 10;
    
    [numP numD] = string2matrix(varargin{1});
    [denP denD] = string2matrix(varargin{2});
    
    [numP, denP, D] = create_rl_marix(numP, numD, denP, denD);
    %numP = [1; 0.0183]; numD = [0; 1]; denP = [2 0; 0 1]; denD = [0; 1];

    % P=[1.5 0.2 0 20.1;1 0 -2.1 0;0 0 3.2 0;0 0 0 1.4];
    % D=[0;1.3;3.5;4.3];

    if nargin > 0
        xLimits = [reg(1) reg(2)];
        yLimits = [reg(3) reg(4)];
    else
        xLimits = [defaultReg(1) defaultReg(2)];
        yLimits = [defaultReg(3) defaultReg(4)];
    end

    %% GUI Setup
    hFig = uifigure(Position=figPosition, Name='Time delay Root Locus', ...
       Color=figColor);
    myLayout = uigridlayout(hFig, RowHeight={'4x', '16x', '1x', '1x'}, ...
        ColumnWidth={'2x', '4x', '3x', '12x', '1x'}, BackgroundColor=figColor);
    
    % Plot axes
    hAx = uiaxes(myLayout, Color=axesColor, Box="on", XGrid="on", YGrid="on", ...
        XLim=xLimits, YLim=yLimits);
    hAx.Layout.Column = [1 5];
    hAx.Layout.Row = [1 2];
    hAx.XLabel.String = 'Real part';
    hAx.YLabel.String = 'Imaginary part';
    hAx.Toolbar.Visible = 'off';
    hold(hAx, 'on');


    drawRL
    
    function drawRL
        roots = compute_roots(reg, P, D, 0.1)
        plot(hAx, real(roots), imag(roots), 'rx', 'MarkerSize', 8, 'MarkerFaceColor', 'k', 'LineWidth', 1.5);
    end


end