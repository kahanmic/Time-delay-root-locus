classdef UndoStack < handle
    % UndoStack
    % Stack of previous states of root locus
    properties (Access = private)
        StackRL
        StackOLPole
        StackOLZero
        StackCLPole
        StackTFText
        StackNum
        StackDen
        StackGain
        StackParamNum
        StackParamDen
        StackParamTFText
        MaxSize
    end

    methods
        % Constructor
        function obj = UndoStack(maxSize)
            obj.MaxSize = maxSize;
            obj.StackRL = {};
            obj.StackOLPole = {};
            obj.StackOLZero = {};
            obj.StackCLPole = {};
            obj.StackTFText = {};
            obj.StackNum = {};
            obj.StackDen = {};
            obj.StackGain = {};
            obj.StackParamNum = {};
            obj.StackParamDen = {};
            obj.StackParamTFText = {};
        end 

        % Push new state to the stack
        function push(obj, rl, olpole, olzero, clpole, tftext, num, den, ...
                gain, parnum, parden, partext)
            % Remove oldest item if stack storrage exceeds limit
            if length(obj.StackRL) >= obj.MaxSize
                obj.StackRL(1) = [];
                obj.StackOLPole(1) = [];
                obj.StackOLZero(1) = [];
                obj.StackCLPole(1) = [];
                obj.StackTFText(1) = [];
                obj.StackNum(1) = [];
                obj.StackDen(1) = [];
                obj.StackGain(1) = [];
                obj.StackParamNum(1) = [];
                obj.StackParamDen(1) = [];
                obj.StackParamTFText(1) = [];
            end

            % Add most recent state
            obj.StackRL{end+1} = rl;
            obj.StackOLPole{end+1} = olpole;
            obj.StackOLZero{end+1} = olzero;
            obj.StackCLPole{end+1} = clpole;
            obj.StackTFText{end+1} = tftext;
            obj.StackNum{end+1} = num;
            obj.StackDen{end+1} = den;
            obj.StackGain{end+1} = gain;
            obj.StackParamNum{end+1} = parnum;
            obj.StackParamDen{end+1} = parden;
            obj.StackParamTFText{end+1} = partext;
        end
       
        % Pop from stack
        function [rl, olpole, olzero, clpole, tftext, num, den, gain, parnum, parden, partext] = pop(obj)
            if ~obj.isEmpty()
                % Get data from stack
                rl = obj.StackRL{end};
                olpole = obj.StackOLPole{end};
                olzero = obj.StackOLZero{end};
                clpole = obj.StackCLPole{end};
                tftext = obj.StackTFText{end};
                num = obj.StackNum{end};
                den = obj.StackDen{end};
                gain = obj.StackGain{end};
                parnum = obj.StackParamNum{end};
                parden = obj.StackParamDen{end};
                partext = obj.StackParamTFText{end};

                
                % Remove from stack
                obj.StackRL(end) = [];
                obj.StackOLPole(end) = [];
                obj.StackOLZero(end) = [];
                obj.StackCLPole(end) = [];
                obj.StackTFText(end) = [];
                obj.StackNum(end) = [];
                obj.StackDen(end) = [];
                obj.StackGain(end) = [];
                obj.StackParamNum(end) = [];
                obj.StackParamDen(end) = [];
                obj.StackParamTFText(end) = [];
            else
                rl = [];
                olpole = [];
                olzero = [];
                clpole = [];
                tftext = '';
                num = '1';
                den = '1';
                gain = 1;
                parnum = '';
                parden = '';
                partext = '';
            end
        end

        % Check if stack is empty
        function stackEmpty = isEmpty(obj)
            cnt = 0;
            cnt = cnt + ~isempty(obj.StackRL);
            cnt = cnt + ~isempty(obj.StackOLPole);
            cnt = cnt + ~isempty(obj.StackOLZero);
            cnt = cnt + ~isempty(obj.StackCLPole);
            cnt = cnt + ~isempty(obj.StackTFText);
            cnt = cnt + ~isempty(obj.StackNum);
            cnt = cnt + ~isempty(obj.StackDen);
            cnt = cnt + ~isempty(obj.StackGain);
            cnt = cnt + ~isempty(obj.StackParamNum);
            cnt = cnt + ~isempty(obj.StackParamDen);
            cnt = cnt + ~isempty(obj.StackParamTFText);
            stackEmpty = (cnt == 0);
        end

        % Undo operation
        function [rl, olpole, olzero, clpole, tftext, num, den, gain, parnum, parden, partext] = undo(obj)
            if obj.isEmpty()
                rl = [];
                olpole = [];
                olzero = [];
                clpole = [];
                tftext = '';
                num = '1';
                den = '1';
                gain = 1;
                parnum = '';
                parden = '';
                partext = '';
            else
                [rl, olpole, olzero, clpole, tftext, num, den, gain, parnum, parden, partext] = obj.pop();
            end
        end

        % Clear the stack
        function clear(obj)
            obj.StackRL = {};
            obj.StackOLPole = {};
            obj.StackOLZero = {};
            obj.StackCLPole = {};
            obj.StackTFText = {};
            obj.StackNum = {};
            obj.StackDen = {};
            obj.StackGain = {};
            obj.StackParamNum = {};
            obj.StackParamDen = {};
            obj.StackParamTFText = {};
        end

        function size = getSize(obj)
            size = length(obj.StackCLPole);
        end
    end
end
