tic

P=[1.5 0.2 0 20.1;1 0 -2.1 0;0 0 3.2 0;0 0 0 1.4];
D=[0;1.3;3.5;4.3];

%bmin = -1; bmax = 2; wmin = -1; wmax = 1;
bmin = -10; bmax = 5; wmin = -50; wmax = 50;
ds = (bmax-bmin)*(wmax-wmin)/1000;

bmin = -1; bmax = 2; wmin = -1; wmax = 1;
ds = 1;
N = size(P, 1);
n = size(P, 2);
order = n - 1;

beta=bmin:ds:bmax;  
omega=wmin:ds:wmax;
b = length(beta);
w = length(omega);

[B, W]=meshgrid(beta,omega);
S = B+W.*1i;    % origin is on the left
%  bottom corner
S2 = reshape(S, [], 1);
k = order:-1:0;

M = (S2.^k).'; % mocneni kazdeho bodu az do n-1. radu (matrix of n x L)
H = ones(1,N)*(exp(-D*S2.').*(P*M));
H2 = reshape(H, [w b]);
toc
%%


tic
P=[1.5 0.2 0 20.1;1 0 -2.1 0;0 0 3.2 0;0 0 0 1.4];
Z=[0;1.3;3.5;4.3];

bmin = -10; bmax = 5; wmin = -50; wmax = 50;
ds = (bmax-bmin)*(wmax-wmin)/1000;

bmin = -1; bmax = 2; wmin = -1; wmax = 1;
ds = 1;
beta=bmin:ds:bmax;  
omega=wmin:ds:wmax;


[B W]=meshgrid(beta,omega);
S=B+j*W;
rad=length(P(1,:))-1;   % rad polynomu
poczp=length(Z);     % pocet zpozdeni
for k1=1:rad+1    % Sp 3D, pro každý řád se mocní hodnota na meshgridu
   Sp(k1,:,:)=S.^(k1-1);
end

MM=zeros(size(S));
for k1=1:poczp    % iterace pres vsechna zpozdeni
   M=zeros(size(S));
   for m=1:rad+1    % iterace pres vsechny rady
       M=M+squeeze(Sp(m,:,:))*P(k1,rad+2-m); % squeeze udela z 3D matice 2D matici (beru m-ty rad), P jen jedna hodnota?
   end
   MM=MM+M.*exp(-Z(k1)*S);
end
toc
%%----------------------------------------------------------------------------------------


