%% This script simulates a game of iterated Prisoner's dilemma (PD). 
%  A player competes against all other players.
%  A genetic algorithm will be used to evolve the players.
%  Steven Cardini, 02.01.2017

clear variables;
close all;
clc; % clear command window

global payoff;
global pop_size;
global memory_depth;


%% Body
% 0 = defector, 1 = cooperator

        % opponent defects  % opponent cooperates
payoff = [1.1 (0),              5.0 (1);  % player defects
          0.5 (2),              3.3 (3)]; % player cooperates

pop_size = 20; % amount of prisoners / players
memory_depth = 2; % players remember that many previous rounds
cycle_amount = 10;

game_state = initialize();

for cycle_id = 1:cycle_amount
  [game_state, fitness] = play_cycle (game_state);
end


%% Functions

function game_state = initialize ()
  global pop_size;
  global memory_depth;
  
  game_state = zeros (2*pop_size, 4^memory_depth);
  
  for player_id = 1 : pop_size
    
    for memory_step = 1 : memory_depth
      index = player_id * 2 - 1;
      game_state(index, memory_step) = randi (4) - 1;
    end
    
    for history_result = 1 : 4^memory_depth
      index = player_id * 2;
      game_state(index, history_result) = randi(2) - 1;
    end
    
  end
  
end

function [game_state, fitness] = play_cycle (game_state)
  global pop_size;
  global memory_depth;
  
  fitness = zeros(pop_size, 1);
  
  for player_id = 1 : pop_size % compete player against each other
    
    for opponent_id = 2 : pop_size
      if opponent_id <= player_id % ensure that all players play once against each other exactly
        continue;
      end
      
      fitness = play_round (game_state, fitness, player_id, opponent_id);
      
    end
    
  end
  
  % fitness evaluation
  % selection
  % evolution (recombination and mutation)

end

function fitness = play_round (game_state, fitness, player_id, opponent_id)
  global payoff;  
  global memory_depth;

  for duel_id = 1 : 4^memory_depth
    
    % fight
    player_strategy = get_strategy (game_state, player_id);
    opponent_strategy = get_strategy (game_state, opponent_id);
    
    % update history
    game_state = update_history (game_state, player_id, 2*player_strategy + opponent_strategy);
    game_state = update_history (game_state, opponent_id, 2*opponent_strategy + player_strategy);
    
    % evaluate points
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