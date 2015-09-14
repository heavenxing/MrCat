function H = jointentropy(data)
% function H = jointentropy(data)
%
% Calculate the joint entropy between the two columns of the matrix in bits
%
% Rogier B. Mars, University of Oxford, 06022014

%=========================================================
% Housekeeping
%=========================================================

if size(data,2)~=2, error('Error: size(data,2) incorrect in jointentropy.m!'); end

elementsA = unique(data(:,1));
elementsB = unique(data(:,2));

%=========================================================
% Do the work
%=========================================================

% Get joint probabilities
jointPs = get_jointprobs(data);
jointPs = jointPs(:);

% if iselement(0,jointPs), error('Error: joint probability of zero found in jointentropy.m!'); end

% Caclulate joint entropy
J = jointPs.*log2(jointPs);
J(isnan(J)) = 0; % Remove effects of joint probabilities of zero
H = -sum(J);