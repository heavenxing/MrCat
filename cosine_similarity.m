function cos_similarity = costine_similarity(a,b)
% function cos_angle = costine_similarity(a,b)
%
% Calculate cosine similarity between column vector a and column vectors in
% b
%
% Rogier B. Mars, 04012015, Donders Institute/University of Oxford
% 17032015 RBM Fixed bug in looping over the same b all the time

%===============================================
% Housekeeping
%===============================================

if size(a,2)>1, error('Error in cos_similarity: input a not a column vector!'); end
if ~isequal(size(a,1),size(b,1)), error('Error in cos_similarity: inputs not of same length!'); end

%===============================================
% Do the work
%===============================================

cos_similarity = [];

for i = 1:size(b,2)
   cos_similarity(i) =  (a'*b(:,i))/(sqrt(sum(a.^2)*sum(b(:,i).^2)));
end