function weights = pawQuadrantWeights_Distance(varargin)
% max_distance is optional and always defined on the normalized coordinate
% system, meaning that the values range from 0 to 1;

    x = varargin{1};    y = varargin{2}; 
    Mx= varargin{3};	My= varargin{4}; 
    Px= varargin{5}(1);	Py= varargin{5}(2);
    
    if size(varargin{5},2) > 2
        max_distance = varargin{5}(3);
    else
         max_distance = 1;
    end
    
    if size(varargin{5},2) ==7
        xMin = varargin{5}(4);
        xMax = varargin{5}(5);
        yMin = varargin{5}(6);
        yMax = varargin{5}(7);
    else
        xMin = NaN;
        xMax = NaN;
        yMin = NaN;
        yMax = NaN;
    end

    if ~isvector(x) || ~isvector(y)
        error('x and y must be vectors');
    end

    Nx = length(x);
    Ny = length(y);

    if Nx ~= Ny
        error('x and y must have the same number of elements!');
    end

    x = (x-Mx(1))./(Mx(2)-Mx(1)+1);
    y = (y-My(1))./(My(2)-My(1)+1);

    weights = 1 - sqrt((x - Px).^2 + (y - Py).^2)/sqrt(2);

    if max_distance ~= 1
        weights(weights < (1-max_distance)) = 0;
    end
    if ~any(isnan([xMin xMax yMin yMax]))
        weights(x < xMin | x > xMax) = 0;
        weights(y < yMin | y > yMax) = 0;
    end
end