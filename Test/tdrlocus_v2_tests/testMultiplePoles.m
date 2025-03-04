function testMultiplePoles(reg, varargin)
% tdrlocus v2
% numerator = "1+0.1.*exp(-s)"
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

    numP = [];
    denP = [];
    numdP = [];
    dendP = [];
    D = [];
    clPoles = [];


    % minLogLim = -5;
    % maxLogLim = 10;
    % samples = 400;
    ds = 0.1;
    % delGain = logspace(minLogLim, maxLogLim, samples);

    % Limits of gain on slider
    minSliderLim = 0.00147;

    maxSliderLim = 0.00152;
    maxSliderLim = 10;
    
    

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

    % Gain slider
    gainSlider = uislider(myLayout, Value=1);
    gainSlider.Limits = [minSliderLim, maxSliderLim];
    gainSlider.Layout.Column = [3 4];
    gainSlider.Layout.Row = [3 4];

    gainSlider.ValueChangingFcn = @sliderMovement;


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
        lines = draw_rl_lines(1e12, olZeros, olPoles, numP, denP, D, numdP, dendP, ds, 0.01, 1);
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

    function updateCLPoles(~)
        
        
        plotCLPoles.XData = real(clPoles);
        plotCLPoles.YData = imag(clPoles);
    end % function

% Gain slider callback (update after slider movement stopped)
    function sliderMovement(~, event)
        %gainEdit.Value = event.Value;
        clPoles = compute_roots(reg, denP+event.Value*numP, D, ds);
        num = evaluate_poly(clPoles, numP, D, ds, false);
        den = evaluate_poly(clPoles, dendP, D, ds, false) + event.Value.*evaluate_poly(clPoles, numdP, D, ds, false);
        den
        updateCLPoles;
    end

end