function [stats, solveroutput] = yalmip_spiral(nout, P_ABC, solver, basis, slack, optimizer)

%--------------Constraint matrices---------------
[A, b, G, h] = get_spiral_constraints(nout, P_ABC, basis);

%--------------YALMIP solver options---------------
if (strcmpi(solver, 'Mosek')) && (nargin > 5)
    options = sdpsettings('solver',solver,'verbose',1,'savesolveroutput',1, 'mosek.MSK_IPAR_OPTIMIZER', optimizer);
else
    options = sdpsettings('solver',solver,'verbose',1,'savesolveroutput',1);
end
    
%--------------YALMIP without slack---------------
if slack == false
    % VARIABLES
    x = sdpvar(nout^6, 1);%column vector
    % OBJECTIVE
    Objective = [];%feasibility
    % CONSTRAINTS
    if G == 0
        Constraints = [A * x == b, x >= 0];
    else
        Constraints = [A * x == b, G * x <= h];
    end
    
    % Run optimizer
    sol = optimize(Constraints,Objective,options);

else
    %--------------YALMIP with slack---------------
    % VARIABLES
    x = sdpvar(nout^6, 1);
    t = sdpvar(1);%scalar
    % OBJECTIVE
    Objective = t;
    % CONSTRAINTS
    if G == 0
        Constraints = [A * x == b, x >= t];
    else
        Constraints = [A * x == b, G * x + t <= h];
    end
    
    % Run optimizer
    sol = optimize(Constraints,-Objective,options);%maximize
end

% Save solver output
solveroutput = sol.solveroutput;

% Calculate primal dual gap stats
primal_opt = value(Objective);
y = dual(Constraints(1));
dual_opt = dot(y, b);
gap = primal_opt - dual_opt;

% Collect statistics
stats = {sol.yalmiptime, sol.solvertime, yalmiperror(sol.problem),...
    sol.info, primal_opt, dual_opt, gap};

end