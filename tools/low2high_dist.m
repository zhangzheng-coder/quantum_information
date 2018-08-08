function h_dist = low2high_dist(dist_name, h_out, conv_mat, use_interval, seed)
% LOW2HIGH_DIST generate random distribution with higher number of 
% outcomes which has the same feasibility with a corresponding 
% distribution with lower number of outcomes.
% Assumes 3 observed variables (triangle scenario)
rng(seed,'v5uniform');%fixed seed
nvar = 3;

% Get original (lower-outcome) distribution
[l_dist, l_out, feasibility] = get_dist(dist_name, use_interval);

if nargin < 4
    use_interval = false; %default
end

% If conversion matrices (e.g. P(a'|a)) not given, generate randomly
if nargin < 3 || isempty(conv_mat)
    if feasibility == true
        if use_interval
            % For FEASIBLE distribution, generate random matrix
            conv_mat = intval(rand(h_out, l_out, nvar));

            % Normalize probabilities
            col_sums = sum(conv_mat, 1);%shape=(1, l_out, nvar)
            divisor = repmat(col_sums, h_out, 1, 1);
            for k1 = 1:size(divisor, 1)
                for k2 = 1:size(divisor,2)
                    for k3 = 1:size(divisor, 3)
                    conv_mat(k1,k2,k3) = conv_mat(k1,k2,k3) / divisor(k1,k2,k3);
                    end
                end
            end
        else
            % For FEASIBLE distribution, generate random matrix
            conv_mat = rand(h_out, l_out, nvar);

            % Normalize probabilities
            col_sums = sum(conv_mat, 1);%shape=(1, l_out, nvar)
            divisor = repmat(col_sums, h_out, 1, 1);
            conv_mat = conv_mat ./ divisor;
        end
    else
        % For INFEASIBLE dist, generate random invertibly normalizable matrix
        %     (1) generate matrix
        %         .5 0  0
        %         .5 0  0
        %         0  .3 0
        %         0  .4 0
        %         0  .3 0
        %         0  0  1
        %     (2) shuffle rows
        if use_interval
            conv_mat = intval(zeros(h_out, l_out, nvar));
            % Do this for every layer(nvar):
            for layer = 1:nvar
                % Determine lengths of vectors
                col_nonzeros = ones(1, l_out);%at least 1 nonzero entries
                for k = 1:h_out-l_out
                    rand_index = randi(l_out);
                    col_nonzeros(1, rand_index) = col_nonzeros(1, rand_index) + 1;
                end
                % Create random vectors and place inside matrix
                slices = [0 cumsum(col_nonzeros)];
                for k = 1:l_out
                    % Random normalized vector of shape (#nonzero, 1)
                    rand_mat = intval(rand(col_nonzeros(1,k),1));
                    divisor = sum(rand_mat);
                    rand_mat = rand_mat/divisor;
                    % Place random vector inside the matrix
                    conv_mat(slices(k)+1:slices(k+1), k, layer) = rand_mat;
                end
                % Shuffle rows of the matrix
                conv_mat(:,:,layer) = conv_mat(randperm(size(conv_mat,1)),:,layer);
            end
        else
            conv_mat = zeros(h_out, l_out, nvar);
            % Do this for every layer(nvar):
            for layer = 1:nvar
                % Determine lengths of vectors
                col_nonzeros = ones(1, l_out);%at least 1 nonzero entries
                for k = 1:h_out-l_out
                    rand_index = randi(l_out);
                    col_nonzeros(1, rand_index) = col_nonzeros(1, rand_index) + 1;
                end
                % Create random vectors and place inside matrix
                slices = [0 cumsum(col_nonzeros)];
                for k = 1:l_out
                    % Random normalized vector of shape (#nonzero, 1)
                    rand_mat = rand(col_nonzeros(1,k),1);
                    divisor = sum(rand_mat);
                    rand_mat = rand_mat/divisor;
                    % Place random vector inside the matrix
                    conv_mat(slices(k)+1:slices(k+1), k, layer) = rand_mat;
                end
                % Shuffle rows of the matrix
                conv_mat(:,:,layer) = conv_mat(randperm(size(conv_mat,1)),:,layer);
            end
        end
    end
end

% Take kronecker product e.g. C x B x A
kron_prod = 1;
for k = 1:nvar
    kron_prod = kron(kron_prod, conv_mat(:,:,k));
end

% Multiply by original distribution
h_dist = kron_prod * l_dist;

%---------Code for verbose printouts---------
% rank(kron_prod)
% spy(kron_prod);
% find(h_dist)
% sum(sort(65 - find(h_dist)) ~= find(h_dist)) == 0
% h_dist(find(h_dist))

end