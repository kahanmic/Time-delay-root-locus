A = [1 2 3; 4 5 6]  % 2x2 matrix
% A2 = [5 6; 7 8];  % Another 2x2 matrix
% A3 = [9 10; 11 12]; % Another one
P = [1 0 2 1; 0 2 0 1; 0 0 1 1];
D = [0 1 2].';
%A = cat(3, A1, A2, A3)

k = 0:3;
vk = reshape(k, 1, 1, length(k));

M = A.^vk
size(M);
size(permute(M, [3 1 2]));
M2 = permute(M, [3 1 2]);
%P*M(1, 1, :)