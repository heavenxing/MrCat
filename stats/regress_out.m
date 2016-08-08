function Yr = regress_out(Y,X)
% function Yr = regress_out(Y,X)
% Produces Yr after regressing X out of Y
%
% Y is NxP and X is NxQ
%--------------------------------------------------------------------------
%
% version history
% 2016-03-23    Rogier  added to MrCat, based on Saad's original
%
%--------------------------------------------------------------------------

m=repmat(mean(Y),size(Y,1),1);

M=[ones(size(X,1),1) X];

Yr = Y - (M*(pinv(M)*Y)) + m;

% figure
% subplot(1,2,1),hold on
% plot(X,Y,'k.')
% plot(X,M*(pinv(M)*Y),'r');
% subplot(1,2,2),hold on
% plot(X,Yr,'.');
