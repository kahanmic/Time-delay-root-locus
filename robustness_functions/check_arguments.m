function isOkay = check_arguments(varargin)
    isOkay = false;
    if nargin == 2
        if (isstring(varargin{1}) || ischar(varargin{1})) && (isstring(varargin{2}) || ischar(varargin{2}))
            isOkay = true;
        else
            warning("Numerator and denominator must be string/char.")
        end
    elseif nargin == 4
        if size(varargin{1}, 1) == size(varargin{2}, 1) && size(varargin{2}, 2) == 1 && size(varargin{3}, 1) == size(varargin{4}, 1) && size(varargin{4}, 2) == 1
            isOkay = true;
        else
            warning("Invalid Matrix dimensions.")
        end
    end
end
