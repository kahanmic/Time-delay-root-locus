classdef UndoStack < handle
    % UndoStack
    % Stack of previous states of root locus
    properties (Access = private)
        StackRL
        StackOLPole
        StackOLZero
        StackCLPole
        StackNumP
        StackDenP
        StackD
        StackGain
        StackParamNum
        StackParamDen
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
            obj.StackNumP = {};
            obj.StackDenP = {};
            obj.StackD = {};
            obj.StackGain = {};
            obj.StackParamNum = {};
            obj.StackParamDen = {};
        end 

        % Push new state to the stack
        function push(obj, rl, olpole, olzero, clpole, numP, denP, D, ...
                gain, parnum, parden)
            % Remove oldest item if stack storrage exceeds limit
            if length(obj.StackRL) >= obj.MaxSize
                obj.StackRL(1) = [];
                obj.StackOLPole(1) = [];
                obj.StackOLZero(1) = [];
                obj.StackCLPole(1) = [];
                obj.StackNumP(1) = [];
                obj.StackDenP(1) = [];
                obj.StackD(1) = [];             
                obj.StackGain(1) = [];
                obj.StackParamNum(1) = [];
                obj.StackParamDen(1) = [];
            end

            % Add most recent state
            obj.StackRL{end+1} = rl;
            obj.StackOLPole{end+1} = olpole;
            obj.StackOLZero{end+1} = olzero;
            obj.StackCLPole{end+1} = clpole;
            obj.StackNumP{end+1} = numP;
            obj.StackDenP{end+1} = denP;
            obj.StackD{end+1} = D;          
            obj.StackGain{end+1} = gain;
            obj.StackParamNum{end+1} = parnum;
            obj.StackParamDen{end+1} = parden;
        end
       
        % Pop from stack
        function [rl, olpole, olzero, clpole, numP, denP, D, gain, ...
                parnum, parden] = pop(obj)
            if ~obj.isEmpty()
                % Get data from stack
                rl = obj.StackRL{end};
                olpole = obj.StackOLPole{end};
                olzero = obj.StackOLZero{end};
                clpole = obj.StackCLPole{end};
                numP = obj.StackNumP{end};
                denP = obj.StackDenP{end};
                D = obj.StackD{end};              
                gain = obj.StackGain{end};
                parnum = obj.StackParamNum{end};
                parden = obj.StackParamDen{end};

                
                % Remove from stack
                obj.StackRL(end) = [];
                obj.StackOLPole(end) = [];
                obj.StackOLZero(end) = [];
                obj.StackCLPole(end) = [];
                obj.StackNumP(end) = [];
                obj.StackDenP(end) = [];
                obj.StackD(end) = [];
                obj.StackGain(end) = [];
                obj.StackParamNum(end) = [];
                obj.StackParamDen(end) = [];
            else % maybe remove else
                rl = [];
                olpole = [];
                olzero = [];
                clpole = [];
                numP = 1;
                denP = 1;
                D = 0;               
                gain = 1;
                parnum = '';    % change in the future
                parden = '';
            end
        end

        % Check if stack is empty
        function stackEmpty = isEmpty(obj)
            stackEmpty = isempty(obj.StackRL);
        end

        % Undo operation
        function [rl, olpole, olzero, clpole, numP, denP, D, gain, ...
                parnum, parden] = undo(obj)
            if obj.isEmpty()
                rl = [];
                olpole = [];
                olzero = [];
                clpole = [];
                numP = 1;
                denP = 1;
                D = 0;             
                gain = 1;
                parnum = '';
                parden = '';
            else
                [rl, olpole, olzero, clpole, numP, denP, D, gain, ...
                parnum, parden] = obj.pop();
            end
        end

        % Clear the stack
        function clear(obj)
            obj.StackRL = {};
            obj.StackOLPole = {};
            obj.StackOLZero = {};
            obj.StackCLPole = {};
            obj.StackNumP = {};
            obj.StackDenP = {};
            obj.StackD = {};          
            obj.StackGain = {};
            obj.StackParamNum = {};
            obj.StackParamDen = {};
        end

        function size = getSize(obj)
            size = length(obj.StackCLPole);
        end
    end
end
