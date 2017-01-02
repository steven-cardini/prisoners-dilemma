%% This script simulates a game of iterated Prisoner's dilemma (PD). 
%  A player competes against all other players.
%  A genetic algorithm will be used to evolve the players.
%  Steven Cardini, 02.01.2017

clear variables;
close all;
clc; % clear command window

global pop_size;
global memory_depth;


%% Body
% 0 = defector, 1 = cooperator

        % opponent defects  % opponent cooperates
payoff = [1.1,              5.0;  % player defects
         0.5,               3.3]; % player cooperates

pop_size = 20; % amount of prisoners / players
memory_depth = 2; % players remember that many previous rounds

game_state = initialize();


%% Functions

function game_state = initialize ()
  global pop_size;
  global memory_depth;
  
  game_state = zeros (2*pop_size, 4^memory_depth);
  
  for player_id = 1 : pop_size
    
    for memory_step = 1 : memory_depth
      index = player_id * 2 - 1;
      game_state(index, memory_step) = randi (4^memory_depth);
    end
    
    for history_result = 1 : 4^memory_depth
      index = player_id * 2;
      game_state(index, history_result) = randi(2) - 1;
    end
    
  end
  
end