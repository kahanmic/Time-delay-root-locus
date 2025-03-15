function [nP, dP, D] = create_rl_matrix(numP, numD, denP, denD)
% Creates one quasipolynomial matrix notation of den + K*num from two
% quasipolynomial matrix notations.

    all_delays = [numD; denD];
    nrep_delays = unique(all_delays);
    N = length(nrep_delays); % N number of delays
    n = max([size(numP, 2), size(denP, 2)]);

    nP = zeros(N, n);
    D = nrep_delays;
    for i1 = 1:size(numP,1)
        idx = find(nrep_delays == numD(i1));
        nP(idx, n+1-size(numP,2):end) = nP(idx, n+1-size(numP,2):end) + numP(i1,1:end);
    end

    dP = zeros(N, n);
    for i2 = 1:size(denD,1)
        idx = find(nrep_delays == denD(i2));
        dP(idx, n+1-size(denP,2):end) = dP(idx, n+1-size(denP,2):end) + denP(i2,1:end);
    end

end