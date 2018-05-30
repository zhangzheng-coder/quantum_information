% Matrices stay nonflat in the main body of code

% Given:
P_ABC = [0.5;0;0;0;0;0;0;0.5]; %(000, 100, 010, 110, 001, 101, 011, 111)
 
% P_ABC in CG coordinate:
G_ABC = p2cg(P_ABC);

zero_vector = zeros(8,1);

cvx_begin
    variable x(16); % x is concat(P_CG_inf, z)
    dual variables y1 y2 y3 y4 y5;
    expressions P_CG_inf(8) z(8);
    P_CG_inf = x(1:8);
    z = x(9:16);
    subject to 
        % Equality conditions
        % G_A2C1 = G_AC
        y1: cgmarginal(P_CG_inf, [1 3]) == cgmarginal(G_ABC, [1 3]);
        % G_B1C1 = G_BC
        y2: cgmarginal(P_CG_inf, [2 3]) == cgmarginal(G_ABC, [2 3]);
        % G_A2B1 = S * P_A * P_B
        y3: cgmarginal(P_CG_inf, [1 2]) == p2cg((pmarginal(P_ABC, 1))*(pmarginal(P_ABC, 2)).');
        % Nonnegative conditions
        y4: cg2p(P_CG_inf) - z == 0;
        y5: z >= 0;
cvx_end

% RESULTS
% Status: Infeasible
% Optimal value (cvx_optval): -Inf

b = [cgmarginal(G_ABC, [1 3]);
	cgmarginal(G_ABC, [2 3]);
	p2cg((pmarginal(P_ABC, 1))*(pmarginal(P_ABC, 2)).')]

b.', b.' * [y1; y2; y3]
