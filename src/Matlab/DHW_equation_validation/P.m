function p = P(a,z,n,m)
% Eqn.(2) at
% https://math.stackexchange.com/questions/3335630/probability-problem-roll-a-n-sided-dice-for-m-times-the-probablity-to-have-at
p = (Q(a,z,n,m)-Q(a,(z-1),n,m)) - (Q((a+1),z,n,m)-Q((a+1),(z-1),n,m));
end

