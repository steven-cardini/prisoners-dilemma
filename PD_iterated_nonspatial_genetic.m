%% This script simulates a game of iterated Prisoner's dilemma (PD). 
%  A player competes against all other players.
%  A genetic algorithm is used to evolve the players.
%  Steven Cardini, 02.01.2017

clear variables;
close all;
clc; % clear command window


%% Body
% 0 = defector, 1 = cooperator

global payoff;
global pop_size;
global memory_depth;
global crossover_rate;
global mutation_rate;

% payoff matrix with indices [0, 1; 2, 3]
        % opponent defects  % opponent cooperates
payoff = [1.1,              5.0;  % player defects
          0.5,              3.3]; % player cooperates

pop_size = 20; % amount of prisoners / players
memory_depth = 2; % each players remembers that many previous duels
generations = 1000;

crossover_rate = 1.5 / 4^memory_depth; % on average, 1.5 crossovers per reproduction
mutation_rate = 1.0 / ( pop_size * 4^memory_depth); % on average, 1 mutation per generation

max_player_fitness =  payoff(1,2)*(pop_size-1)*4^memory_depth;
max_population_fitness = payoff(2,2)*(pop_size-1)*4^memory_depth * pop_size;

game_state = initialize_game_state(true);
fitness_history = zeros (generations, pop_size+1, 1);

optimized_fitness = 0;
optimized_strategy = zeros(4^memory_depth, 1);

for generation_id = 1 : generations
  
  [game_state, fitness] = evaluate_generation (game_state);
  
  % record and evaluate fitness
  fitness_history(generation_id,:) = [int32(sum(fitness)); fitness]; % record fitness to review the history
  [best_generation_fitness, best_player_id] = max(fitness(:));
  if best_generation_fitness > optimized_fitness
    optimized_fitness = best_generation_fitness;
    optimized_strategy = game_state (2*best_player_id, :);
  end
  
  [fitness_sorted, fitness_ind] = sort(fitness);
  
  new_game_state = initialize_game_state(false); % prepare game state for next generation
  
  % select individuals for next generation and reproduce
  for individual_id = 1 : pop_size
    % select randomly two parents
    parent_id_1 = select_parent(fitness_sorted, fitness_ind);
    parent_id_2 = select_parent(fitness_sorted, fitness_ind);
    while parent_id_1 == parent_id_2 % ensure that parents are different individuals
      parent_id_2 = select_parent(fitness_sorted, fitness_ind);
    end
    
    % parents reproduce sexually (crossover and mutations) to produce a
    % child strategy
    child_strategy = reproduce(game_state, parent_id_1, parent_id_2);
    new_game_state(individual_id*2,:) = child_strategy;
  end
  
  game_state = new_game_state;
  
end

% output the optimized strategy
optimized_strategy
fprintf('Individual: Optimized Fitness Value: %d (max possible: %d)\n', int32(optimized_fitness), max_player_fitness);
fprintf('Population: Optimized Fitness Value: %d (max possible: %d)\n', int32(max(fitness_history(1,:))), max_population_fitness);


%% Functions

function game_state = initialize_game_state (with_strategies)
  global pop_size;
  global memory_depth;
  
  game_state = zeros (2*pop_size, 4^memory_depth);
  
  for player_id = 1 : pop_size
    
    for memory_step = 1 : memory_depth
      index = player_id * 2 - 1;
      game_state(index, memory_step) = randi (4) - 1;
    end
    
    if ~with_strategies
      continue;
    end
    
    for history_result = 1 : 4^memory_depth
      index = player_id * 2;
      game_state(index, history_result) = randi(2) - 1;
    end
    
  end
  
end

function [game_state, fitness] = evaluate_generation (game_state)
  global pop_size;
  
  fitness = zeros(pop_size, 1);
  
  for player_id = 1 : pop_size % compete player against each other
    for opponent_id = 2 : pop_size
      if opponent_id <= player_id % ensure that all players play once against each other exactly
        continue;
      end
      fitness = play_round (game_state, fitness, player_id, opponent_id); 
    end
  end
end

function fitness = play_round (game_state, fitness, player_id, opponent_id)
  global payoff;  
  global memory_depth;

  for duel_id = 1 : 4^memory_depth
    
    % fight
    player_strategy = get_strategy (game_state, player_id);
    opponent_strategy = get_strategy (game_state, opponent_id);
    
    % update each player's history
    game_state = update_history (game_state, player_id, 2*player_strategy + opponent_strategy);
    game_state = update_history (game_state, opponent_id, 2*opponent_strategy + player_strategy);
    
    % update each player's fitness points
    player_payoff = payoff(player_strategy+1, opponent_strategy+1);
    opponent_payoff = payoff(opponent_strategy+1, player_strategy+1);
    fitness(player_id) = fitness(player_id) + player_payoff;
    fitness(opponent_id) = fitness(opponent_id) + opponent_payoff;
    
  end

end

function strategy = get_strategy (game_state, player_id)
  global memory_depth;
  
  index = 2*player_id-1;
  strategy_id = 0;
  
  % check player's history to determine which strategy he plays
  for memory_step = 1:memory_depth
    result = game_state (index, memory_step);
    if memory_step > 1
      result = result * 2^memory_step;
    end
    strategy_id = strategy_id + result;
  end
  
  strategy = game_state (2*player_id, strategy_id+1);
end

function game_state = update_history (game_state, player_id, new_result)
  global memory_depth;
  
  index = player_id*2 - 1;
  
  for memory_step = memory_depth:-1:1
    if memory_step == 1
      new_val = new_result;
    else
      new_val = game_state(index, memory_step-1);
    end
    game_state(index, memory_step) = new_val;
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

function child_strategy = reproduce (game_state, parent_id_1, parent_id_2)
  global memory_depth;
  global crossover_rate;
  global mutation_rate;

  % create chromosomes from parents' strategies
  chromosomes = zeros(2, 4^memory_depth, 1);
  chromosomes(1,:) = game_state(2*parent_id_1,:);
  chromosomes(2,:) = game_state(2*parent_id_2,:);
  
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
    
    bit = chromosomes(parent_id, bit_id);
    
    % perform mutation if necessary
    if rand() < mutation_rate
      if bit == 0
        bit = 1;
      else
        bit = 0;
      end
    end
    
    child_strategy(bit_id) = bit;
    
  end
  
end
