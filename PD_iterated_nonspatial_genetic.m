%% This script simulates a game of iterated Prisoner's dilemma (PD). 
%  A player competes against all other players.
%  A genetic algorithm is used to evolve the players.
%  Steven Cardini, 02.01.2017

clear variables;
close all;
clc; % clear command window


%% Body

global payoff;
global pop_size;
global memory_depth;
global crossover_rate;
global mutation_rate;

% Payoff Vector
% 0 = player defects, opponent defects
% 1 = player defects, opponent cooperates
% 2 = player cooperates, opponent defects
% 3 = player cooperates, opponent cooperates
        %  0    1    2    3
payoff = [1.1, 5.0, 0.5, 3.3];

pop_size = 20; % amount of players
memory_depth = 2; % each player remembers that many previous duels
generations = 1000;

crossover_rate = 1.5 / 4^memory_depth; % on average, 1.5 crossovers per reproduction
mutation_rate = 1.0 / ( pop_size * 4^memory_depth); % on average, 1 mutation per generation

player_strategies = initialize_strategies(); % 0 = defect, 1 = cooperate
player_histories = initialize_histories();

fitness_history = zeros (generations, pop_size+1, 1);
optimized_player_fitness = 0;
optimized_player_strategy = zeros(4^memory_depth, 1);
max_player_fitness =  payoff(2)*(pop_size-1)*4^memory_depth;
max_population_fitness = payoff(4)*(pop_size-1)*4^memory_depth * pop_size;

for generation_id = 1 : generations
  
  fitness = evaluate_generation (player_strategies, player_histories);
  
  % record and evaluate fitness
  fitness_history(generation_id,:) = [int32(sum(fitness)); fitness]; % record fitness to review the history later
  [best_player_fitness, best_player_id] = max(fitness(:));
  if best_player_fitness > optimized_player_fitness
    optimized_player_fitness = best_player_fitness;
    optimized_player_strategy = player_strategies(best_player_id, :);
  end
  
  [fitness_sorted, fitness_indices] = sort(fitness);
  
  new_player_strategies = initialize_strategies(); % prepare player strategies for next generation
  
  % create individuals for next generation, each by reproducing two
  % individuals of current generation
  for individual_id = 1 : pop_size
    % select two parents
    parent_id_1 = select_parent(fitness_sorted, fitness_indices);
    parent_id_2 = select_parent(fitness_sorted, fitness_indices);
    while parent_id_1 == parent_id_2 % ensure that parents are different individuals
      parent_id_2 = select_parent(fitness_sorted, fitness_indices);
    end
    
    % parents reproduce sexually (crossover and mutations) to produce a
    % child strategy
    child_strategy = reproduce(player_strategies, parent_id_1, parent_id_2);
    new_player_strategies(individual_id,:) = child_strategy;
  end
  
  player_strategies = new_player_strategies;
  
end

% output the optimized strategy
optimized_player_strategy
fprintf('Individual: Optimized Fitness Value: %d (max possible: %d)\n', int32(optimized_player_fitness), max_player_fitness);
fprintf('Population: Optimized Fitness Value: %d (max possible: %d)\n', int32(max(fitness_history(:,1))), max_population_fitness);


%% Functions

function strategies = initialize_strategies()
  global pop_size;
  global memory_depth;

  strategies = zeros (pop_size, 4^memory_depth);
  
  for player_id = 1 : pop_size
    for history_result = 1 : 4^memory_depth
      strategies(player_id, history_result) = randi(2) - 1;
    end
  end
end

% initializes the player histories with random values
% values 1-4 according to payoff vector
function histories = initialize_histories()
  global pop_size;
  global memory_depth;
  
  histories = zeros(pop_size, memory_depth);
  
  for player_id = 1 : pop_size
    for memory_step = 1 : memory_depth
      histories(player_id, memory_step) = randi (4) - 1;
    end
  end
end

function fitness = evaluate_generation (strategies, histories)
  global pop_size;
  
  fitness = zeros(pop_size, 1);
  
  for player_id = 1 : pop_size % compete player against each other
    for opponent_id = 2 : pop_size
      if opponent_id <= player_id % ensure that all players play once against each other exactly
        continue;
      end
      fitness = play_round (strategies, histories, fitness, player_id, opponent_id); 
    end
  end
end

function fitness = play_round (strategies, histories, fitness, player_id, opponent_id)
  global payoff;  
  global memory_depth;

  for duel_id = 1 : 4^memory_depth
    
    % fight
    player_strategy = get_strategy (strategies, histories, player_id);
    opponent_strategy = get_strategy (strategies, histories, player_id);
    
    % update each player's history
    histories = update_history (histories, player_id, opponent_id, player_strategy, opponent_strategy);
    
    % update each player's fitness points
    player_payoff = payoff(player_strategy*2 + opponent_strategy + 1);
    opponent_payoff = payoff(opponent_strategy*2 + player_strategy + 1);
    fitness(player_id) = fitness(player_id) + player_payoff;
    fitness(opponent_id) = fitness(opponent_id) + opponent_payoff;
    
  end

end

function strategy = get_strategy (strategies, histories, player_id)
  global memory_depth;
  
  strategy_id = 0;
  
  % check player's history to determine which strategy he plays
  for memory_step = 1:memory_depth
    strategy_id = strategy_id + histories(player_id, memory_step) * 4^(memory_step-1);
  end
  
  strategy = strategies(player_id, strategy_id+1);
end

function histories = update_history (histories, player_id, opponent_id, player_strategy, opponent_strategy)
  global memory_depth;
    
  for memory_step = memory_depth:-1:1
    if memory_step == 1 % calculate duel value for current round
      player_val = player_strategy * 2 + opponent_strategy;
      opponent_val = opponent_strategy * 2 + player_strategy;
    else % shift history duels one back
      player_val = histories(player_id, memory_step-1);
      opponent_val = histories(opponent_id, memory_step-1);
    end
    histories(player_id, memory_step) = player_val;
    histories(opponent_id, memory_step) = opponent_val;
  end
end

function parent_id = select_parent(fitness_sorted, fitness_ind)
 
  accumulation = cumsum(fitness_sorted);
  p = rand() * accumulation(end);
  chosen_index = -1;
  for index = 1 : length(accumulation)
    if (accumulation(index) > p)
      chosen_index = index;
      break;
    end
  end
  
  parent_id = fitness_ind(chosen_index);
end

function child_strategy = reproduce (strategies, parent_id_1, parent_id_2)
  global memory_depth;
  global crossover_rate;
  global mutation_rate;

  % create chromosomes from parents' strategies
  chromosomes = zeros(2, 4^memory_depth, 1);
  chromosomes(1,:) = strategies(parent_id_1,:);
  chromosomes(2,:) = strategies(parent_id_2,:);
  
  child_strategy = zeros(4^memory_depth, 1);
  parent_id = 1;
  
  for bit_id = 1 : 4^memory_depth
    
    % perform crossover if necessary
    if rand() < crossover_rate
      if parent_id == 1
        parent_id = 2;
      else
        parent_id = 1;
      end
    end
    
    bit_val = chromosomes(parent_id, bit_id);
    
    % perform mutation if necessary
    if rand() < mutation_rate
      if bit_val == 0
        bit_val = 1;
      else
        bit_val = 0;
      end
    end
    
    child_strategy(bit_id) = bit_val;
    
  end
  
end
