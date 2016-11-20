%% This script simulates a game of iterated Prisoner's dilemma (PD). 
%  Players are distributed over space and interact with their direct neighbors only. 
%  Players use pure strategies only (either always cooperate or defect).
%  Steven Cardini, 13.11.2016

clear variables;
close all;
clc; % clear command window

global pop_size;
pop_size    = 100;   % game board is a square and accommodates pop_size^2 players
gen_amount  = 100;  % number of generations
coop_freq   = 0.5;  % initial frequency of cooperators

benefit     = 50;   % benefit > 0
cost        = 1;    % 0 < cost < benefit

        % opponent defects  % opponent cooperates
payoff = [0,                benefit;       % player defects
         -cost,             benefit-cost]; % player cooperates
         
         
%% Body
% 0 = defector, 1 = cooperator

pop = zeros(pop_size);  % defines a matrix for the game board that accomodates all players
pop ( randperm(numel(pop), round(coop_freq * pop_size^2)) ) = 1; % add the specified of cooperators

for generation = 1:gen_amount
  
  image(pop*50);
  pause;
  cooperators = sum (pop(:)==1);
  freq = double(cooperators) / double(pop_size^2);
  fprintf('Gen %d - Coop_freq: %d\n', generation, freq);
  pop_new = zeros(pop_size); % stores the successor population
  
  for row = 1:pop_size
    
    for col = 1:pop_size
      
      % define player to be evaluated
      x_coords = [row, col];
      x = pop(row, col);
      
      % choose randomly y = player's direct opponent
      y_coords = randomNeighbor(x_coords);
      y = pop(y_coords(1), y_coords(2));
      
      % choose randomly u = player's indirect opponent
      u_coords = x_coords;
      while isequal(u_coords, x_coords)
        u_coords = randomNeighbor(x_coords);
      end
      u = pop(u_coords(1), u_coords(2));
      
      % choose randomly v = u's direct opponent
      v_coords = u_coords;
      while isequal(v_coords, u_coords) || isequal(v_coords, x_coords)
        v_coords = randomNeighbor(u_coords);
      end
      v = pop(v_coords(1), v_coords(2));
      
      payoff_x = payoff (x+1, y+1);
      payoff_u = payoff (u+1, v+1);
      w = ( payoff_u - payoff_x ) / ( max(payoff(:)) - min(payoff(:)) ); % probability that x is replaced by u
      w = max([0 w]); % ensure that w is between 0 and 1
      
      if w >= rand()
        pop_new(row, col) = u; % x is 'replaced' by u
      else
        pop_new(row, col) = x; % x 'survives'
      end
      
    end % col
        
  end % row
  
  pop = pop_new;
  
end % gen

%% Functions

function neighbor_coords = randomNeighbor (coords)
  global pop_size;  
  row = coords(1);
  col = coords(2);
  n_col = col;
  n_row = row;
  
  while n_col == col && n_row == row
    n_col = (col-2) + randi(3); % n_col is col-1, col or col+1
    n_col = mod (n_col-1, pop_size) + 1; % borders are continuous / periodic
  
    n_row = (row-2) + randi(3); % n_row is row-1, row or row+1
    n_row = mod (n_row-1, pop_size) + 1; % borders are continuous / periodic
  end
  
  neighbor_coords = [n_row, n_col];
end