function H = columnentropy(data,varargin)
% function H = columnentropy(data,varagin)
%
% Calculate the entropy of the columns of a matrix in bits
%
% By default, this function assumes that you are passing vectors elements.
% If you want to pass a vector of (marginal) probabilites, add the optional
% parameter 'datatype' as 'probabilities'
%
% Obligatory input:
%   data    data matrix
%
% Optional inputs:
%   datatype    'elements' (default) or 'probabilities'
%
% Rogier B. Mars, University of Oxford, 05022014
% 09032014 RBM Added option to pass probability matrix

%=========================================================
% Housekeeping
%=========================================================

% Defaults
datatype = 'elements';

if nargin>1
    for argnr = 2:2:nargin
        switch varargin{argnr-1}
            case 'datatype'
                datatype = varargin{argnr};
        end
    end
end

%=========================================================
% Do the work
%=========================================================

switch datatype
    case 'elements'
        
        %--------------------------------------------------
        % If working with element input matrix
        %--------------------------------------------------
        
        elements = unique(data)';
        for d = 1:size(data,2)
            
            % Get frequencies
            P = [];
            for i = 1:length(elements)
                
                e = elements(i);
                P(i) = length(find(data(:,d)==e))/size(data,1);
                
            end
            
            % Calculate entropy
            H(d) = -sum(P.*log2(P));
            
        end
        
    case 'probabilities'
        
        %--------------------------------------------------
        % If working with probability matrix
        %--------------------------------------------------
        
        for d = 1:size(data,2)
            
            P = data(:,d);
            
            % Calculate entropy
            H(d) = -sum(P.*log2(P));
            
        end
        
end