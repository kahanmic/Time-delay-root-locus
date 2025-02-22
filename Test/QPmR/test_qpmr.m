bmin = -10;
bmax = 5;
wmin = 0;
wmax = 50;
ds = 0.1;
P = [1.5 0.2 0 20.1;1 0 -2.1 0;0 0 3.2 0;0 0 0 1.4];
Z = [0;1.3;3.5;4.3];

% Hodnoty meshgridu
beta=bmin:ds:bmax;  
omega=wmin:ds:wmax;

%mapping the zerolevel curves of the function
[B W]=meshgrid(beta,omega);
S=B+j*W;
rad=length(P(1,:))-1;   % rad polynomu
poczp=length(Z);     % pocet zpozdeni
for k=1:rad+1;
   Sp(k,:,:)=S.^(k-1);
end